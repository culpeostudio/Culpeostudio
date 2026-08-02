package philobot

import (
	"fmt"
	"strings"
)

const (
	maxDiffLines = 1500

	diffContextLines = 3
)

type diffOp struct {
	kind byte
	text string
}

func canDiffText(oldText, newText string) bool {
	if len(oldText) > 256*1024 || len(newText) > 256*1024 {
		return false
	}
	oldLines := strings.Count(oldText, "\n") + 1
	newLines := strings.Count(newText, "\n") + 1
	return oldLines <= maxDiffLines && newLines <= maxDiffLines
}

func unifiedDiff(oldText, newText, relPath string) string {
	oldLines := splitDiffLines(oldText)
	newLines := splitDiffLines(newText)
	ops := diffOps(oldLines, newLines)
	hunks := groupDiffHunks(ops)
	if len(hunks) == 0 {
		return ""
	}
	var b strings.Builder
	fmt.Fprintf(&b, "--- a/%s\n+++ b/%s\n", relPath, relPath)
	for _, hunk := range hunks {
		oldCount := countKind(hunk.ops, ' ') + countKind(hunk.ops, '-')
		newCount := countKind(hunk.ops, ' ') + countKind(hunk.ops, '+')
		fmt.Fprintf(&b, "@@ -%d,%d +%d,%d @@\n", hunk.oldStart, oldCount, hunk.newStart, newCount)
		for _, op := range hunk.ops {
			b.WriteByte(op.kind)
			b.WriteString(op.text)
			b.WriteByte('\n')
		}
	}
	return b.String()
}

func splitDiffLines(text string) []string {
	if text == "" {
		return nil
	}
	lines := strings.Split(text, "\n")

	if len(lines) > 0 && lines[len(lines)-1] == "" {
		lines = lines[:len(lines)-1]
	}
	return lines
}

func diffOps(oldLines, newLines []string) []diffOp {
	n, m := len(oldLines), len(newLines)

	lcs := make([][]int, n+1)
	for i := range lcs {
		lcs[i] = make([]int, m+1)
	}
	for i := n - 1; i >= 0; i-- {
		for j := m - 1; j >= 0; j-- {
			if oldLines[i] == newLines[j] {
				lcs[i][j] = lcs[i+1][j+1] + 1
			} else if lcs[i+1][j] >= lcs[i][j+1] {
				lcs[i][j] = lcs[i+1][j]
			} else {
				lcs[i][j] = lcs[i][j+1]
			}
		}
	}
	ops := make([]diffOp, 0, n+m)
	i, j := 0, 0
	for i < n && j < m {
		switch {
		case oldLines[i] == newLines[j]:
			ops = append(ops, diffOp{' ', oldLines[i]})
			i++
			j++
		case lcs[i+1][j] >= lcs[i][j+1]:
			ops = append(ops, diffOp{'-', oldLines[i]})
			i++
		default:
			ops = append(ops, diffOp{'+', newLines[j]})
			j++
		}
	}
	for ; i < n; i++ {
		ops = append(ops, diffOp{'-', oldLines[i]})
	}
	for ; j < m; j++ {
		ops = append(ops, diffOp{'+', newLines[j]})
	}
	return ops
}

type diffHunk struct {
	ops                []diffOp
	oldStart, newStart int
}

func groupDiffHunks(ops []diffOp) []diffHunk {

	oldLine, newLine := 1, 1
	type numberedOp struct {
		op           diffOp
		oldNo, newNo int
	}
	numbered := make([]numberedOp, 0, len(ops))
	for _, op := range ops {
		entry := numberedOp{op: op}
		if op.kind != '+' {
			entry.oldNo = oldLine
			oldLine++
		}
		if op.kind != '-' {
			entry.newNo = newLine
			newLine++
		}
		numbered = append(numbered, entry)
	}

	var hunks []diffHunk
	var current []numberedOp
	var pendingContext []numberedOp
	gap := 0
	flush := func() {
		if len(current) == 0 {
			return
		}
		hunk := diffHunk{}
		for _, entry := range current {
			if hunk.oldStart == 0 && entry.op.kind != '+' {
				hunk.oldStart = entry.oldNo
			}
			if hunk.newStart == 0 && entry.op.kind != '-' {
				hunk.newStart = entry.newNo
			}
			hunk.ops = append(hunk.ops, entry.op)
		}
		hunks = append(hunks, hunk)
		current = nil
		pendingContext = nil
		gap = 0
	}
	for _, entry := range numbered {
		if entry.op.kind == ' ' {
			if current == nil {
				pendingContext = append(pendingContext, entry)
				if len(pendingContext) > diffContextLines {
					pendingContext = pendingContext[1:]
				}
				continue
			}
			gap++
			if gap > 2*diffContextLines {

				current = current[:len(current)-(gap-diffContextLines)]
				flush()
				pendingContext = append(pendingContext, entry)
				continue
			}
			current = append(current, entry)
			continue
		}
		if current == nil {
			current = append(current, pendingContext...)
		}
		pendingContext = nil
		gap = 0
		current = append(current, entry)
	}
	if current != nil {

		trim := 0
		for i := len(current) - 1; i >= 0 && current[i].op.kind == ' '; i-- {
			trim++
		}
		if trim > diffContextLines {
			current = current[:len(current)-(trim-diffContextLines)]
		}
		flush()
	}
	return hunks
}

func countKind(ops []diffOp, kind byte) int {
	count := 0
	for _, op := range ops {
		if op.kind == kind {
			count++
		}
	}
	return count
}
