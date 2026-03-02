# Nix Derivations

## stdenv.mkDerivation

```nix
{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "hello";
  version = "2.12";

  src = fetchurl {
    url = "https://ftp.gnu.org/gnu/hello/hello-${version}.tar.gz";
    sha256 = "sha256-...";
  };

  buildInputs = [ ];
  nativeBuildInputs = [ ];

  configureFlags = [ "--prefix=${placeholder "out"}" ];

  meta = with lib; {
    description = "A program that produces a familiar greeting";
    homepage = "https://www.gnu.org/software/hello/";
    license = licenses.gpl3Plus;
    maintainers = [ maintainers.example ];
    platforms = platforms.all;
  };
}
```

## Build Phases

```nix
stdenv.mkDerivation {
  # ...
  
  # Phases in order:
  # unpackPhase, patchPhase, configurePhase, 
  # buildPhase, checkPhase, installPhase, fixupPhase
  
  configurePhase = ''
    ./configure --prefix=$out
  '';
  
  buildPhase = ''
    make -j$NIX_BUILD_CORES
  '';
  
  installPhase = ''
    mkdir -p $out/bin
    cp myapp $out/bin/
  '';
  
  # Skip a phase
  dontConfigure = true;
}
```

## Fetchers

```nix
# URL
src = fetchurl {
  url = "https://example.com/file.tar.gz";
  sha256 = "sha256-...";
};

# GitHub
src = fetchFromGitHub {
  owner = "owner";
  repo = "repo";
  rev = "v1.0.0";
  sha256 = "sha256-...";
};

# Git
src = fetchgit {
  url = "https://github.com/owner/repo.git";
  rev = "abc123";
  sha256 = "sha256-...";
};
```

## Language-Specific Builders

```nix
# Go
buildGoModule {
  pname = "myapp";
  version = "1.0.0";
  src = ./.;
  vendorHash = "sha256-...";
}

# Python
python3Packages.buildPythonApplication {
  pname = "myapp";
  version = "1.0.0";
  src = ./.;
  propagatedBuildInputs = [ python3Packages.requests ];
}

# Rust
rustPlatform.buildRustPackage {
  pname = "myapp";
  version = "1.0.0";
  src = ./.;
  cargoHash = "sha256-...";
}
```

## Debugging

```bash
# Build with verbose output
nix-build -K  # Keep build directory on failure

# Enter build environment
nix-shell '<nixpkgs>' -A hello

# Run specific phase
genericBuild
unpackPhase
configurePhase
buildPhase
```
