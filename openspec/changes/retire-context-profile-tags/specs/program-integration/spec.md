## MODIFIED Requirements

### Requirement: Profile-specific integrations remain separated

Work- and personal-specific variants SHALL be Craig-owned configuration selected by the matching identity leaf (`user:craig:work` or `user:craig:personal`) plus `profile:email-management`. Selecting one variant SHALL not implicitly select another, and neither variant SHALL be selected by `profile:work` or `profile:personal`.

#### Scenario: Select work mail filters

- WHEN `craig@work` declares `user:craig:work` and `profile:email-management`
- THEN the work filter package is contributed

#### Scenario: Select personal mail filters

- WHEN `craig@personal` declares `user:craig:personal` and `profile:email-management`
- THEN the personal filter package is contributed without selecting the work variant

#### Scenario: Neither profile matches

- WHEN neither identity leaf applies (for example `craig@server`)
- THEN neither profile-specific filter package is contributed

## ADDED Requirements

### Requirement: Masked-email integration separates generic behavior from account secrets

The generic maskedemail module SHALL be selected by `profile:email-management` and SHALL expose a `tokenFile` option without declaring Craig's Fastmail secret reference. Craig's Fastmail reference and token-file assignment SHALL be selected by `user:craig:personal`, `core:security:secrets`, and `profile:email-management`. The same category SHALL also group Fastmail MCP (with `profile:ai`) and both Craig mail-filter variants.

#### Scenario: Generic maskedemail integration

- WHEN a user declares `profile:email-management` and configures `hdwlinux.programs.maskedemail.tokenFile`
- THEN the generic wrapper and helper SHALL be installed without Craig's Fastmail secret entry

#### Scenario: Generic maskedemail without a token

- WHEN a user declares `profile:email-management` and leaves `tokenFile` null
- THEN the generic unwrapped CLI and helper SHALL be installed without Craig's Fastmail secret entry

#### Scenario: Craig personal maskedemail integration

- WHEN `craig@personal` is evaluated
- THEN the Fastmail reference SHALL supply the generic wrapper's token file
- AND `craig@work` and `craig@server` SHALL NOT receive Craig's maskedemail account settings
