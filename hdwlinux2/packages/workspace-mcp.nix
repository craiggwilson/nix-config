{ lib, pkgs, ... }:
let
  python3Packages = pkgs.python3Packages;

  fastmcp = python3Packages.buildPythonPackage rec {
    pname = "fastmcp";
    version = "2.12.5";
    pyproject = true;

    src = python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-Lf0C4lVwWkr+Q9JsrdvIZFYwNuIz28aHDzie5SOzmmo=";
    };

    build-system = [
      python3Packages.hatchling
      python3Packages.uv-dynamic-versioning
    ];

    dependencies = [
      python3Packages.mcp
      python3Packages.pydantic
      python3Packages.pydantic-settings
      python3Packages.httpx
      python3Packages.uvicorn
      python3Packages.starlette
      python3Packages.click
      python3Packages.python-dotenv
      python3Packages.rich
      python3Packages.typer
      python3Packages.exceptiongroup
      python3Packages.websockets
      python3Packages.authlib
    ];

    doCheck = false;
    dontCheckRuntimeDeps = true;

    meta = with lib; {
      description = "FastMCP - A fast, simple framework for building MCP servers";
      homepage = "https://github.com/jlowin/fastmcp";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };
in
python3Packages.buildPythonApplication rec {
  pname = "workspace-mcp";
  version = "1.6.1";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "taylorwilsdon";
    repo = "google_workspace_mcp";
    rev = "v${version}";
    sha256 = "sha256-8CnynYutbuIBHPoq9bAWSpuRDsLF1oWZjLDmD8Q7Rtk=";
  };

  build-system = [
    python3Packages.setuptools
    python3Packages.wheel
  ];

  dependencies = [
    python3Packages.fastapi
    fastmcp
    python3Packages.google-api-python-client
    python3Packages.google-auth-httplib2
    python3Packages.google-auth-oauthlib
    python3Packages.httpx
    python3Packages.pyjwt
    python3Packages.python-dotenv
    python3Packages.pyyaml
  ];

  doCheck = false;
  dontCheckRuntimeDeps = true;

  meta = with lib; {
    mainProgram = "workspace-mcp";
    description = "Google Workspace MCP Server for Calendar, Gmail, Docs, Sheets, Slides & Drive";
    homepage = "https://github.com/taylorwilsdon/google_workspace_mcp";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
