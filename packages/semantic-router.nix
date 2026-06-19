{ lib, pkgs, ... }:
let
  version = "0.3.0";
  src = pkgs.fetchFromGitHub {
    owner = "vllm-project";
    repo = "semantic-router";
    rev = "f08056e793434ad5ccec8054fe34d43baff52fdd";
    hash = "sha256-rJJUmpRcnFrjuYT4OQf7HVl01MIYogRPNKouMYbnF6c=";
  };

  mlBinding = pkgs.rustPlatform.buildRustPackage {
    pname = "ml-semantic-router";
    version = "0.1.0";

    inherit src;

    sourceRoot = "source/ml-binding";

    cargoLock.lockFile = "${src}/ml-binding/Cargo.lock";

    doCheck = false;

    installPhase = ''
      runHook preInstall
      libPath=$(find target -name 'libml_semantic_router.so' -print -quit)
      install -Dm644 "$libPath" $out/lib/libml_semantic_router.so
      runHook postInstall
    '';

    meta = {
      description = "Traditional ML native library for vLLM semantic router";
      homepage = "https://github.com/vllm-project/semantic-router";
      license = lib.licenses.asl20;
      platforms = lib.platforms.linux;
    };
  };

  nlpBinding = pkgs.rustPlatform.buildRustPackage {
    pname = "nlp-binding";
    version = "0.1.0";

    inherit src;

    sourceRoot = "source/nlp-binding";

    cargoLock.lockFile = "${src}/nlp-binding/Cargo.lock";

    doCheck = false;

    installPhase = ''
      runHook preInstall
      libPath=$(find target -name 'libnlp_binding.so' -print -quit)
      install -Dm644 "$libPath" $out/lib/libnlp_binding.so
      runHook postInstall
    '';

    meta = {
      description = "NLP native library for vLLM semantic router";
      homepage = "https://github.com/vllm-project/semantic-router";
      license = lib.licenses.asl20;
      platforms = lib.platforms.linux;
    };
  };

  candleBinding = pkgs.rustPlatform.buildRustPackage {
    pname = "candle-semantic-router";
    version = "0.3.0";

    inherit src;

    sourceRoot = "source/candle-binding";

    cargoLock = {
      lockFile = "${src}/candle-binding/Cargo.lock";
      outputHashes = {
        "candle-core-0.9.2-alpha.1" = "sha256-kr7VJlDimjf6Th8LIyiz8ZN/c3vCH1wlAB+mCP2BYxI=";
        "candle-flash-attn-0.9.2-alpha.1" = "sha256-kr7VJlDimjf6Th8LIyiz8ZN/c3vCH1wlAB+mCP2BYxI=";
        "candle-nn-0.9.2-alpha.1" = "sha256-kr7VJlDimjf6Th8LIyiz8ZN/c3vCH1wlAB+mCP2BYxI=";
        "candle-transformers-0.9.2-alpha.1" = "sha256-kr7VJlDimjf6Th8LIyiz8ZN/c3vCH1wlAB+mCP2BYxI=";
      };
    };

    cargoBuildFlags = [ "--no-default-features" ];
    cargoCheckFlags = [ "--no-default-features" ];

    doCheck = false;

    installPhase = ''
      runHook preInstall
      libPath=$(find target -name 'libcandle_semantic_router.so' -print -quit)
      install -Dm644 "$libPath" $out/lib/libcandle_semantic_router.so
      runHook postInstall
    '';

    meta = {
      description = "Candle native library for vLLM semantic router";
      homepage = "https://github.com/vllm-project/semantic-router";
      license = lib.licenses.asl20;
      platforms = lib.platforms.linux;
    };
  };
in
pkgs.buildGoModule {
  pname = "semantic-router";
  inherit version;

  inherit src;

  sourceRoot = "source/src/semantic-router";

  vendorHash = "sha256-Y0GiiU/pDa/ySONUJcgxiJnH3WPVJyS+OK28jxljjVg=";

  subPackages = [ "cmd" ];

  preBuild = ''
    substituteInPlace vendor/github.com/vllm-project/semantic-router/candle-binding/semantic-router.go \
      --replace-fail '#cgo LDFLAGS: -L''${SRCDIR}/target/release -lcandle_semantic_router -ldl -lm' '#cgo LDFLAGS: -L${candleBinding}/lib -lcandle_semantic_router -ldl -lm'
    substituteInPlace vendor/github.com/vllm-project/semantic-router/nlp-binding/nlp_binding.go \
      --replace-fail '#cgo LDFLAGS: -L''${SRCDIR}/target/release -lnlp_binding -ldl -lm -lpthread' '#cgo LDFLAGS: -L${nlpBinding}/lib -lnlp_binding -ldl -lm -lpthread'
    substituteInPlace vendor/github.com/vllm-project/semantic-router/ml-binding/ml_binding.go \
      --replace-fail '#cgo LDFLAGS: -L''${SRCDIR}/target/release -lml_semantic_router -lm -ldl -lpthread' '#cgo LDFLAGS: -L${mlBinding}/lib -lml_semantic_router -lm -ldl -lpthread'
  '';

  postPatch = ''
    substituteInPlace pkg/classification/unified_classifier_cgo_candle.go \
      --replace-fail '-L../../../../../candle-binding/target/release' '-L${candleBinding}/lib'
    substituteInPlace ../../candle-binding/semantic-router.go \
      --replace-fail '-L''${SRCDIR}/target/release' '-L${candleBinding}/lib'
    substituteInPlace ../../nlp-binding/nlp_binding.go \
      --replace-fail '-L''${SRCDIR}/target/release' '-L${nlpBinding}/lib'
    substituteInPlace ../../ml-binding/ml_binding.go \
      --replace-fail '-L''${SRCDIR}/target/release' '-L${mlBinding}/lib'
  '';

  ldflags = [ "-extldflags=-Wl,--allow-multiple-definition" ];

  postInstall = ''
    if [ -e "$out/bin/cmd" ]; then
      mv "$out/bin/cmd" "$out/bin/semantic-router"
    fi
  '';

  doCheck = false;

  meta = {
    description = "vLLM semantic router";
    homepage = "https://github.com/vllm-project/semantic-router";
    mainProgram = "semantic-router";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
