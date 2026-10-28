{
  substrate.packages.mongo-orchestration =
    { pkgs, ... }:
    let
      inherit (pkgs) python3Packages;
    in
    python3Packages.buildPythonApplication rec {
      pname = "mongo-orchestration";
      version = "0.11.1";
      pyproject = true;

      src = pkgs.fetchFromGitHub {
        owner = "10gen";
        repo = "mongo-orchestration";
        rev = "0.11.1";
        sha256 = "sha256-6GxktOUTetJcpCpoWMgiUAH2+AJ5JAQm5hurJFptIXA=";
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
    };
}
