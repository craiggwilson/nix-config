{
  config.substrate.modules.services.augment-openai-proxy = {
    tags = [
      "ai:agent"
      "users:craig:work"
    ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.hdwlinux.services.augment-openai-proxy;
      in
      {
        options.hdwlinux.services.augment-openai-proxy = {
          port = lib.mkOption {
            description = "The port on which to host the proxy.";
            type = lib.types.int;
            default = 9191;
          };
        };

        config.systemd.user.services.augment-openai-proxy = {
          Unit = {
            Description = "OpenAI-compatible API proxy for Augment Code backends";
            Documentation = [ "https://github.com/craiggwilson/augment-opencode" ];
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
          Service = {
            Type = "simple";
            ExecStart = "${pkgs.hdwlinux.augment-openai-proxy}/bin/augment-openai-proxy";
            Restart = "on-failure";
            RestartSec = 10;
            Environment = "PORT=${lib.toString cfg.port}";
          };
        };
      };
  };
}
