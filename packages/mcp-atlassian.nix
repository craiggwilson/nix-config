{ lib, pkgs, ... }:
let
  inherit (pkgs) python3Packages;

  markdown-to-confluence = python3Packages.buildPythonPackage rec {
    pname = "markdown-to-confluence";
    version = "0.6.3";
    format = "wheel";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/6d/1f/ad58a85343b2739a8c867e31599fee54733ce4634d428eeda35d0a58cba8/markdown_to_confluence-0.6.3-py3-none-any.whl";
      sha256 = "sha256-I9QZUCUzzlkZYrTNdjCNH81HRTMrV8Gl9nc7gjL51CM=";
    };

    dependencies = [
      python3Packages.cattrs
      python3Packages.lxml
      python3Packages.markdown
      python3Packages.orjson
      python3Packages.pathspec
      python3Packages.pymdown-extensions
      python3Packages.pyyaml
      python3Packages.requests
      python3Packages.truststore
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
  version = "0.23.0";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "sooperset";
    repo = "mcp-atlassian";
    rev = "v${version}";
    sha256 = "sha256-aTiPYMhZwWCjS/S9pZgdb4oFbXyNO7Q/aMUt0bKfSjM=";
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
    python3Packages.fastmcp
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
