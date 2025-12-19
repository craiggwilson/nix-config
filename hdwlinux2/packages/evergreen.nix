{ lib, pkgs, ... }:
pkgs.buildGoModule {
  name = "evergreen";

  src = pkgs.fetchFromGitHub {
    owner = "evergreen-ci";
    repo = "evergreen";
    rev = "2b11f88e5d7be0ede27f74a93efc103dd2df9f54";
    sha256 = "sha256-U7FHJ3p4HOh/EIQfmjhP2WsW9C99R0rKODGqC5hbZNg=";
  };

  subPackages = [ "cmd/evergreen" ];

  vendorHash = "sha256-HF27MWV7vwCCbIjF8srzBh0nA/nyKmd86iZAdI5cZn0=";

  meta = {
    mainProgram = "evergreen";
    description = "Evergreen - MongoDB Continuous Integration Platform";
    homepage = "https://github.com/evergreen-ci/evergreen";
  };
}
