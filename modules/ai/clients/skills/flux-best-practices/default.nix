{
  config.substrate.modules.ai.clients.skills.flux-best-practices = {
    tags = [ "ai:clients" ];

    homeManager =
      { pkgs, ... }:
      let
        src = pkgs.fetchFromGitHub {
          owner = "black-forest-labs";
          repo = "skills";
          rev = "d0793c84262183e8220a95fc1faeb5e2560aa6ef";
          hash = "sha256-9yLtKKFyZttHt63l+6lh4PAOl0t9EBZ7nTlj+cwLgKI=";
        };
      in
      {
        hdwlinux.ai.clients.skills.flux-best-practices = "${src}/skills/flux-best-practices";
      };
  };
}
