{ lib, pkgs, ... }:
let
  inherit (pkgs) python3Packages;
in
python3Packages.buildPythonApplication rec {
  pname = "laya-mcp";
  version = "0.2.2";
  pyproject = true;

  # sdist filename normalizes the dash to an underscore, breaking fetchPypi's URL guess
  src = pkgs.fetchurl {
    url = "https://files.pythonhosted.org/packages/source/l/laya-mcp/laya_mcp-${version}.tar.gz";
    hash = "sha256-/23XYlNw5FlOutpC2C+CeiPfErs+H7gEo7Xif3ASC2g=";
  };

  build-system = with python3Packages; [
    setuptools
    wheel
  ];

  dependencies = [
    pkgs.hdwlinux.laya
    python3Packages.mcp
  ];

  # Upstream test suite requires a network-attached model and dev extras.
  doCheck = false;

  meta = {
    description = "MCP server exposing Laya typed decisions (ask/noul/choice/score/plan) to coding agents";
    homepage = "https://github.com/PerryLink/laya-mcp";
    license = lib.licenses.mit;
    mainProgram = "laya-mcp";
  };
}
