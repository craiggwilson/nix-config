/// Document chunking for semantic search.
///
/// Splits documents into overlapping token-aware chunks to improve search
/// granularity. Each chunk includes the document title for context.

pub struct Chunk {
    pub index: usize,
    pub content: String,  // the text to embed
}

/// Split text into overlapping word-aware chunks.
///
/// Uses a simple word-boundary approximation: split into words, accumulate
/// until reaching `max_tokens` words (proxy for tokens), then step forward
/// by `stride` words. Prepends the document title to each chunk for context.
///
/// Parameters:
/// - `title`: Document title, prepended to each chunk
/// - `content`: Document text to chunk
/// - `max_tokens`: Maximum words per chunk (word ≈ 0.75 tokens for English)
/// - `stride`: Step size in words (determines overlap)
/// - `min_chunk_words`: Minimum words to emit a chunk (avoids tiny trailing chunks)
///
/// Returns a vector of chunks with sequential indices.
pub fn chunk_text(
    title: &str,
    content: &str,
    max_tokens: usize,
    stride: usize,
    min_chunk_words: usize,
) -> Vec<Chunk> {
    // Split content into words
    let words: Vec<&str> = content.split_whitespace().collect();

    if words.is_empty() {
        return vec![];
    }

    let mut chunks = vec![];
    let mut index = 0;
    let mut pos = 0;

    while pos < words.len() {
        // Take a chunk up to max_tokens words
        let end = (pos + max_tokens).min(words.len());
        let chunk_words: Vec<&str> = words[pos..end].to_vec();

        // Only emit chunks with at least min_chunk_words words
        if chunk_words.len() >= min_chunk_words {
            let chunk_text = chunk_words.join(" ");
            let content = format!("{}\n\n{}", title, chunk_text);
            chunks.push(Chunk { index, content });
            index += 1;
        }

        // Move forward by stride; stop if we can't fit a minimal chunk
        pos += stride;
        if pos >= words.len() {
            break;
        }
        // If remaining words can't form a chunk, we're done
        if words.len() - pos < min_chunk_words {
            break;
        }
    }

    chunks
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_chunk_simple_text() {
        let title = "Test Document";
        let content = "word1 word2 word3 word4 word5 word6 word7 word8";
        let chunks = chunk_text(title, content, 4, 2, 2);

        // With max_tokens=4, stride=2, min_chunk_words=2:
        // Chunk 0: words 0-3 (word1..word4)
        // Chunk 1: words 2-5 (word3..word6)
        // Chunk 2: words 4-7 (word5..word8)
        // Chunk 3: words 6-7 (word7..word8)
        assert_eq!(chunks.len(), 4);
        assert!(chunks[0].content.contains("word1"));
        assert!(chunks[1].content.contains("word3"));
        assert!(chunks[2].content.contains("word5"));
        assert!(chunks[3].content.contains("word7"));
    }

    #[test]
    fn test_chunk_respects_min_words() {
        let title = "Doc";
        let content = "w1 w2 w3 w4 w5";
        let chunks = chunk_text(title, content, 3, 3, 2);

        // max_tokens=3, stride=3, min_chunk_words=2
        // Chunk 0: words 0-2 (3 words) ✓
        // Chunk 1: words 3-5, but only 2 words remain (5 is out of bounds) ✓
        assert_eq!(chunks.len(), 2);
    }

    #[test]
    fn test_chunk_empty_content() {
        let title = "Empty";
        let content = "";
        let chunks = chunk_text(title, content, 128, 64, 20);
        assert_eq!(chunks.len(), 0);
    }

    #[test]
    fn test_chunk_too_small() {
        let title = "Tiny";
        let content = "only five words in this chunk";
        let chunks = chunk_text(title, content, 128, 64, 20);
        // Content has 6 words, less than min_chunk_words=20
        assert_eq!(chunks.len(), 0);
    }

    #[test]
    fn test_chunk_includes_title() {
        let title = "Important Title";
        let content = "some content words here for testing purposes";
        let chunks = chunk_text(title, content, 128, 64, 5);

        assert!(!chunks.is_empty());
        assert!(chunks[0].content.contains("Important Title"));
        assert!(chunks[0].content.contains("some content"));
    }

    #[test]
    fn test_chunk_indices_sequential() {
        let title = "Doc";
        let content = "w1 w2 w3 w4 w5 w6 w7 w8 w9 w10";
        let chunks = chunk_text(title, content, 3, 2, 2);

        for (i, chunk) in chunks.iter().enumerate() {
            assert_eq!(chunk.index, i);
        }
    }

    #[test]
    fn test_chunk_large_text() {
        let title = "Large";
        let words = vec!["word"; 1000].join(" ");
        let chunks = chunk_text(title, &words, 128, 64, 20);

        // Should create multiple chunks with overlap
        assert!(chunks.len() > 1);
        // Each chunk should have 128 words max
        for chunk in chunks {
            let chunk_word_count = chunk.content.split_whitespace().count();
            // Account for title + "\n\n" + content
            assert!(chunk_word_count <= 135, "Chunk has {} words", chunk_word_count);
        }
    }
}
