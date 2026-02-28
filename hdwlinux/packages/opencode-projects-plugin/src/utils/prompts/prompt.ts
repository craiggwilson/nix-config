/**
 * Core prompt system abstractions
 *
 * Provides the foundational types and utilities for the template-based prompt system.
 * Templates are typed objects that render prompts from structured data,
 * while sections are reusable prompt fragments that can be composed.
 */

/**
 * Base type for data passed to templates and sections.
 * Using object instead of Record<string, unknown> to allow
 * specific interfaces without requiring index signatures.
 */
export type PromptData = object

/**
 * A section is a function that renders part of a prompt.
 * Sections are composable building blocks for templates.
 */
export type PromptSection<T extends PromptData = PromptData> = (data: T) => string

/**
 * Template definition with typed slots.
 *
 * Templates are the primary abstraction for building prompts.
 * Each template has a name for debugging, an optional description,
 * and a render function that produces the final prompt string.
 *
 * @example
 * ```typescript
 * interface GreetingData {
 *   name: string
 *   role: string
 * }
 *
 * const greetingTemplate: PromptTemplate<GreetingData> = {
 *   name: "greeting",
 *   description: "Simple greeting prompt",
 *   render: (data) => `Hello ${data.name}, you are the ${data.role}.`
 * }
 * ```
 */
export interface PromptTemplate<T extends PromptData> {
  /** Unique template name for debugging/logging */
  name: string
  /** Human-readable description of what this template produces */
  description?: string
  /** Main render function that produces the prompt string */
  render: (data: T) => string
}
