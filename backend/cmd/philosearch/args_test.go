package main

import (
	"flag"
	"reflect"
	"testing"
)

// newTestFlagSet baut ein FlagSet mit denselben Flag-Arten wie runSearch:
// ein int-Flag mit Wert und ein bool-Flag ohne.
func newTestFlagSet() *flag.FlagSet {
	fs := flag.NewFlagSet("test", flag.ContinueOnError)
	fs.Int("max", 10, "")
	fs.String("region", "us-en", "")
	fs.Bool("json", false, "")
	return fs
}

func TestSplitArgs(t *testing.T) {
	cases := []struct {
		name    string
		args    []string
		wantPos []string
		wantFlg []string
	}{
		{
			name:    "flags nach der query",
			args:    []string{"railway nginx", "-max", "5", "-json"},
			wantPos: []string{"railway nginx"},
			wantFlg: []string{"-max", "5", "-json"},
		},
		{
			name:    "flags vor der query",
			args:    []string{"-max", "5", "railway nginx"},
			wantPos: []string{"railway nginx"},
			wantFlg: []string{"-max", "5"},
		},
		{
			name:    "flags auf beiden seiten",
			args:    []string{"-json", "nginx", "-region", "de-de", "proxy"},
			wantPos: []string{"nginx", "proxy"},
			wantFlg: []string{"-json", "-region", "de-de"},
		},
		{
			name:    "gleichheitszeichen-form",
			args:    []string{"nginx", "--max=5"},
			wantPos: []string{"nginx"},
			wantFlg: []string{"--max=5"},
		},
		{
			name:    "doppelstrich beendet flags",
			args:    []string{"--", "-max", "5"},
			wantPos: []string{"-max", "5"},
			wantFlg: nil,
		},
		{
			name:    "nur positional",
			args:    []string{"tls", "fingerprint"},
			wantPos: []string{"tls", "fingerprint"},
			wantFlg: nil,
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			pos, flg := splitArgs(newTestFlagSet(), tc.args)
			if !reflect.DeepEqual(pos, tc.wantPos) {
				t.Errorf("positional = %q, erwartet %q", pos, tc.wantPos)
			}
			if !reflect.DeepEqual(flg, tc.wantFlg) {
				t.Errorf("flags = %q, erwartet %q", flg, tc.wantFlg)
			}
		})
	}
}

// TestSplitArgsRoundtrip prueft, dass die getrennten Flags vom
// flag-Paket auch tatsaechlich geparst werden.
func TestSplitArgsRoundtrip(t *testing.T) {
	fs := newTestFlagSet()
	pos, flg := splitArgs(fs, []string{"railway nginx", "-max", "5", "-json"})
	if err := fs.Parse(flg); err != nil {
		t.Fatalf("Parse: %v", err)
	}
	if got := fs.Lookup("max").Value.String(); got != "5" {
		t.Errorf("max = %s, erwartet 5", got)
	}
	if got := fs.Lookup("json").Value.String(); got != "true" {
		t.Errorf("json = %s, erwartet true", got)
	}
	if len(pos) != 1 || pos[0] != "railway nginx" {
		t.Errorf("positional = %q, erwartet [\"railway nginx\"]", pos)
	}
}
