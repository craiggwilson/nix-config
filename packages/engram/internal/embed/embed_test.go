package embed

import (
	"strings"
	"testing"
	"unicode"
)

func TestTruncateShortText(t *testing.T) {
	text := "hello world"
	if got := truncate(text); got != text {
		t.Errorf("truncate(%q) = %q, want unchanged", text, got)
	}
}

func TestTruncateLongText(t *testing.T) {
	// Build a string longer than maxRunes using repeated words.
	word := "truncation "
	text := strings.Repeat(word, 200) // ~2200 runes
	got := truncate(text)

	runes := []rune(got)
	if len(runes) > maxRunes {
		t.Errorf("truncate produced %d runes, want <= %d", len(runes), maxRunes)
	}
	if len(runes) == 0 {
		t.Error("truncate returned empty string")
	}
}

func TestTruncateCutsOnWordBoundary(t *testing.T) {
	// Construct text where the maxRunes boundary falls mid-word.
	prefix := strings.Repeat("a ", maxRunes/2) // fills ~maxRunes with "a a a ..."
	suffix := "verylongwordthatexceedsboundary"
	text := prefix + suffix

	got := truncate(text)

	// Result must not end mid-word (last rune should be a space or letter
	// from a complete word — specifically it must not contain the suffix).
	if strings.Contains(got, suffix) {
		t.Error("truncate should have cut before the long suffix word")
	}
	// Must end on a clean boundary (no trailing space after TrimSpace).
	if len(got) > 0 && unicode.IsSpace([]rune(got)[len([]rune(got))-1]) {
		t.Error("truncate result has trailing whitespace")
	}
}

func TestTruncateMultibyteUTF8(t *testing.T) {
	// Japanese characters are 3 bytes each — byte slicing would panic,
	// rune slicing must be safe.
	text := strings.Repeat("あ ", maxRunes) // well over maxRunes runes
	got := truncate(text)

	runes := []rune(got)
	if len(runes) > maxRunes {
		t.Errorf("truncate produced %d runes from multibyte input, want <= %d", len(runes), maxRunes)
	}
}
