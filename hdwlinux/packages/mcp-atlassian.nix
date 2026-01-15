{ lib, pkgs, ... }:
let
  python3Packages = pkgs.python3Packages;

  fastmcp = python3Packages.buildPythonPackage rec {
    pname = "fastmcp";
    version = "2.2.7";
    format = "wheel";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/dc/65/a68d6288963d89a43a880c6e6f38caf24d26eef9149200797891f56ae02a/fastmcp-2.2.7-py3-none-any.whl";
      sha256 = "sha256-B0dCek9RWD6Frc7q7Rh6QDKm4nxwVZDZUbRfA+2FFIs=";
    };

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
      python3Packages.websockets
      python3Packages.exceptiongroup
    ];

    doCheck = false;
    dontCheckRuntimeDeps = true;

    meta = with lib; {
      description = "FastMCP - A fast, simple framework for building Model Context Protocol servers";
      homepage = "https://github.com/jlowin/fastmcp";
      license = licenses.asl20;
      platforms = platforms.all;
    };
  };

  markdown-to-confluence = python3Packages.buildPythonPackage rec {
    pname = "markdown-to-confluence";
    version = "0.3.5";
    pyproject = true;

    src = python3Packages.fetchPypi {
      pname = "markdown_to_confluence";
      inherit version;
      sha256 = "sha256-QwmvYlaC9tMA4ReZK4fmRZqK5rZT3uL5Empnis8Hbws=";
    };

    build-system = [
      python3Packages.setuptools
      python3Packages.wheel
    ];

    propagatedBuildInputs = [
      python3Packages.requests
      python3Packages.markdown
      python3Packages.beautifulsoup4
      python3Packages.pyyaml
      python3Packages.python-frontmatter
      python3Packages.pillow
      python3Packages.lxml
      python3Packages.cattrs
      python3Packages.orjson
      python3Packages.pymdown-extensions
    ];

    doCheck = false;
    dontCheckRuntimeDeps = true;

    meta = with lib; {
      description = "Publish Markdown files to Confluence wiki";
      homepage = "https://github.com/hunyadi/md2conf";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };
in
python3Packages.buildPythonApplication rec {
  pname = "mcp-atlassian";
  version = "0.10.3";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "sooperset";
    repo = "mcp-atlassian";
    rev = "v${version}";
    sha256 = "sha256-aD2O4TSDtof7gsm0FL0ipnjz5IoOV4r3ff0Ylcz0TDo=";
  };

  build-system = [
    python3Packages.hatchling
    python3Packages.uv-dynamic-versioning
  ];

  dependencies = [
    python3Packages.atlassian-python-api
    python3Packages.requests
    python3Packages.beautifulsoup4
    python3Packages.httpx
    python3Packages.mcp
    fastmcp
    python3Packages.python-dotenv
    python3Packages.markdownify
    python3Packages.markdown
    markdown-to-confluence
    python3Packages.pydantic
    python3Packages.trio
    python3Packages.click
    python3Packages.uvicorn
    python3Packages.starlette
    python3Packages.thefuzz
    python3Packages.python-dateutil
    python3Packages.types-python-dateutil
    python3Packages.keyring
  ];

  doCheck = false;
  dontCheckRuntimeDeps = true;

  meta = with lib; {
    mainProgram = pname;
    description = "MCP Atlassian integration for AI language models";
    homepage = "https://github.com/sooperset/mcp-atlassian";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
