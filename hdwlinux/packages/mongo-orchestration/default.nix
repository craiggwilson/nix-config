{
  pkgs,
  python3Packages,
  ...
}:

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

    # testing
    # pkgs.python3Packages.coverage
    # pkgs.python3Packages.pexpect
    # pkgs.python3Packages.pytest
  ];

  meta = {
    mainProgram = pname;
    description = "Mongo Orchestration is an HTTP server that provides a REST API for creating and managing MongoDB configurations on a single host.";
    homepage = "https://github.com/mongodb-labs/mongo-orchestration";
  };
}
