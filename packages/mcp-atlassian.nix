{ lib, pkgs, ... }:
let
  python3Packages = pkgs.python3Packages;

  jsonschema-path = python3Packages.buildPythonPackage rec {
    pname = "jsonschema-path";
    version = "0.5.0";
    format = "wheel";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/04/2c/9e69d73c4297508be9e3b64a970ea3971b3eb8db64ffc5802d40bd25981f/jsonschema_path-0.5.0-py3-none-any.whl";
      sha256 = "sha256-J5CgcLx6uwjqPb5NNA7OTvrfY5IjAB8CDHUDIpugaOI=";
    };

    dependencies = [
      python3Packages.pyyaml
      python3Packages.attrs
      python3Packages.pathable
      python3Packages.referencing
    ];

    doCheck = false;
    dontCheckRuntimeDeps = true;

    meta = with lib; {
      description = "JSONSchema spec paths";
      homepage = "https://github.com/p1c2u/jsonschema-path";
      license = licenses.asl20;
      platforms = platforms.all;
    };
  };

  openapi-pydantic = python3Packages.buildPythonPackage rec {
    pname = "openapi-pydantic";
    version = "0.5.1";
    format = "wheel";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/12/cf/03675d8bd8ecbf4445504d8071adab19f5f993676795708e36402ab38263/openapi_pydantic-0.5.1-py3-none-any.whl";
      sha256 = "sha256-o6Ce9FhvW9dgqN9/QwKLYMr7bZ9h3irLqVdHZiVasUY=";
    };

    dependencies = [
      python3Packages.pydantic
    ];

    doCheck = false;
    dontCheckRuntimeDeps = true;

    meta = with lib; {
      description = "OpenAPI pydantic models";
      homepage = "https://github.com/mike-oakley/openapi-pydantic";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };

  # py-key-value-aio is not a top-level nixpkgs attribute but is a transitive dep of pydocket.
  # Reuse it from there to avoid duplicate derivations in the closure.
  py-key-value-aio = lib.findFirst (p: p.pname == "py-key-value-aio") null python3Packages.pydocket.propagatedBuildInputs;

  fastmcp = python3Packages.buildPythonPackage rec {
    pname = "fastmcp";
    version = "2.14.7";
    format = "wheel";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/a6/f1/56310847b0bdd5b14c2af8f0a39082af078deff60d0dc43efef4e366a83e/fastmcp-2.14.7-py3-none-any.whl";
      sha256 = "sha256-4IGlIiptMCoUiHHYn9cUsTEwzuZZT1Oj4a/XUY8AlsA=";
    };

    dependencies = [
      python3Packages.authlib
      python3Packages.cyclopts
      python3Packages.exceptiongroup
      python3Packages.fakeredis
      python3Packages.httpx
      jsonschema-path
      python3Packages.jsonref
      python3Packages.mcp
      openapi-pydantic
      python3Packages.packaging
      python3Packages.platformdirs
      py-key-value-aio
      python3Packages.pydantic
      python3Packages.pydocket
      python3Packages.pyperclip
      python3Packages.python-dotenv
      python3Packages.rich
      python3Packages.starlette
      python3Packages.uvicorn
      python3Packages.websockets
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
