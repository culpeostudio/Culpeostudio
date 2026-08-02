// Package huggingface adapts the Hugging Face Hub to the marketplace provider
// interface, including the filters its search API expects.
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

	"gitattributes": {},

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
