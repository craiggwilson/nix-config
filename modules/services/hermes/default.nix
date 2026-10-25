{ inputs, ... }:
{
  config.substrate.modules.services.hermes = {
    tags = [ "host:soulsmith" ];

    nixos = {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      services.hermes-agent = {
        enable = true;
        addToSystemPackages = true;
        stateDir = "/var/lib/hermes";
        workingDirectory = "/var/lib/hermes/workspace";

        settings = {
          model = {
            base_url = "http://wintersteel:9292/v1";
            context_length = 65536;
            default = "Qwen3.8-27B-UD-Q4_K_XL";
            provider = "custom";
          };
          terminal.backend = "local";
        };
      };

      users.users.craig = {
        extraGroups = [ "hermes" ];
        linger = true;
      };
    };
  };
}
