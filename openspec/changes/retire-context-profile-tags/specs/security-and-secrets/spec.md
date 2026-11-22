## MODIFIED Requirements

### Requirement: Deployment access is explicit and separately privileged

The deployment account SHALL use its configurable SSH key and SHALL be distinct from the interactive user. Its Nix-daemon and passwordless-sudo privileges SHALL remain scoped to deployment.

#### Scenario: Deployment account is selected

- **WHEN** the base deployment-user module is applied
- **THEN** the `deploy` account SHALL exist with its configured SSH public key, wheel membership, Nix trust, and NOPASSWD sudo rule
- **Source:** [account and key option](../../../modules/security/deploy-user/default.nix#L12-L30), [Nix access and sudo rule](../../../modules/security/deploy-user/default.nix#L32-L51)

#### Scenario: Interactive-user privilege remains separate

- **WHEN** an interactive user is evaluated under the workstation or server sudo module
- **THEN** sudo-rs SHALL remain enabled with wheel restriction and password requirement
- **AND** the deploy account's NOPASSWD rule SHALL NOT make the interactive user's commands passwordless
- **Source:** [interactive sudo policies](../../../modules/security/sudo/workstation.nix#L2-L16) and [server sudo policy](../../../modules/security/sudo/server.nix#L2-L16), [deploy-only sudo rule](../../../modules/security/deploy-user/default.nix#L37-L50)
