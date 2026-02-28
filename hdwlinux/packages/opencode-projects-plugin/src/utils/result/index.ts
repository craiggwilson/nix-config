/**
 * Result type module for error handling
 */

export type { Result, BaseError } from "./result.js"
export { ok, err, isOk, isErr, unwrap, unwrapOr, map, mapErr, flatMap } from "./result.js"
