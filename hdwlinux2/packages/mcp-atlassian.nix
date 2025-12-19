{ lib, pkgs, ... }:
let
  python3Packages = pkgs.python3Packages;

  fastmcp-legacy = python3Packages.buildPythonPackage rec {
    pname = "fastmcp";
    version = "2.3.4";
    pyproject = true;

    src = python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-8/4AS4c1s2WmXsJUfutH24NS1WE2lyVIVLx8nDw2Duo=";
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
    ];

    doCheck = false;
    dontCheckRuntimeDeps = true;

    meta = with lib; {
      description = "FastMCP - A fast, simple framework for building Model Context Protocol servers";
      homepage = "https://github.com/jlowin/fastmcp";
      license = licenses.mit;
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
  version = "0.11.0";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "sooperset";
    repo = "mcp-atlassian";
    rev = "ca05d51cea76ac19c37c6d30a5883b1f6fe74caf";
    sha256 = "sha256-nDjIM98DsPwqbjDkVhwErBSWTR911lxa6w8NM9GrdPE=";
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
    fastmcp-legacy
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
    python3Packages.cachetools
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
