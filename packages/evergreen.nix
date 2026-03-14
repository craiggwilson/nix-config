{ lib, pkgs, ... }:
pkgs.buildGoModule {
  name = "evergreen";

  src = pkgs.fetchFromGitHub {
    owner = "evergreen-ci";
    repo = "evergreen";
    rev = "c8fb1ac2d485cdf17a3d9f87be266a6d3963bdea";
    sha256 = "sha256-mxZswcuhOSap1j/+iYPkGtoUnS+ivINxj2EpVD7K32Y=";
  };

  subPackages = [ "cmd/evergreen" ];

  proxyVendor = true;
  vendorHash = "sha256-A9qtFwoewr4f0HXFk+Y5EALMJ9UIn3i+zxuY9+ZRQ9U=";

  meta = {
    mainProgram = "evergreen";
    description = "Evergreen - MongoDB Continuous Integration Platform";
    homepage = "https://github.com/evergreen-ci/evergreen";
  };
}
