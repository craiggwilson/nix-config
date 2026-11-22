# Packages and shells Specification

## Purpose

Specify how this flake publishes repository-defined packages and development shells, and preserve the shared shell-application subcommand dispatch contract without freezing package pins or enumerating software.

## Requirements

### Requirement: Repository packages use the configured namespace

The package tree SHALL be imported into the flake and published under the `hdwlinux` package namespace. Package outputs SHALL be evaluated only for the flake's configured system set; the baseline SHALL NOT imply support for other systems merely because an upstream package supports them.

#### Scenario: Package output is selected on a configured system

- **WHEN** a repository package is requested for one of the configured systems
- **THEN** it SHALL be available under the `hdwlinux` namespace if its package definition supports that system
- **Source:** [package import](../../../flake.nix#L145-L162), [namespace and systems](../../../flake.nix#L173-L184), [package declarations](../../../packages/)

#### Scenario: Package requested on an unconfigured system

- **WHEN** a package is requested for a system outside the configured system set
- **THEN** the repository SHALL NOT promise that output is published or buildable
- **Source:** [configured systems](../../../flake.nix#L173-L182)

### Requirement: Development shells are published by their declared names

The shell tree SHALL be imported into the flake, and each declared development shell SHALL be published through its named `devShells` output. Shell evaluation SHALL construct the declared environment without running the interactive shell hook; hook behavior is exercised only when a shell is entered.

#### Scenario: Named development shell is evaluated

- **WHEN** a published development shell is requested on a configured system
- **THEN** its derivation SHALL evaluate under its declared shell name
- **AND** evaluation alone SHALL NOT execute interactive hook commands such as starting a shell
- **Source:** [shell import](../../../flake.nix#L145-L162), [published shell](../../../shells/go/default.nix#L1-L17), [interactive hook](../../../shells/mms/default.nix#L107-L128)

#### Scenario: Shell output is absent for an unsupported system

- **WHEN** a development shell is requested on a system outside the configured system set
- **THEN** the repository SHALL NOT promise that shell output is available
- **Source:** [configured systems](../../../flake.nix#L173-L182)

### Requirement: Shared shell applications dispatch declared subcommands safely

The shared shell-application helper SHALL dispatch named commands and nested command sets. Invalid handler types SHALL fail evaluation; unknown commands without a wildcard handler SHALL report available commands and exit nonzero.

#### Scenario: Declared command and nested command dispatch

- **WHEN** a caller invokes a declared subcommand, including a nested attribute-set command
- **THEN** the dispatcher SHALL run that command's configured handler with the subcommand removed from its arguments
- **Source:** [handler types and dispatch](../../../packages/writeShellApplicationWithSubcommands.nix#L5-L20), [nested dispatch](../../../packages/writeShellApplicationWithSubcommands.nix#L23-L51)

#### Scenario: Invalid command without wildcard fallback

- **WHEN** a caller invokes an unknown subcommand and no wildcard handler is declared
- **THEN** the application SHALL print the available subcommands and exit nonzero
- **Source:** [default and invalid-command behavior](../../../packages/writeShellApplicationWithSubcommands.nix#L29-L40)

#### Scenario: Unsupported handler value

- **WHEN** a handler value is not an attribute set, string, or path
- **THEN** evaluation SHALL fail with the helper's type error rather than silently omitting the handler
- **Source:** [handler type error](../../../packages/writeShellApplicationWithSubcommands.nix#L5-L14)
