package modelcatalog

import (
	"encoding/binary"
	"fmt"
	"io"
	"math"
	"os"
	"regexp"
	"strconv"
	"strings"
)

const (
	ggufTypeUint8   uint32 = 0
	ggufTypeInt8    uint32 = 1
	ggufTypeUint16  uint32 = 2
	ggufTypeInt16   uint32 = 3
	ggufTypeUint32  uint32 = 4
	ggufTypeInt32   uint32 = 5
	ggufTypeFloat32 uint32 = 6
	ggufTypeBool    uint32 = 7
	ggufTypeString  uint32 = 8
	ggufTypeArray   uint32 = 9
	ggufTypeUint64  uint32 = 10
	ggufTypeInt64   uint32 = 11
	ggufTypeFloat64 uint32 = 12
)

const (
	maxGGUFMetadataEntries = 10_000_000
	maxGGUFTensors         = 10_000_000
	maxGGUFDimensions      = 16
	maxGGUFStringBytes     = 256 * 1024 * 1024
)

type ggufResult struct {
	Metadata
	tensorParameters int64
}

type boundedReader struct {
	file *os.File
	size int64
}

func parseGGUF(path string) (ggufResult, error) {
	file, err := os.Open(path)
	if err != nil {
		return ggufResult{}, err
	}
	defer file.Close()
	info, err := file.Stat()
	if err != nil {
		return ggufResult{}, err
	}
	reader := &boundedReader{file: file, size: info.Size()}

	var magic [4]byte
	if err := reader.read(&magic); err != nil {
		return ggufResult{}, fmt.Errorf("read magic: %w", err)
	}
	if string(magic[:]) != "GGUF" {
		return ggufResult{}, fmt.Errorf("invalid magic %q", magic[:])
	}
	var version uint32
	var tensorCount, metadataCount uint64
	if err := reader.read(&version); err != nil {
		return ggufResult{}, fmt.Errorf("read version: %w", err)
	}
	if version < 1 || version > 3 {
		return ggufResult{}, fmt.Errorf("unsupported GGUF version %d", version)
	}
	if err := reader.read(&tensorCount); err != nil {
		return ggufResult{}, fmt.Errorf("read tensor count: %w", err)
	}
	if err := reader.read(&metadataCount); err != nil {
		return ggufResult{}, fmt.Errorf("read metadata count: %w", err)
	}
	if tensorCount > maxGGUFTensors || metadataCount > maxGGUFMetadataEntries {
		return ggufResult{}, fmt.Errorf("unreasonable header counts: %d tensors, %d metadata entries", tensorCount, metadataCount)
	}

	values := make(map[string]any)
	for i := uint64(0); i < metadataCount; i++ {
		key, err := reader.readString(true)
		if err != nil {
			return ggufResult{}, fmt.Errorf("read metadata key %d: %w", i, err)
		}
		var valueType uint32
		if err := reader.read(&valueType); err != nil {
			return ggufResult{}, fmt.Errorf("read metadata type for %q: %w", key, err)
		}
		capture := interestingGGUFKey(key)
		value, err := reader.readGGUFValue(valueType, capture, 0)
		if err != nil {
			return ggufResult{}, fmt.Errorf("read metadata value for %q: %w", key, err)
		}
		if capture {
			values[key] = value
		}
	}

	var tensorParameters int64
	for i := uint64(0); i < tensorCount; i++ {
		if _, err := reader.readString(false); err != nil {
			return ggufResult{}, fmt.Errorf("read tensor %d name: %w", i, err)
		}
		var dimensions uint32
		if err := reader.read(&dimensions); err != nil {
			return ggufResult{}, fmt.Errorf("read tensor %d dimensions: %w", i, err)
		}
		if dimensions == 0 || dimensions > maxGGUFDimensions {
			return ggufResult{}, fmt.Errorf("tensor %d has invalid dimension count %d", i, dimensions)
		}
		parameters := int64(1)
		for dimension := uint32(0); dimension < dimensions; dimension++ {
			var length uint64
			if version == 1 {
				var legacyLength uint32
				if err := reader.read(&legacyLength); err != nil {
					return ggufResult{}, fmt.Errorf("read tensor %d legacy shape: %w", i, err)
				}
				length = uint64(legacyLength)
			} else if err := reader.read(&length); err != nil {
				return ggufResult{}, fmt.Errorf("read tensor %d shape: %w", i, err)
			}
			if length == 0 || length > math.MaxInt64 || parameters > math.MaxInt64/int64(length) {
				parameters = math.MaxInt64
			} else if parameters != math.MaxInt64 {
				parameters *= int64(length)
			}
		}

		var tensorType uint32
		var offset uint64
		if err := reader.read(&tensorType); err != nil {
			return ggufResult{}, fmt.Errorf("read tensor %d type: %w", i, err)
		}
		if err := reader.read(&offset); err != nil {
			return ggufResult{}, fmt.Errorf("read tensor %d offset: %w", i, err)
		}
		tensorParameters = saturatingAdd(tensorParameters, parameters)
	}

	metadata := metadataFromGGUF(values)
	if metadata.ParameterCount == 0 {
		metadata.ParameterCount = tensorParameters
	}
	return ggufResult{Metadata: metadata, tensorParameters: tensorParameters}, nil
}

