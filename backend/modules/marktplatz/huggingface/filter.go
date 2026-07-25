package huggingface

import (
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/fillyengine/backend/modules/marktplatz/types"
)

var hfIgnoredExtensions = map[string]struct{}{
	"md":   {},
	"txt":  {},
	"json": {},
	"yaml": {},
	"yml":  {},
	"png":  {},
	"jpg":  {},
	"jpeg": {},
	"gif":  {},
	"webp": {},
	"csv":  {},
	"tsv":  {},
	// gitattributes is a tiny (few-KB) LFS config file present in almost
	// every HuggingFace repo. It has no penalty token in its name (unlike
	// tokenizer.model/config.json) and no recognized extension score, so it
	// used to survive as a real, "known-size" download option. Whenever the
	// recommender picked the smallest artifact across all options, this
	// near-zero-byte file won every time -- reporting a fixed ~7GB overhead
	// estimate (KV-cache/activation only, no real weights) as if it were the
	// full model, so even a 70B checkpoint looked like it fit any GPU.
	"gitattributes": {},
	// imatrix files are quantization calibration data (a few MB), not a
	// loadable model checkpoint. Same failure mode as gitattributes above.
	"imatrix": {},
}

var hfPreferredExtensionScore = map[string]int{
	"gguf":        110,
	"safetensors": 95,
	"mlx":         92,
	"nemo":        90,
	"bin":         75,
	"pt":          70,
	"pth":         70,
	"ckpt":        60,
	"onnx":        55,
}

var hfPenaltyTokens = []string{
	"tokenizer",
	"vocab",
	"merges",
	"config",
	"readme",
	"license",
	"special_tokens_map",
	"generation_config",
}

type hfOptionCandidate struct {
	option types.DownloadOption
	score  int
}

// shardPattern matches sharded checkpoints regardless of extension.  GGUF
// repositories use the exact same "-00001-of-00002" convention as
// safetensors once a quantized weight file exceeds HuggingFace's per-file
// limit (common from ~70B parameters up). Grouping only safetensors here
// silently left every GGUF shard as its own download option, so the
// recommender picked one shard's size as if it were the whole model's
// weight file -- understating a sharded 70B GGUF's VRAM need by roughly
// half and reporting it as fitting a GPU it does not fit on.
//
// The index and total are matched with \d+, not a fixed \d{5}: repos with
// hundreds of shards (e.g. DeepSeek-V3's "-00012-of-000163.safetensors")
// pad the total to more digits than the index, and a fixed width silently
// failed to match, leaving those shards ungrouped -- the exact same
// understated-size bug this pattern exists to prevent.
var shardPattern = regexp.MustCompile(`(?i)^(.*)-\d+-of-\d+\.(safetensors|gguf)$`)

func BuildHuggfaceFilteredOptions(siblings []HuggingFaceSibling) []types.DownloadOption {
	candidates := make([]hfOptionCandidate, 0, len(siblings))
	fallback := make([]types.DownloadOption, 0, len(siblings))

	for _, sibling := range siblings {
		file := strings.TrimSpace(sibling.RFilename)
		if file == "" {
			continue
		}
		ext := strings.TrimPrefix(strings.ToLower(filepath.Ext(file)), ".")
		if ext == "" {
			continue
		}
		format := inferHFOptionFormat(file, ext)

		baseOption := types.DownloadOption{
			Label:     file,
			AssetID:   file,
			Format:    format,
			SizeBytes: sibling.Size,
		}
		fallback = append(fallback, baseOption)

		if _, ignored := hfIgnoredExtensions[ext]; ignored {
			continue
		}

		score := 10
		if extScore, ok := hfPreferredExtensionScore[ext]; ok {
			score += extScore
		}

		lower := strings.ToLower(file)
		if strings.Contains(lower, "q4_") || strings.Contains(lower, "q4-") {
			score += 20
		}
		if strings.Contains(lower, "q5_") || strings.Contains(lower, "q5-") {
			score += 18
		}
		if strings.Contains(lower, "q8_") || strings.Contains(lower, "q8-") {
			score += 10
		}
		if strings.Contains(lower, "instruct") {
			score += 6
		}
		if strings.Contains(lower, ".index") {
			score -= 50
		}
		for _, token := range hfPenaltyTokens {
			if strings.Contains(lower, token) {
				score -= 35
			}
		}
		if score <= 0 {
			continue
		}

		candidates = append(candidates, hfOptionCandidate{
			option: baseOption,
			score:  score,
		})
	}

	if len(candidates) == 0 {
		return trimHFOptions(fallback, 40)
	}

	sort.Slice(candidates, func(i, j int) bool {
		if candidates[i].score == candidates[j].score {
			return strings.ToLower(candidates[i].option.Label) < strings.ToLower(candidates[j].option.Label)
		}
		return candidates[i].score > candidates[j].score
	})

	options := make([]types.DownloadOption, 0, len(candidates))
	for _, candidate := range candidates {
		options = append(options, candidate.option)
	}
	return trimHFOptions(groupShards(options), 40)
}

