# Nix Modules

## Module Structure

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.myservice;
in {
  options.services.myservice = {
    enable = lib.mkEnableOption "my service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port to listen on";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Additional settings";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.myservice = {
      description = "My Service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.myservice}/bin/myservice --port ${toString cfg.port}";
        Restart = "always";
      };
    };
  };
}
```

## Option Types

```nix
lib.types.str              # String
lib.types.int              # Integer
lib.types.bool             # Boolean
lib.types.path             # Path
lib.types.package          # Nix package
lib.types.port             # Port number (1-65535)

lib.types.listOf types.str           # List of strings
lib.types.attrsOf types.int          # Attribute set of integers
lib.types.nullOr types.str           # String or null
lib.types.either types.str types.int # String or integer

lib.types.enum [ "a" "b" "c" ]       # One of specific values
lib.types.submodule { ... }          # Nested module
```

## mkOption

```nix
lib.mkOption {
  type = lib.types.str;
  default = "value";
  example = "example value";
  description = "Description of the option";
}

# Required option (no default)
lib.mkOption {
  type = lib.types.str;
  description = "Required string";
}

# With apply function
lib.mkOption {
  type = lib.types.str;
  apply = lib.toLower;
}
```

## Conditional Configuration

```nix
config = lib.mkIf cfg.enable {
  # Only applied when cfg.enable is true
};

# Merge multiple conditions
config = lib.mkMerge [
  (lib.mkIf cfg.enable {
    # Base config
  })
  (lib.mkIf cfg.debug {
    # Debug config
  })
];
```

## Submodules

```nix
options.servers = lib.mkOption {
  type = lib.types.attrsOf (lib.types.submodule {
    options = {
      host = lib.mkOption {
        type = lib.types.str;
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 80;
      };
    };
  });
  default = {};
};

# Usage
config.servers = {
  web = { host = "web.example.com"; port = 443; };
  api = { host = "api.example.com"; };
};
```

## Imports

```nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./users.nix
  ];

  # Rest of configuration
}
```

## Home Manager Module

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.myprogram;
in {
  options.programs.myprogram = {
    enable = lib.mkEnableOption "myprogram";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.myprogram;
    };

    config = lib.mkOption {
      type = lib.types.lines;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."myprogram/config".text = cfg.config;
  };
}
```

## Priority and Ordering

```nix
# Default priority is 100
lib.mkDefault value      # Priority 1000 (low)
lib.mkOptionDefault value # Priority 1500 (lower)
lib.mkForce value        # Priority 50 (high)
lib.mkOverride 10 value  # Custom priority
```
