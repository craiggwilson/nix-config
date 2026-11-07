{
  substrate.packages.opentracker-cli =
    { pkgs, ... }:
    pkgs.buildGoModule {
      pname = "opentracker-cli";
      version = "1.5.1";

      src = pkgs.fetchFromGitHub {
        owner = "wsmajt";
        repo = "opentracker";
        rev = "v1.5.1";
        hash = "sha256-uhEY8V0utfMOFZbU/hW9rSw/LIGFOEUiE5OgsVz1lL4=";
      };

      vendorHash = "sha256-h2KZAB3pYdJAPotdj7YxF9P39EEk5OyCef2Esq2SWBA=";

      ldflags = [
        "-X main.version=1.5.1"
        "-s"
        "-w"
      ];

      meta = {
        description = "CLI tool for tracking AI provider usage limits";
        homepage = "https://github.com/wsmajt/opentracker";
        license = pkgs.lib.licenses.mit;
        mainProgram = "opentracker";
      };
    };
}
