/**
 * Result type module for error handling
 */

export type { Result, BaseError } from "./result.js";
export {
	all,
	err,
	firstOk,
	flatMap,
	fromPromise,
	isErr,
	isOk,
	map,
	mapErr,
	match,
	ok,
	orElse,
	tap,
	tapErr,
	toPromise,
	tryCatch,
	tryCatchAsync,
	unwrap,
	unwrapOr,
	unwrapOrElse,
} from "./result.js";
