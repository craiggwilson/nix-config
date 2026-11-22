# Desktop Theming

## Purpose

Specify the shared theme options and the conditions under which theme colors, cursor settings, console colors, and the Catppuccin theme are applied. Evidence: [shared theme options and conditionals](../../../modules/theming/default.nix#L9) and [Catppuccin selection and configuration](../../../modules/theming/catppuccin/default.nix#L127).

## Requirements

### Requirement: Theme options SHALL be available to NixOS and Home Manager

The shared theme interface SHALL expose NixOS theme colors and system theme name, and Home Manager theme colors, cursor, dark-mode preference, name, and wallpaper. Theme colors default to an empty set; cursor and wallpaper default to null.

#### Scenario: Theme options are left at their defaults

- **WHEN** no theme colors, cursor, or wallpaper are supplied
- **THEN** colors remain empty and cursor and wallpaper remain unset
- **Evidence:** [theme defaults](../../../modules/theming/default.nix#L10), [Home Manager defaults](../../../modules/theming/default.nix#L50)

#### Scenario: A cursor theme is supplied

- **WHEN** a cursor package and name are supplied, with an optional size
- **THEN** Home Manager enables the pointer cursor using those values
- **Evidence:** [cursor option and application](../../../modules/theming/default.nix#L56)

### Requirement: NixOS console colors SHALL be derived from a configured theme palette

When theme colors are nonempty, NixOS console colors SHALL be populated from the palette's 16 ANSI color slots in standard console order. Empty colors SHALL leave this console-color configuration unapplied.

#### Scenario: A complete ANSI palette is supplied

- **WHEN** theme colors contain all required ANSI color slots
- **THEN** NixOS console colors use those 16 hex values in standard order
- **Evidence:** [console color mapping](../../../modules/theming/default.nix#L21)

#### Scenario: Theme colors are empty

- **WHEN** `hdwlinux.theme.colors` is empty
- **THEN** the theme module does not set `console.colors`
- **Evidence:** [conditional console colors](../../../modules/theming/default.nix#L21)

### Requirement: Cursor presence SHALL control shared cursor and GTK preference settings

When a non-null cursor theme is configured, Home Manager SHALL enable the pointer cursor and GTK integration, and set the GTK 3 and GTK 4 dark-theme preference from `hdwlinux.theme.dark`. When the cursor is null, this shared cursor/GTK configuration SHALL not be applied.

#### Scenario: Cursor theme is configured

- **WHEN** `hdwlinux.theme.cursor` is non-null
- **THEN** pointer cursor integration is enabled and GTK preference reflects `hdwlinux.theme.dark`
- **Evidence:** [cursor and GTK settings](../../../modules/theming/default.nix#L96)

#### Scenario: Cursor theme is unset

- **WHEN** `hdwlinux.theme.cursor` is null
- **THEN** the shared cursor/GTK configuration block is not applied
- **Evidence:** [cursor condition](../../../modules/theming/default.nix#L96)

### Requirement: Catppuccin NixOS palette SHALL require the matching system theme name

When the Catppuccin module is selected and `hdwlinux.theme.system` is `catppuccin`, NixOS SHALL publish its palette through `hdwlinux.theme.colors`. A different system theme name SHALL not activate that NixOS palette assignment.

#### Scenario: Catppuccin system theme is selected

- **WHEN** the Catppuccin module is selected and `hdwlinux.theme.system` equals `catppuccin`
- **THEN** the NixOS theme color option receives the Catppuccin palette
- **Evidence:** [system theme condition](../../../modules/theming/catppuccin/default.nix#L131)

#### Scenario: Another system theme is selected

- **WHEN** the Catppuccin module is selected and `hdwlinux.theme.system` is not `catppuccin`
- **THEN** this module does not assign its palette to the NixOS theme color option
- **Evidence:** [system theme condition](../../../modules/theming/catppuccin/default.nix#L134)

#### Scenario: Catppuccin module is not selected

- **WHEN** a configuration does not select the `desktop:theming:catppuccin` module
- **THEN** the module's Catppuccin configuration is absent
- **Evidence:** [module selector](../../../modules/theming/catppuccin/default.nix#L128)
