{
  config.substrate.modules.programs.orca-ide = {
    tags = [
      "ai:clients"
      "gui"
    ];

    homeManager =
      { pkgs, ... }:
      let
        src = pkgs.fetchFromGitHub {
          owner = "stablyai";
          repo = "orca";
          rev = "v1.4.158";
          hash = "sha256-JmrH6o9BP7qCLjGlijw6ZQDGANipVbRznO6X5cmoAOc=";
        };
      in
      {
        home.packages = [ pkgs.hdwlinux.orca-ide ];

        hdwlinux.ai.clients.skills = {
          orca-cli = "${src}/skills/orca-cli";
          orchestration = "${src}/skills/orchestration";
        };
      };
  };
}
