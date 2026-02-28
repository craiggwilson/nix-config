/**
 * XML wrapping utilities for prompt construction
 *
 * Provides utilities for wrapping content in XML tags and building
 * multi-line prompt content from arrays.
 */

/** Options for XML wrapping */
export interface XmlWrapOptions {
  /** The XML tag name */
  tag: string
  /** Content to wrap (string or array of strings joined with newlines) */
  content: string | string[]
  /** Optional attributes to add to the opening tag */
  attributes?: Record<string, string>
}

/**
 * Wrap content in XML tags.
 *
 * @example
 * ```typescript
 * // Simple usage
 * xmlWrap("context", "Some content")
 * // => "<context>\nSome content\n</context>"
 *
 * // With array content
 * xmlWrap("list", ["item 1", "item 2"])
 * // => "<list>\nitem 1\nitem 2\n</list>"
 *
 * // With options object
 * xmlWrap({ tag: "data", content: "value", attributes: { type: "json" } })
 * // => '<data type="json">\nvalue\n</data>'
 * ```
 */
export function xmlWrap(tag: string, content: string | string[]): string
export function xmlWrap(options: XmlWrapOptions): string
export function xmlWrap(
  tagOrOptions: string | XmlWrapOptions,
  content?: string | string[]
): string {
  const opts: XmlWrapOptions =
    typeof tagOrOptions === "string"
      ? { tag: tagOrOptions, content: content! }
      : tagOrOptions

  const contentStr = Array.isArray(opts.content)
    ? opts.content.join("\n")
    : opts.content

  const attrs = opts.attributes
    ? " " +
      Object.entries(opts.attributes)
        .map(([k, v]) => `${k}="${v}"`)
        .join(" ")
    : ""

  return `<${opts.tag}${attrs}>\n${contentStr}\n</${opts.tag}>`
}

/**
 * Build a prompt string from multiple parts.
 *
 * Flattens nested arrays, filters out null/undefined values,
 * and joins everything with newlines.
 *
 * @example
 * ```typescript
 * lines(
 *   "# Header",
 *   "",
 *   condition ? "Optional line" : null,
 *   ["Line 1", "Line 2"],
 *   "Footer"
 * )
 * ```
 */
export function lines(...parts: (string | string[] | null | undefined)[]): string {
  return parts
    .flat()
    .filter((p): p is string => p != null)
    .join("\n")
}

/**
 * Create a markdown section with a header.
 *
 * @example
 * ```typescript
 * section("##", "Overview", "This is the overview content.")
 * // => "## Overview\n\nThis is the overview content."
 * ```
 */
export function section(
  level: "#" | "##" | "###" | "####",
  title: string,
  content: string | string[]
): string {
  const contentStr = Array.isArray(content) ? content.join("\n") : content
  return `${level} ${title}\n\n${contentStr}`
}

/**
 * Create a bullet list from items.
 *
 * @example
 * ```typescript
 * bulletList(["First item", "Second item"])
 * // => "- First item\n- Second item"
 * ```
 */
export function bulletList(items: string[]): string {
  return items.map((item) => `- ${item}`).join("\n")
}

/**
 * Create a numbered list from items.
 *
 * @example
 * ```typescript
 * numberedList(["First step", "Second step"])
 * // => "1. First step\n2. Second step"
 * ```
 */
export function numberedList(items: string[]): string {
  return items.map((item, i) => `${i + 1}. ${item}`).join("\n")
}
