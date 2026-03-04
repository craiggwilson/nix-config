/**
 * BeadsResponseParser - Parse and validate beads CLI responses
 */

import type { Result } from "../../utils/result/index.js";
import type { Issue } from "../issue-storage.js";
import {
	parseJSON as parseJSONInternal,
	parseBeadsIssue as parseBeadsIssueInternal,
	parseBeadsIssueArray as parseBeadsIssueArrayInternal,
	type BeadsParseError,
} from "./schemas.js";

/**
 * BeadsResponseParser handles parsing and validation of beads CLI output
 */
export class BeadsResponseParser {
	/**
	 * Parse JSON string safely
	 */
	parseJSON(jsonString: string): Result<unknown, BeadsParseError> {
		return parseJSONInternal(jsonString);
	}

	/**
	 * Parse and validate a single beads issue from raw JSON data
	 */
	parseIssue(data: unknown): Result<Issue, BeadsParseError> {
		return parseBeadsIssueInternal(data);
	}

	/**
	 * Parse and validate an array of beads issues from raw JSON data
	 */
	parseIssueArray(data: unknown): Result<Issue[], BeadsParseError> {
		return parseBeadsIssueArrayInternal(data);
	}
}
