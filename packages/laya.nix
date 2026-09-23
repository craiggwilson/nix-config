{ lib, pkgs, ... }:
let
  inherit (pkgs) python3Packages;
in
python3Packages.buildPythonPackage rec {
  pname = "laya";
  version = "0.3.11";
  pyproject = true;

  src = pkgs.fetchPypi {
    inherit pname version;
    hash = "sha256-9ITv6zOaOfaP5ExlCUeqkCOL+4TZ7FRQsVe1H7L6B5Q=";
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
}
