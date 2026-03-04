import { Token } from "../container/index.js";
import type { IssueStorage } from "./issue-storage.js";

/** DI token for the {@link IssueStorage} singleton. */
export const IssueStorageToken = new Token<IssueStorage>("IssueStorage");
