{ inputs, lib, ... }: {
  # mkOutOfStoreSymlink = path: 
  #   let
  #     pathStr = toString path;
  #     name = inputs.home-manager.lib.hm.strings.storeFileName (baseNameOf pathStr);
  #   in
  #     pkgs.runCommandLocal name {} ''ln -s ${lib.escapeShellArg pathStr} $out'';
}