package autoupdate

import (
	"fmt"
	"strconv"
	"strings"
)

type semanticVersion struct {
	major      uint64
	minor      uint64
	patch      uint64
	prerelease []string
}

// CompareVersions compares two SemVer 2.0 versions. It returns -1 when left
// is older, 0 when both versions have equal precedence, and 1 when left is
// newer. Build metadata is deliberately ignored as required by SemVer.
func CompareVersions(left, right string) (int, error) {
	leftVersion, err := parseSemanticVersion(left)
	if err != nil {
		return 0, fmt.Errorf("invalid version %q: %w", left, err)
	}
	rightVersion, err := parseSemanticVersion(right)
	if err != nil {
		return 0, fmt.Errorf("invalid version %q: %w", right, err)
	}

	for _, pair := range [][2]uint64{
		{leftVersion.major, rightVersion.major},
		{leftVersion.minor, rightVersion.minor},
		{leftVersion.patch, rightVersion.patch},
	} {
		switch {
		case pair[0] < pair[1]:
			return -1, nil
		case pair[0] > pair[1]:
			return 1, nil
		}
	}
	return comparePrerelease(leftVersion.prerelease, rightVersion.prerelease), nil
}

func parseSemanticVersion(raw string) (semanticVersion, error) {
	value := strings.TrimSpace(raw)
	if strings.HasPrefix(value, "v") {
		value = strings.TrimPrefix(value, "v")
	}
	if value == "" {
		return semanticVersion{}, fmt.Errorf("version is empty")
	}

	precedence := value
	if plus := strings.IndexByte(precedence, '+'); plus >= 0 {
		if err := validateIdentifiers(precedence[plus+1:], false); err != nil {
			return semanticVersion{}, fmt.Errorf("invalid build metadata: %w", err)
		}
		precedence = precedence[:plus]
	}

	var prerelease []string
	if dash := strings.IndexByte(precedence, '-'); dash >= 0 {
		rawPrerelease := precedence[dash+1:]
		if err := validateIdentifiers(rawPrerelease, true); err != nil {
			return semanticVersion{}, fmt.Errorf("invalid prerelease: %w", err)
		}
		prerelease = strings.Split(rawPrerelease, ".")
		precedence = precedence[:dash]
	}

	core := strings.Split(precedence, ".")
	if len(core) != 3 {
		return semanticVersion{}, fmt.Errorf("expected major.minor.patch")
	}
	numbers := make([]uint64, len(core))
	for index, part := range core {
		if part == "" || (len(part) > 1 && part[0] == '0') {
			return semanticVersion{}, fmt.Errorf("invalid numeric component %q", part)
		}
		for _, character := range part {
			if character < '0' || character > '9' {
				return semanticVersion{}, fmt.Errorf("invalid numeric component %q", part)
			}
		}
		number, err := strconv.ParseUint(part, 10, 64)
		if err != nil {
			return semanticVersion{}, fmt.Errorf("numeric component %q is too large", part)
		}
		numbers[index] = number
	}
	return semanticVersion{
		major:      numbers[0],
		minor:      numbers[1],
		patch:      numbers[2],
		prerelease: prerelease,
	}, nil
}

func validateIdentifiers(raw string, rejectNumericLeadingZero bool) error {
	if raw == "" {
		return fmt.Errorf("identifier list is empty")
	}
	for _, identifier := range strings.Split(raw, ".") {
		if identifier == "" {
			return fmt.Errorf("identifier is empty")
		}
		numeric := true
		for _, character := range identifier {
			if (character < '0' || character > '9') &&
				(character < 'A' || character > 'Z') &&
				(character < 'a' || character > 'z') &&
				character != '-' {
				return fmt.Errorf("identifier %q contains an unsupported character", identifier)
			}
			if character < '0' || character > '9' {
				numeric = false
			}
		}
		if rejectNumericLeadingZero && numeric && len(identifier) > 1 && identifier[0] == '0' {
			return fmt.Errorf("numeric identifier %q has a leading zero", identifier)
		}
	}
	return nil
}

func comparePrerelease(left, right []string) int {
	if len(left) == 0 && len(right) == 0 {
		return 0
	}
	if len(left) == 0 {
		return 1
	}
	if len(right) == 0 {
		return -1
	}
	limit := len(left)
	if len(right) < limit {
		limit = len(right)
	}
	for index := 0; index < limit; index++ {
		leftNumber, leftNumeric := numericIdentifier(left[index])
		rightNumber, rightNumeric := numericIdentifier(right[index])
		switch {
		case leftNumeric && rightNumeric && leftNumber < rightNumber:
			return -1
		case leftNumeric && rightNumeric && leftNumber > rightNumber:
			return 1
		case leftNumeric && !rightNumeric:
			return -1
		case !leftNumeric && rightNumeric:
			return 1
		case !leftNumeric && !rightNumeric && left[index] < right[index]:
			return -1
		case !leftNumeric && !rightNumeric && left[index] > right[index]:
			return 1
		}
	}
	switch {
	case len(left) < len(right):
		return -1
	case len(left) > len(right):
		return 1
	default:
		return 0
	}
}

func numericIdentifier(value string) (uint64, bool) {
	for _, character := range value {
		if character < '0' || character > '9' {
			return 0, false
		}
	}
	number, err := strconv.ParseUint(value, 10, 64)
	return number, err == nil
}
