export { TeamManager } from "./team-manager.js";
export type {
	TeamMemberRole,
	TeamStatus,
	TeamMemberStatus,
	TeamMember,
	TeamMemberResult,
	DiscussionRound,
	Team,
	CreateTeamOptions,
	TeamConfig,
} from "./team-manager.js";

export { TeamComposer } from "./team-composer.js";
export type { TeamComposerConfig } from "./team-composer.js";

export { TeamNotifier } from "./team-notifier.js";

export {
	resolvePermissions,
	getAlwaysDisabledTools,
	getWriteTools,
	hasWriteAccess,
	isReadOnly,
} from "./permission-manager.js";
export type { ToolPermissions } from "./permission-manager.js";

export { teamsModule } from "./module.js";

export { TeamManagerToken } from "./token.js";
