{
  substrate.packages.opentracker-cli =
    { pkgs, ... }:
    pkgs.buildGoModule {
      pname = "opentracker-cli";
      version = "1.5.0-beta.4";

      src = pkgs.fetchFromGitHub {
        owner = "wsmajt";
        repo = "opentracker";
        rev = "v1.5.0-beta.4";
        hash = "sha256-YboPU/GyHRDcYYID2ji8nNsmvecYfnEnNzGbc1VmL/g=";
      };

      vendorHash = "sha256-h2KZAB3pYdJAPotdj7YxF9P39EEk5OyCef2Esq2SWBA=";

      ldflags = [
        "-X main.version=1.5.0-beta.4"
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
