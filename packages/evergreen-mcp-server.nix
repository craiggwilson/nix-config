{ lib, pkgs, ... }:
let
  python3Packages = pkgs.python3Packages;

  # Helper packages not in nixpkgs
  uncalled-for = python3Packages.buildPythonPackage rec {
    pname = "uncalled-for";
    version = "0.2.0";
    pyproject = true;

    src = python3Packages.fetchPypi {
      pname = "uncalled_for";
      inherit version;
      sha256 = "sha256-tPj9vOwyjFoROAfWU+BBxQlEc91K+nw0WZrOacy35p8=";
    };

    build-system = [
      python3Packages.hatchling
      python3Packages.hatch-vcs
    ];

    doCheck = false;
    dontCheckRuntimeDeps = true;

    meta = {
      description = "Shared context for Python";
      homepage = "https://pypi.org/project/uncalled-for/";
      license = lib.licenses.mit;
    };
  };

  jsonref = python3Packages.buildPythonPackage rec {
    pname = "jsonref";
    version = "1.1.0";
    format = "wheel";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/0c/ec/e1db9922bceb168197a558a2b8c03a7963f1afe93517ddd3cf99f202f996/jsonref-1.1.0-py3-none-any.whl";
      sha256 = "sha256-WQ3Hdz32why/lItdrAenKiUdsosCOM7szgoqv6jsMKk=";
    };

    doCheck = false;
    dontCheckRuntimeDeps = true;

    meta = {
      description = "JSON Reference resolution";
      homepage = "https://github.com/gazpachoking/jsonref";
      license = lib.licenses.mit;
    };
  };

  pathable = python3Packages.buildPythonPackage rec {
    pname = "pathable";
    version = "0.5.0";
    pyproject = true;

    src = python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-2Bk4NIocrLUl58dRZicGRHgsD7nIzswWvgM+cUJ+DvE=";
    };

    build-system = [ python3Packages.poetry-core ];

    doCheck = false;
    dontCheckRuntimeDeps = true;

    meta = {
      description = "Object-oriented paths";
      homepage = "https://github.com/p1c2u/pathable";
      license = lib.licenses.asl20;
    };
  };

  jsonschema-path = python3Packages.buildPythonPackage rec {
    pname = "jsonschema-path";
    version = "0.4.5";
    pyproject = true;

    src = python3Packages.fetchPypi {
      pname = "jsonschema_path";
      inherit version;
      sha256 = "sha256-xs19V3rikMfe/U9AKehv2ySMob1BoHVXeVs8leUUSRg=";
    };

    build-system = [ python3Packages.poetry-core ];

    dependencies = [
      pathable
      python3Packages.pyyaml
      python3Packages.referencing
    ];

    doCheck = false;
    dontCheckRuntimeDeps = true;

    meta = {
      description = "JSONSchema Spec with object-oriented paths";
      homepage = "https://github.com/p1c2u/jsonschema-path";
      license = lib.licenses.asl20;
    };
  };

  openapi-pydantic = python3Packages.buildPythonPackage rec {
    pname = "openapi-pydantic";
    version = "0.5.1";
    pyproject = true;

    src = python3Packages.fetchPypi {
      pname = "openapi_pydantic";
      inherit version;
      sha256 = "sha256-/2g1r2veekWfuT65O7krh0m3VPxuUbLxWQoZ3DAF7g0=";
    };

    build-system = [ python3Packages.poetry-core ];

    dependencies = [ python3Packages.pydantic ];

    doCheck = false;
    dontCheckRuntimeDeps = true;

    meta = {
      description = "Pydantic models for OpenAPI";
      homepage = "https://github.com/mike-oakley/openapi-pydantic";
      license = lib.licenses.mit;
    };
  };

  py-key-value-aio = python3Packages.buildPythonPackage rec {
    pname = "py-key-value-aio";
    version = "0.4.4";
    format = "wheel";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/32/69/f1b537ee70b7def42d63124a539ed3026a11a3ffc3086947a1ca6e861868/py_key_value_aio-0.4.4-py3-none-any.whl";
      sha256 = "sha256-GOF1ZOyuYbmH+Qn8LNQe4gEshLSx3LjAVc+LS8G/P10=";
    };

    dependencies = [
      python3Packages.beartype
      python3Packages.cachetools
      python3Packages.typing-extensions
    ];

    doCheck = false;
    dontCheckRuntimeDeps = true;

    meta = {
      description = "Async key-value store abstraction";
      homepage = "https://pypi.org/project/py-key-value-aio/";
      license = lib.licenses.mit;
    };
  };

  fastmcp = python3Packages.buildPythonPackage rec {
    pname = "fastmcp";
    version = "3.2.4";
    pyproject = true;

    src = python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-CD7LdbRKQWnn/A9jL5S3gb2w/4d8azW5h3y7Vm/U1NE=";
    };

    build-system = [
      python3Packages.hatchling
      python3Packages.uv-dynamic-versioning
    ];

    dependencies = [
      jsonref
      jsonschema-path
      openapi-pydantic
      py-key-value-aio
      uncalled-for
      python3Packages.authlib
      python3Packages.cyclopts
      python3Packages.exceptiongroup
      python3Packages.httpx
      python3Packages.mcp
      python3Packages.opentelemetry-api
      python3Packages.packaging
      python3Packages.platformdirs
      python3Packages.pydantic
      python3Packages.pyperclip
      python3Packages.python-dotenv
      python3Packages.pyyaml
      python3Packages.rich
      python3Packages.uvicorn
      python3Packages.watchfiles
      python3Packages.websockets
    ];

    doCheck = false;
    dontCheckRuntimeDeps = true;

    meta = {
      description = "FastMCP - A fast, simple framework for building MCP servers";
      homepage = "https://github.com/jlowin/fastmcp";
      license = lib.licenses.mit;
    };
  };

  aiohttp-retry = python3Packages.buildPythonPackage rec {
    pname = "aiohttp-retry";
    version = "2.9.1";
    pyproject = true;

    src = python3Packages.fetchPypi {
      pname = "aiohttp_retry";
      inherit version;
      sha256 = "sha256-jrdekE7U7lwuwkL+/oW/BCQPaFORxIedj1QdYCj/AfE=";
    };

    build-system = [
      python3Packages.setuptools
      python3Packages.wheel
    ];

    dependencies = [ python3Packages.aiohttp ];

    doCheck = false;
    dontCheckRuntimeDeps = true;

    meta = {
      description = "Retry client for aiohttp";
      homepage = "https://github.com/inyutin/aiohttp_retry";
      license = lib.licenses.mit;
    };
  };
in
python3Packages.buildPythonApplication rec {
  pname = "evergreen-mcp-server";
  version = "0.4.2";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "evergreen-ci";
    repo = "evergreen-mcp-server";
    rev = "06048872ae97e6bd70dd69b42e35e2dc88aa6d4e";
    sha256 = "sha256-6WygZHdiUucvZKRx3d0Hqhz09Sb4rpY76R6j2WNC8PQ=";
  };

  build-system = [
    python3Packages.setuptools
    python3Packages.wheel
  ];

  dependencies = [
    aiohttp-retry
    fastmcp
    python3Packages.aiohttp
    python3Packages.authlib
    python3Packages.cryptography
    python3Packages.filelock
    python3Packages.gql
    python3Packages.httpx
    python3Packages.mcp
    python3Packages.pydantic
    python3Packages.pyjwt
    python3Packages.python-dateutil
    python3Packages.pyyaml
    python3Packages.sentry-sdk
    python3Packages.typing-extensions
    python3Packages.urllib3
  ];

  doCheck = false;
  dontCheckRuntimeDeps = true;

  meta = {
    mainProgram = pname;
    description = "MCP server for interacting with the Evergreen CI API";
    homepage = "https://github.com/evergreen-ci/evergreen-mcp-server";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
  };
}