// groupShards turns model-00001-of-00008.safetensors / .gguf … into one
// logical option. The API exposes all AssetIDs, the total size and a friendly
// label so the UI can explain that every fragment will be downloaded, and so
// size-based VRAM estimates see the complete weight size instead of one
// shard.
func groupShards(options []types.DownloadOption) []types.DownloadOption {
	type shardGroup struct {
		first int
		files []string
		size  int64
	}
	groups := make(map[string]*shardGroup)
	for i := range options {
		option := &options[i]
		match := shardPattern.FindStringSubmatch(strings.TrimSpace(option.AssetID))
		if len(match) != 3 {
			continue
		}
		key := strings.ToLower(match[1]) + "." + strings.ToLower(match[2])
		group := groups[key]
		if group == nil {
			group = &shardGroup{first: i}
			groups[key] = group
		}
		group.files = append(group.files, option.AssetID)
		group.size += option.SizeBytes
	}

	if len(groups) == 0 {
		return options
	}
	out := make([]types.DownloadOption, 0, len(options))
	for i, option := range options {
		match := shardPattern.FindStringSubmatch(strings.TrimSpace(option.AssetID))
		if len(match) != 3 {
			out = append(out, option)
			continue
		}
		key := strings.ToLower(match[1]) + "." + strings.ToLower(match[2])
		group := groups[key]
		if group.first != i {
			continue
		}
		sort.Strings(group.files)
		option.AssetIDs = group.files
		option.SizeBytes = group.size
		option.Label = filepath.Base(match[1]) + " · " + strconv.Itoa(len(group.files)) + " Dateien"
		out = append(out, option)
	}
	return out
}

func ExtractFormatsFromHFOptions(options []types.DownloadOption) []string {
	formats := make([]string, 0, len(options))
	for _, option := range options {
		formats = append(formats, types.NormalizeFormat(option.Format))
	}
	return types.UniqueNonEmptyLower(formats)
}

func trimHFOptions(options []types.DownloadOption, limit int) []types.DownloadOption {
	if len(options) <= limit {
		return options
	}
	return options[:limit]
}

func inferHFOptionFormat(fileName string, extension string) string {
	ext := types.NormalizeFormat(extension)
	lower := strings.ToLower(strings.TrimSpace(fileName))

	if strings.HasSuffix(lower, ".nemo") || strings.Contains(lower, "nvidia-nemo") || strings.Contains(lower, "nvidia_nemo") {
		return "nemo"
	}
	if strings.Contains(lower, "/mlx/") || strings.Contains(lower, "-mlx") || strings.Contains(lower, "_mlx") || strings.Contains(lower, "mlx-") {
		return "mlx"
	}
	if ext == "safetensors" && strings.Contains(lower, "mlx") {
		return "mlx"
	}
	if strings.Contains(lower, "onnx") {
		return "onnx"
	}
	return ext
}
