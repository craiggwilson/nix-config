{
  lib,
  inputs,
  pkgs,
  stdenv,
  ...
}:

pkgs.buildGoModule rec {
  name = "songtool";

  src = pkgs.fetchFromGitHub {
    owner = "craiggwilson";
    repo = "songtool";
    rev = "master";
    sha256 = "sha256-vWMRc6x/IlDcaGN5jkXHbieMY2ncfdh9MjwYaUw115M=";
  };

  vendorHash = "sha256-ZiMbTWPK14IDTqs/re9U1ZwIAhqIw1VP+54Vaioga+A=";

  meta = {
    mainProgram = "songtool";
    description = "SongTool - a tool for viewing chords and lyrics";
    homepage = "https://github.com/craiggwilson/songtool";
  };
}
