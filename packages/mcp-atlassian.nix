{
  substrate.packages.mcp-atlassian =
    { lib, pkgs, ... }:
    let
      # fastmcp and mcp-atlassian require mcp < 2; nixpkgs 26.11 ships mcp 2.x,
      # which also trips fastmcp-slim's meta.broken (broken when mcp >= 2).
      # Older locks only have mcp 1.x (no mcp_1 alias), hence the fallback.
      python3Packages =
        (pkgs.python3.override {
          packageOverrides = _final: prev: { mcp = prev.mcp_1 or prev.mcp; };
        }).pkgs;

      markdown-to-confluence = python3Packages.buildPythonPackage rec {
        pname = "markdown-to-confluence";
        version = "0.6.5";
        format = "wheel";

        src = pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/b0/9a/fd541e53e8d15ad68edc5ade102772ad58f033b4ac67ccf1e2d1daaf5c8a/markdown_to_confluence-0.6.5-py3-none-any.whl";
          sha256 = "sha256-dbfFV635TP9IkPPFupdt5ju+H0WXhwiMMIjqJ6OiUBg=";
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
      version = "0.23.1";
      pyproject = true;

      src = pkgs.fetchFromGitHub {
        owner = "sooperset";
        repo = "mcp-atlassian";
        rev = "v${version}";
        sha256 = "sha256-zbBsEBEfSvsS7dTbbvx2HG2GQhxGtvwVpYf4JPZVCKw=";
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
    };
}