func interestingGGUFKey(key string) bool {
	if key == "general.architecture" || key == "general.name" || key == "general.file_type" || key == "general.parameter_count" {
		return true
	}
	for _, suffix := range []string{
		".context_length", ".block_count", ".attention.head_count", ".attention.head_count_kv",
		".attention.key_length", ".embedding_length", ".attention.sliding_window",
	} {
		if strings.HasSuffix(key, suffix) {
			return true
		}
	}
	return false
}

func metadataFromGGUF(values map[string]any) Metadata {
	architecture := stringValue(values["general.architecture"])
	prefix := architecture
	metadata := Metadata{
		Name:               stringValue(values["general.name"]),
		Architecture:       architecture,
		Layers:             intValue(values[prefix+".block_count"]),
		AttentionHeads:     intValue(values[prefix+".attention.head_count"]),
		KVHeads:            intValue(values[prefix+".attention.head_count_kv"]),
		HeadDimension:      intValue(values[prefix+".attention.key_length"]),
		EmbeddingDimension: intValue(values[prefix+".embedding_length"]),
		ContextLength:      intValue(values[prefix+".context_length"]),
		SlidingWindow:      intValue(values[prefix+".attention.sliding_window"]),
		ParameterCount:     int64Value(values["general.parameter_count"]),
	}
	if metadata.KVHeads == 0 {
		metadata.KVHeads = metadata.AttentionHeads
	}
	if fileType, ok := numberAsUint64(values["general.file_type"]); ok {
		metadata.Quantization = ggufFileTypeName(fileType)
	}
	return metadata
}

func (r *boundedReader) read(value any) error {
	position, err := r.file.Seek(0, io.SeekCurrent)
	if err != nil {
		return err
	}
	size := int64(binary.Size(value))
	if size < 0 || position < 0 || size > r.size-position {
		return io.ErrUnexpectedEOF
	}
	return binary.Read(r.file, binary.LittleEndian, value)
}

func (r *boundedReader) skip(bytes uint64) error {
	position, err := r.file.Seek(0, io.SeekCurrent)
	if err != nil {
		return err
	}
	if bytes > math.MaxInt64 || position < 0 || int64(bytes) > r.size-position {
		return io.ErrUnexpectedEOF
	}
	_, err = r.file.Seek(int64(bytes), io.SeekCurrent)
	return err
}

func (r *boundedReader) readString(capture bool) (string, error) {
	var length uint64
	if err := r.read(&length); err != nil {
		return "", err
	}
	if length > maxGGUFStringBytes {
		return "", fmt.Errorf("string is too large: %d bytes", length)
	}
	if !capture {
		return "", r.skip(length)
	}
	data := make([]byte, int(length))
	if _, err := io.ReadFull(r.file, data); err != nil {
		return "", err
	}
	return string(data), nil
}

