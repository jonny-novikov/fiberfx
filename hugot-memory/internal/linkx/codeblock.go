package linkx

import (
	"bytes"
	"strings"
)

type Mask struct {
	Original []byte
	Masked   []byte
	InCode   []bool
}

const (
	fenceTriple = "```"
	fenceTilde  = "~~~"
)

func MaskCodeBlocks(src []byte) Mask {
	masked := make([]byte, len(src))
	inCode := make([]bool, len(src))
	copy(masked, src)

	maskFenced(masked, inCode, fenceTriple)
	maskFenced(masked, inCode, fenceTilde)
	maskInline(masked, inCode)

	return Mask{
		Original: src,
		Masked:   masked,
		InCode:   inCode,
	}
}

func maskFenced(masked []byte, inCode []bool, fence string) {
	fenceBytes := []byte(fence)
	pos := 0
	for pos < len(masked) {
		startLine, startEnd := findFenceLine(masked, pos, fenceBytes)
		if startLine < 0 {
			return
		}
		closeLine, closeEnd := findFenceLine(masked, startEnd, fenceBytes)
		if closeLine < 0 {
			eraseRange(masked, inCode, startLine, len(masked))
			return
		}
		eraseRange(masked, inCode, startLine, closeEnd)
		pos = closeEnd
	}
}

func findFenceLine(src []byte, from int, fence []byte) (lineStart, lineEnd int) {
	idx := from
	for idx < len(src) {
		bol := idx
		if bol != 0 && src[bol-1] != '\n' {
			next := bytes.IndexByte(src[bol:], '\n')
			if next < 0 {
				return -1, -1
			}
			idx = bol + next + 1
			continue
		}
		j := bol
		for j < len(src) && (src[j] == ' ' || src[j] == '\t') {
			j++
		}
		if j+len(fence) <= len(src) && bytes.Equal(src[j:j+len(fence)], fence) {
			eol := bytes.IndexByte(src[bol:], '\n')
			if eol < 0 {
				return bol, len(src)
			}
			return bol, bol + eol + 1
		}
		next := bytes.IndexByte(src[bol:], '\n')
		if next < 0 {
			return -1, -1
		}
		idx = bol + next + 1
	}
	return -1, -1
}

func maskInline(masked []byte, inCode []bool) {
	pos := 0
	for pos < len(masked) {
		start := bytes.IndexByte(masked[pos:], '`')
		if start < 0 {
			return
		}
		startAbs := pos + start
		runLen := 0
		for startAbs+runLen < len(masked) && masked[startAbs+runLen] == '`' {
			runLen++
		}
		closeFrom := startAbs + runLen
		closeRel := findInlineClose(masked, closeFrom, runLen)
		if closeRel < 0 {
			pos = startAbs + runLen
			continue
		}
		closeStart := closeFrom + closeRel
		closeEnd := closeStart + runLen
		eraseInline(masked, inCode, startAbs, closeEnd)
		pos = closeEnd
	}
}

func findInlineClose(masked []byte, from, runLen int) int {
	idx := from
	for idx < len(masked) {
		c := bytes.IndexByte(masked[idx:], '`')
		if c < 0 {
			return -1
		}
		abs := idx + c
		count := 0
		for abs+count < len(masked) && masked[abs+count] == '`' {
			count++
		}
		if count == runLen {
			return abs - from
		}
		idx = abs + count
	}
	return -1
}

func eraseRange(masked []byte, inCode []bool, start, end int) {
	if start < 0 {
		start = 0
	}
	if end > len(masked) {
		end = len(masked)
	}
	for i := start; i < end; i++ {
		inCode[i] = true
		if masked[i] != '\n' {
			masked[i] = ' '
		}
	}
}

func eraseInline(masked []byte, inCode []bool, start, end int) {
	if start < 0 {
		start = 0
	}
	if end > len(masked) {
		end = len(masked)
	}
	for i := start; i < end; i++ {
		inCode[i] = true
		if masked[i] != '\n' {
			masked[i] = ' '
		}
	}
}

func IsInCodeBlock(mask Mask, offset int) bool {
	if offset < 0 || offset >= len(mask.InCode) {
		return false
	}
	return mask.InCode[offset]
}

func ExtractInlineCodeRegions(src []byte) []InlineSpan {
	var spans []InlineSpan
	pos := 0
	for pos < len(src) {
		start := bytes.IndexByte(src[pos:], '`')
		if start < 0 {
			break
		}
		startAbs := pos + start
		if startAbs >= len(src) {
			break
		}
		if isInsideTripleFence(src, startAbs) {
			pos = startAbs + 1
			continue
		}
		runLen := 0
		for startAbs+runLen < len(src) && src[startAbs+runLen] == '`' {
			runLen++
		}
		closeFrom := startAbs + runLen
		closeRel := findInlineClose(src, closeFrom, runLen)
		if closeRel < 0 {
			pos = startAbs + runLen
			continue
		}
		closeStart := closeFrom + closeRel
		spans = append(spans, InlineSpan{
			Start: closeFrom,
			End:   closeStart,
		})
		pos = closeStart + runLen
	}
	return spans
}

type InlineSpan struct {
	Start int
	End   int
}

func isInsideTripleFence(src []byte, offset int) bool {
	prefix := src[:offset]
	count := strings.Count(string(prefix), fenceTriple)
	return count%2 == 1
}
