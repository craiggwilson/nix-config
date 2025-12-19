{ lib, pkgs, ... }:
let
  python3Packages = pkgs.python3Packages;
in
python3Packages.buildPythonApplication rec {
  pname = "mongo-orchestration";
  version = "0.11.0";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "10gen";
    repo = "mongo-orchestration";
    rev = "400c3399db9b44d0cc4e53486e705bd876f526bd";
    sha256 = "sha256-hlY7WgdV0DRpQeTnO2kgtb+KG2sjezDFawhX5bFCG7k=";
  };

  build-system = [
    python3Packages.setuptools
    python3Packages.hatchling
  ];

  dependencies = [
    python3Packages.bottle
    python3Packages.cheroot
    python3Packages.pymongo
    python3Packages.requests
  ];

  meta = {
    mainProgram = pname;
    description = "Mongo Orchestration REST API for MongoDB configurations";
    homepage = "https://github.com/mongodb-labs/mongo-orchestration";
  };
}
