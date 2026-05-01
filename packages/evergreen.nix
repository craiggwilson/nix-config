{ lib, pkgs, ... }:
pkgs.buildGoModule {
  name = "evergreen";

  src = pkgs.fetchFromGitHub {
    owner = "evergreen-ci";
    repo = "evergreen";
    rev = "d0dc05a5ccedce4bdf510ca395ab1605703a2234";
    sha256 = "sha256-fd0z/MTB4nHfMOnwx54WBFflegm3b/KjeC/eRO2tI6s=";
  };

  subPackages = [ "cmd/evergreen" ];

  proxyVendor = true;
  vendorHash = "sha256-xqvgJ5nSpITPwFZn79Y5NKwMh+fhOlQG9FPoH1b3lO8=";

  meta = {
    mainProgram = "evergreen";
    description = "Evergreen - MongoDB Continuous Integration Platform";
    homepage = "https://github.com/evergreen-ci/evergreen";
  };
}
