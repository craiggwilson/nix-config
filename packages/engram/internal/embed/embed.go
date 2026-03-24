// Package embed provides text embedding using the all-minilm-l6-v2 model.
package embed

import (
	"fmt"
	"strings"
	"sync"
	"unicode"

	"github.com/clems4ever/all-minilm-l6-v2-go/all_minilm_l6_v2"
)

// maxRunes is the maximum number of runes to pass to the tokenizer.
// The underlying tokenizer has a hard 2000-rune internal buffer; we stay
// well below it and truncate on a word boundary to avoid mid-token splits.
const maxRunes = 1500

var (
	once     sync.Once
	instance *all_minilm_l6_v2.Model
	initErr  error
)

// OnnxRuntimePath is the path to the ONNX Runtime library, set via ldflags.
var OnnxRuntimePath string

// getModel lazily initializes and returns the embedding model.
func getModel() (*all_minilm_l6_v2.Model, error) {
	once.Do(func() {
		instance, initErr = all_minilm_l6_v2.NewModel(
			all_minilm_l6_v2.WithRuntimePath(OnnxRuntimePath),
		)
	})
	return instance, initErr
}

// truncate shortens text to at most maxRunes runes, cutting at the last word
// boundary to avoid splitting mid-token.
func truncate(text string) string {
	runes := []rune(text)
	if len(runes) <= maxRunes {
		return text
	}
	runes = runes[:maxRunes]
	// Walk back to the last whitespace so we don't cut mid-word.
	for i := len(runes) - 1; i > 0; i-- {
		if unicode.IsSpace(runes[i]) {
			runes = runes[:i]
			break
		}
	}
	return strings.TrimSpace(string(runes))
}

// Embed generates a vector embedding for the given text using the all-minilm-l6-v2 model.
// The model parameter is ignored (the model is embedded in the binary).
func Embed(text, model string) ([]float32, error) {
	text = truncate(text)

	m, err := getModel()
	if err != nil {
		return nil, fmt.Errorf("initializing embedding model: %w", err)
	}

	embedding, err := m.Compute(text, true)
	if err != nil {
		return nil, fmt.Errorf("computing embedding: %w", err)
	}

	return embedding, nil
}
