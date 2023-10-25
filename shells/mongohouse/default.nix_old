{ mkShell, lib, pkgs, ...}:
mkShell {
    name = "mongohouse";
    
    buildInputs = with pkgs; [
    ];

    inputsFrom = with pkgs; [
        stdenv.cc.cc
    ];

    NIX_LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [
        stdenv.cc.cc
        curl
        libkrb5
        openssl
        xz
    ];

    NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";

    shellHook = ''
        echo "Welcome to the mongohouse dev shell!"
    '';
}
