# AI scheduled tasks

## Purpose

Specify how harness-agnostic scheduled agent task definitions become OpenCode prompt files and systemd user units. The baseline describes generated configuration only; it does not authorize starting tasks or assert that external commands complete successfully.

## Requirements

### Requirement: Task definitions have typed inputs and safe defaults

Each task SHALL define a description, prompt path, and calendar schedule. Optional fields SHALL use their declared defaults, including no agent/model override, no session continuation, auto-approval enabled, no extra packages or secret scope, a one-hour timeout, and the home directory as working directory.

#### Scenario: Minimal valid task

- WHEN a task supplies its required description, prompt, and schedule
- THEN omitted optional values use the declared defaults

#### Scenario: Missing required task field

- WHEN a task omits its description, prompt, or schedule
- THEN module evaluation rejects the incomplete task definition

### Requirement: Each configured task renders a service, timer, and prompt

The OpenCode renderer SHALL generate a prompt file, an `ai-task-<name>` oneshot user service, and a persistent timer using the configured calendar schedule. The service SHALL use the configured timeout and working directory.

#### Scenario: Render a configured task

- WHEN a valid task is present
- THEN its prompt, service, and persistent timer are generated under the task's name

#### Scenario: No configured tasks

- WHEN the task collection is empty
- THEN no task prompt files, task services, or task timers are generated

#### Scenario: Expand a home-relative working directory

- WHEN the working directory begins with `~`
- THEN the generated service uses the corresponding absolute path under the configured home directory

### Requirement: Task execution reflects opt-in overrides

The generated command SHALL include optional agent, model, continuation, and auto-approval flags only when configured. A task model SHALL resolve to its alias's primary entry. Its `PATH` SHALL include the core tools and task packages, and declared prerequisites SHALL become service-ordering dependencies.

#### Scenario: Task with explicit execution options

- WHEN a task sets an agent, model, continuation, or auto-approval option
- THEN only the corresponding requested flags are added and a model alias resolves to its primary entry

#### Scenario: Task without optional execution options

- WHEN a task leaves the optional agent, model, and continuation values unset and disables auto-approval
- THEN the generated command omits those flags

### Requirement: Secret scopes are applied only when configured

The task renderer SHALL apply a secrets-scope wrapper only when `secretsScope` is set. Generated task configuration SHALL contain runtime secret wiring, not resolved secret values.

#### Scenario: Task has a secret scope

- WHEN a task names a secrets scope
- THEN its launcher is wrapped to resolve that scope at execution time

#### Scenario: Task has no secret scope

- WHEN `secretsScope` is null
- THEN the generated service launches the task script directly without a secrets-scope wrapper

## Sources

- [Task type and defaults](../../../modules/ai/clients/default.nix#L82-L160)
- [Task alias and command options](../../../modules/ai/clients/tasks/default.nix#L15-L50)
- [Task PATH, execution, ordering, service, timer, and prompt rendering](../../../modules/ai/clients/tasks/default.nix#L64-L125)
- [Secret-scope option](../../../modules/ai/clients/default.nix#L140-L149) · [conditional wrapper](../../../modules/ai/clients/tasks/default.nix#L81-L91)
