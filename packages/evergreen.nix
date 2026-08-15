{ lib, pkgs, ... }:
pkgs.buildGoModule {
  name = "evergreen";

  src = pkgs.fetchFromGitHub {
    owner = "evergreen-ci";
    repo = "evergreen";
    rev = "4a0f3eb2b6fb04354a32a25e649b28cd57b9c220";
    sha256 = "sha256-9BHt0gkFeDk3rTwKybDd17dsdH/WyIquWkg7qSLFF/8=";
  };

  subPackages = [ "cmd/evergreen" ];

  proxyVendor = true;
  vendorHash = "sha256-3Bty8mJD+/HVlNibrcEjtswZnH4sqf4NQjpt3np6j6k=";

  meta = {
    mainProgram = "evergreen";
    description = "Evergreen - MongoDB Continuous Integration Platform";
    homepage = "https://github.com/evergreen-ci/evergreen";
  };
}
