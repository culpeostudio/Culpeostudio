package autoupdate

import "testing"

func TestCompareVersions(t *testing.T) {
	t.Parallel()
	tests := []struct {
		name        string
		left, right string
		want        int
	}{
		{name: "older patch", left: "1.2.3", right: "1.2.4", want: -1},
		{name: "newer major", left: "v2.0.0", right: "1.99.99", want: 1},
		{name: "build ignored", left: "1.2.3+linux.4", right: "1.2.3+windows.9", want: 0},
		{name: "prerelease older", left: "1.0.0-rc.1", right: "1.0.0", want: -1},
		{name: "numeric prerelease", left: "1.0.0-rc.2", right: "1.0.0-rc.10", want: -1},
		{name: "longer prerelease", left: "1.0.0-alpha.1", right: "1.0.0-alpha", want: 1},
	}
	for _, test := range tests {
		test := test
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			got, err := CompareVersions(test.left, test.right)
			if err != nil {
				t.Fatalf("CompareVersions() error = %v", err)
			}
			if got != test.want {
				t.Fatalf("CompareVersions(%q, %q) = %d, want %d", test.left, test.right, got, test.want)
			}
		})
	}
}

func TestCompareVersionsRejectsInvalidInput(t *testing.T) {
	t.Parallel()
	for _, version := range []string{"", "1.0", "1.01.0", "1.0.0-01", "1.0.0+"} {
		if _, err := CompareVersions(version, "1.0.0"); err == nil {
			t.Errorf("CompareVersions(%q, valid) unexpectedly succeeded", version)
		}
	}
}
