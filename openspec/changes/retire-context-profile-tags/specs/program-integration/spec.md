## MODIFIED Requirements

### Requirement: Profile-specific integrations remain separated

Work- and personal-specific variants SHALL be Craig-owned configuration selected by `user:craig` and the Craig user instance (`craig@work` or `craig@personal`), and contribute configuration only when selected. Selecting one variant SHALL not implicitly select another, and neither variant SHALL be selected by a `profile:work` or `profile:personal` tag.

#### Scenario: Select work mail filters

- WHEN the `craig@work` instance is evaluated
- THEN the work filter package is contributed

#### Scenario: Select personal mail filters

- WHEN the `craig@personal` instance is evaluated
- THEN the personal filter package is contributed without selecting the work variant

#### Scenario: Neither profile matches

- WHEN neither instance applies (for example `craig@server`)
- THEN neither profile-specific filter package is contributed
