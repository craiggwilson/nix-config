{ lib, pkgs, ... }:
let
  python3Packages = pkgs.python3Packages;

  fastmcp = python3Packages.buildPythonPackage rec {
    pname = "fastmcp";
    version = "2.14.7";
    format = "wheel";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/a6/f1/56310847b0bdd5b14c2af8f0a39082af078deff60d0dc43efef4e366a83e/fastmcp-2.14.7-py3-none-any.whl";
      sha256 = "sha256-4IGlIiptMCoUiHHYn9cUsTEwzuZZT1Oj4a/XUY8AlsA=";
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
  version = "0.21.1";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "sooperset";
    repo = "mcp-atlassian";
    rev = "v${version}";
    sha256 = "sha256-KSkKiseEaDjF0ROPqLf/kO9yA7n8GV9eK96b0VMbDg4=";
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
    python3Packages.fakeredis
    python3Packages.python-dotenv
    python3Packages.markdownify
    python3Packages.markdown
    markdown-to-confluence
    python3Packages.pydantic
    python3Packages.trio
    python3Packages.click
    python3Packages.uvicorn
    python3Packages.starlette
    python3Packages.urllib3
    python3Packages.thefuzz
    python3Packages.python-dateutil
    python3Packages.types-python-dateutil
    python3Packages.keyring
    python3Packages.cachetools
    python3Packages.unidecode
    python3Packages.truststore
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