func (r *boundedReader) readGGUFValue(valueType uint32, capture bool, depth int) (any, error) {
	if depth > 4 {
		return nil, fmt.Errorf("nested metadata arrays are too deep")
	}
	switch valueType {
	case ggufTypeUint8:
		var value uint8
		err := r.read(&value)
		return value, err
	case ggufTypeInt8:
		var value int8
		err := r.read(&value)
		return value, err
	case ggufTypeUint16:
		var value uint16
		err := r.read(&value)
		return value, err
	case ggufTypeInt16:
		var value int16
		err := r.read(&value)
		return value, err
	case ggufTypeUint32:
		var value uint32
		err := r.read(&value)
		return value, err
	case ggufTypeInt32:
		var value int32
		err := r.read(&value)
		return value, err
	case ggufTypeFloat32:
		var value float32
		err := r.read(&value)
		return value, err
	case ggufTypeBool:
		var value uint8
		err := r.read(&value)
		return value != 0, err
	case ggufTypeString:
		return r.readString(capture)
	case ggufTypeUint64:
		var value uint64
		err := r.read(&value)
		return value, err
	case ggufTypeInt64:
		var value int64
		err := r.read(&value)
		return value, err
	case ggufTypeFloat64:
		var value float64
		err := r.read(&value)
		return value, err
	case ggufTypeArray:
		var elementType uint32
		var count uint64
		if err := r.read(&elementType); err != nil {
			return nil, err
		}
		if err := r.read(&count); err != nil {
			return nil, err
		}
		if count > maxGGUFMetadataEntries {
			return nil, fmt.Errorf("metadata array is too large: %d elements", count)
		}
		if width := ggufFixedWidth(elementType); width > 0 {
			if count > math.MaxUint64/uint64(width) {
				return nil, fmt.Errorf("metadata array size overflow")
			}
			return nil, r.skip(count * uint64(width))
		}
		for i := uint64(0); i < count; i++ {
			if _, err := r.readGGUFValue(elementType, false, depth+1); err != nil {
				return nil, err
			}
		}
		return nil, nil
	default:
		return nil, fmt.Errorf("unknown GGUF metadata type %d", valueType)
	}
}

func ggufFixedWidth(valueType uint32) int {
	switch valueType {
	case ggufTypeUint8, ggufTypeInt8, ggufTypeBool:
		return 1
	case ggufTypeUint16, ggufTypeInt16:
		return 2
	case ggufTypeUint32, ggufTypeInt32, ggufTypeFloat32:
		return 4
	case ggufTypeUint64, ggufTypeInt64, ggufTypeFloat64:
		return 8
	default:
		return 0
	}
}

func stringValue(value any) string {
	text, _ := value.(string)
	return strings.TrimSpace(text)
}

func intValue(value any) int {
	number := int64Value(value)
	if number <= 0 || number > math.MaxInt {
		return 0
	}
	return int(number)
}

func int64Value(value any) int64 {
	unsigned, ok := numberAsUint64(value)
	if !ok || unsigned > math.MaxInt64 {
		return 0
	}
	return int64(unsigned)
}

func numberAsUint64(value any) (uint64, bool) {
	switch number := value.(type) {
	case uint8:
		return uint64(number), true
	case int8:
		return uint64(number), number >= 0
	case uint16:
		return uint64(number), true
	case int16:
		return uint64(number), number >= 0
	case uint32:
		return uint64(number), true
	case int32:
		return uint64(number), number >= 0
	case uint64:
		return number, true
	case int64:
		return uint64(number), number >= 0
	default:
		return 0, false
	}
}

func ggufFileTypeName(value uint64) string {
	names := map[uint64]string{
		0: "F32", 1: "F16", 2: "Q4_0", 3: "Q4_1", 4: "Q4_1_F16", 7: "Q8_0",
		8: "Q5_0", 9: "Q5_1", 10: "Q2_K", 11: "Q3_K_S", 12: "Q3_K_M",
		13: "Q3_K_L", 14: "Q4_K_S", 15: "Q4_K_M", 16: "Q5_K_S", 17: "Q5_K_M",
		18: "Q6_K", 19: "IQ2_XXS", 20: "IQ2_XS", 21: "IQ3_XXS", 22: "IQ1_S",
		23: "IQ4_NL", 24: "IQ3_S", 25: "IQ2_S", 26: "IQ4_XS", 27: "IQ1_M",
		28: "BF16", 29: "TQ1_0", 30: "TQ2_0", 31: "MXFP4",
	}
	if name, ok := names[value]; ok {
		return name
	}
	return "GGML_FILE_TYPE_" + strconv.FormatUint(value, 10)
}

var quantizationNamePattern = regexp.MustCompile(`(?i)(?:^|[-_.])(IQ[1-4]_[A-Z0-9_]+|Q[2-8]_[A-Z0-9_]+|BF16|F16|F32)(?:[-_.]|$)`)

func inferQuantizationFromName(name string) string {
	match := quantizationNamePattern.FindStringSubmatch(name)
	if len(match) == 2 {
		return strings.ToUpper(match[1])
	}
	return ""
}
