{
  config.substrate.modules.ai.clients.skills.ponytail = {
    tags = [ "ai:clients" ];

    homeManager =
      { pkgs, ... }:
      let
        src = pkgs.fetchFromGitHub {
          owner = "DietrichGebert";
          repo = "ponytail";
          rev = "025da371cd7539c3eb0ad859b08b3ca55e695f16";
          hash = "sha256-4ZT89GA5xnomNBIzY8Kh1yYP0AC9SeVhv406DEKpE3A=";
        };
      in
      {
        hdwlinux.ai.clients.skills = {
          ponytail = "${src}/skills/ponytail";
          ponytail-review = "${src}/skills/ponytail-review";
          ponytail-audit = "${src}/skills/ponytail-audit";
          ponytail-debt = "${src}/skills/ponytail-debt";
          ponytail-gain = "${src}/skills/ponytail-gain";
          ponytail-help = "${src}/skills/ponytail-help";
        };
      };
  };
}
