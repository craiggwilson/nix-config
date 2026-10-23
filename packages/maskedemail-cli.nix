{
  substrate.packages.internal.maskedemail-cli =
    { lib, pkgs, ... }:
    pkgs.buildGoModule rec {
      pname = "maskedemail-cli";
      version = "1.0.1";

      src = pkgs.fetchFromGitHub {
        owner = "dvcrn";
        repo = "maskedemail-cli";
        rev = version;
        hash = "sha256-xitG2Utnn6DH48yqISQ2B3i8JqCgNKCL5VXDX4WH8/A=";
      };

      vendorHash = "sha256-q6DbxF9C0gq9wTDyrZxuED3o4KG1nR9McEavRhEtwYs=";

      ldflags = [
        "-s"
        "-w"
        "-X main.buildVersion=${version}"
        "-X main.buildCommit=${src.rev}"
        "-buildid="
      ];

      env.CGO_ENABLED = "0";

      meta = {
        description = "CLI to create Fastmail Masked Emails";
        homepage = "https://github.com/dvcrn/maskedemail-cli";
        mainProgram = "maskedemail-cli";
        platforms = lib.platforms.linux ++ lib.platforms.darwin;
      };
    };
}
