{
  substrate.packages.internal.opentracker-cli =
    { pkgs, ... }:
    pkgs.buildGoModule {
      pname = "opentracker-cli";
      version = "1.5.0-beta.2";

      src = pkgs.fetchFromGitHub {
        owner = "wsmajt";
        repo = "opentracker";
        rev = "3b7e88c830961bca4b3b1d1b8d7a414d5aa5756b";
        hash = "sha256-1H4TqqBPW+YUQPXdwNyVOslFkddme43tfb6c7bMwwQo=";
      };

      vendorHash = "sha256-oe6f1/jXOZmOtezM+sWQV5+Yj4fVqV/3nvpc4EovSmA=";

      ldflags = [
        "-X main.version=1.5.0-beta.2"
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
