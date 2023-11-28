{ mkShell, pkgs, ... }:
let 
  ps = pkgs.python311Packages; 
in mkShell rec { 
  name = "myenv"; 
  venvDir = "./.venv"; 
  buildInputs = [
    # A Python interpreter including the 'venv' module is required to bootstrap the environment. 
    ps.python
    # This execute some shell code to initialize a venv in $venvDir before
    # dropping into the shell
    ps.venvShellHook
  ];

  postVenvCreation = '' 
    unset SOURCE_DATE_EPOCH 
  '';
  postShellHook = '' 
    # allow pip to install wheels 
    unset SOURCE_DATE_EPOCH 
  ''; 
}