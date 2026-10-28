{
  substrate.packages.laya =
    { lib, pkgs, ... }:
    let
      inherit (pkgs) python3Packages;
    in
    python3Packages.buildPythonPackage rec {
      pname = "laya";
      # laya-mcp currently requires laya < 0.4.
      version = "0.3.29";
      pyproject = true;

      src = pkgs.fetchPypi {
        inherit pname version;
        hash = "sha256-ejxkFjvhlci6bKZcnPartDnePXDYkJAPgPPQ6SPm0LQ=";
      };

      build-system = with python3Packages; [
        setuptools
        wheel
      ];

      dependencies = with python3Packages; [
        torch
        transformers
        safetensors
        huggingface-hub
        numpy
      ];

      # Tests require model weights from the HuggingFace Hub.
      doCheck = false;

      meta = {
        description = "Open-source non-autoregressive System 1 decision model (typed choice/score/noul answers)";
        homepage = "https://huggingface.co/convaiinnovations/laya";
        license = lib.licenses.asl20;
        mainProgram = "laya";
      };
    };
}
