# Desktop Sessions and Actions

## Purpose

Specify how registered desktop compositors and shells become login sessions, how applications get launchers, and how compositor-neutral actions are exposed and dispatched. Evidence: [session registry](../../../modules/desktop/sessions.nix#L8), [app roles and launcher generation](../../../modules/desktop/apps/default.nix#L7), [action schema and dispatcher](../../../modules/desktop/actions.nix#L7), [Niri action rendering](../../../modules/desktop/compositors/niri/default.nix#L97), and [Hyprland action rendering](../../../modules/desktop/compositors/hyprland/default.nix#L47).

## Requirements

### Requirement: Registered compositor and shell combinations SHALL be available as desktop sessions

Each registered compositor/shell pair SHALL produce a `<compositor>-<shell>` session with compositor metadata and shell identity. A null shell SHALL not export `HDWLINUX_SHELL`.

#### Scenario: Registered compositor and shell are combined

- **WHEN** a compositor named `niri` and a shell named `noctalia` are registered
- **THEN** the session set contains `niri-noctalia` with the compositor launch metadata and shell identifier `noctalia`
- **Evidence:** [matrix generation](../../../modules/desktop/sessions.nix#L62)

#### Scenario: A monolithic session has no shell identifier

- **WHEN** an explicit session has `shell = null`
- **THEN** its wrapper does not export `HDWLINUX_SHELL`
- **Evidence:** [session wrapper](../../../modules/desktop/sessions.nix#L87)

#### Scenario: No compositor/shell pair is registered

- **WHEN** either registration set is empty
- **THEN** no generated compositor-shell matrix entries are produced
- **Evidence:** [matrix construction](../../../modules/desktop/sessions.nix#L65)

### Requirement: Desktop sessions SHALL be rendered for the session manager

Each configured session SHALL produce a greetd desktop entry whose wrapper starts the configured session through UWSM.

#### Scenario: A configured session is rendered

- **WHEN** a session is present in the configured session set
- **THEN** the system package set includes its greetd desktop entry and the entry invokes its generated wrapper
- **Evidence:** [session entry generation](../../../modules/desktop/sessions.nix#L81)

#### Scenario: No session is configured

- **WHEN** the compositor/shell matrix and explicit session set are both empty
- **THEN** no session desktop entries are generated
- **Evidence:** [session entry generation](../../../modules/desktop/sessions.nix#L84)

### Requirement: App roles SHALL produce launchers only when configured

A non-null app role SHALL produce an `app-<role>` launcher. The launcher SHALL execute its package through UWSM, with configured arguments followed by caller-supplied arguments. A null role SHALL produce no launcher.

#### Scenario: App role is null

- **WHEN** an app role is unset
- **THEN** no launcher for that role is generated
- **Evidence:** [null filtering](../../../modules/desktop/apps/default.nix#L91)

#### Scenario: App role has package and arguments

- **WHEN** an app role has a package and configured arguments and the launcher receives additional arguments
- **THEN** the launcher invokes the package through UWSM with configured arguments before caller-supplied arguments
- **Evidence:** [launcher generation](../../../modules/desktop/apps/default.nix#L94)

### Requirement: Bound desktop actions SHALL resolve to compositor commands

Bound actions SHALL resolve to a compositor-native mapping, shell dispatcher, or configured command. A bound action with no usable implementation SHALL fail evaluation.

#### Scenario: A bound action has a compositor-native implementation

- **WHEN** a configured action has a binding and the selected compositor defines a native implementation for its name
- **THEN** the generated compositor configuration invokes that native implementation
- **Evidence:** [Niri resolution](../../../modules/desktop/compositors/niri/default.nix#L99), [Hyprland resolution](../../../modules/desktop/compositors/hyprland/default.nix#L60)

#### Scenario: A bound action uses a configured command

- **WHEN** a configured action has a binding, no native implementation, and an executable command
- **THEN** the generated compositor configuration invokes the configured command
- **Evidence:** [Niri resolution](../../../modules/desktop/compositors/niri/default.nix#L114)

#### Scenario: A bound action has no implementation

- **WHEN** a configured action has a binding but has no native implementation, command, or shell override
- **THEN** configuration evaluation fails with an action-specific error
- **Evidence:** [Niri evaluation error](../../../modules/desktop/compositors/niri/default.nix#L127)

### Requirement: Shell-specific action commands SHALL be selected at runtime

Shell-specific overrides SHALL dispatch according to `HDWLINUX_SHELL`. Otherwise the dispatcher SHALL use an executable-list default or fail. Unknown actions SHALL fail.

#### Scenario: An override exists for the current shell

- **WHEN** the dispatcher receives a known action and `HDWLINUX_SHELL` matches one of its overrides
- **THEN** it executes that shell's command
- **Evidence:** [shell dispatch](../../../modules/desktop/actions.nix#L134)

#### Scenario: No override matches but a default command exists

- **WHEN** the dispatcher receives a known action and the shell has no override
- **THEN** it executes the configured executable-list default command
- **Evidence:** [fallback selection](../../../modules/desktop/actions.nix#L139)

#### Scenario: No override or executable-list default exists

- **WHEN** the dispatcher receives a known action and no override matches and no executable-list default is configured
- **THEN** it exits unsuccessfully
- **Evidence:** [missing fallback](../../../modules/desktop/actions.nix#L139)

#### Scenario: The action name is unknown

- **WHEN** the dispatcher receives an action name that is not configured
- **THEN** it exits unsuccessfully
- **Evidence:** [unknown action](../../../modules/desktop/actions.nix#L158)

### Requirement: Desktop action input schemas SHALL reject unsupported values

Gesture, mouse-binding, and action options SHALL enforce their declared types and enum values. Gesture finger counts SHALL be positive.

#### Scenario: A positive supported gesture is configured

- **WHEN** a gesture uses a supported action and direction with a positive finger count
- **THEN** it is accepted by the option schema
- **Evidence:** [gesture schema](../../../modules/desktop/actions.nix#L7)

#### Scenario: An unsupported gesture or non-positive finger count is configured

- **WHEN** a gesture uses an unknown action/direction or a non-positive finger count
- **THEN** Nix option evaluation rejects the configuration
- **Evidence:** [gesture enums and positive count](../../../modules/desktop/actions.nix#L9)
