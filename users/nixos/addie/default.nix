{ inputs, config, lib, pkgs, ... }: 
let 
  username = "addie";
in {
  nix.settings = {
    trusted-users = [ username ];
    allowed-users = [ username ];
  };

  users.users.${username} = {
    isNormalUser = true;

    name = username;
    home = "/home/${username}";
    group = "users";
    initialPassword = "password";

    extraGroups = [
        "wheel"
    ] ++ (lib.optionals config.hdwlinux.features._1password-cli.enable [
        "1password-cli"
    ]) ++ (lib.optionals config.hdwlinux.features.audio.enable [
        "audio"
    ]) ++ (lib.optionals config.hdwlinux.features.virtualization.docker.enable [
        "docker"
    ]) ++ (lib.optionals config.hdwlinux.features.networking.enable [
        "networkmanager"
    ]) ++ (lib.optionals config.hdwlinux.features.scanning.enable [
        "scanner"
        "lp"
    ]);
  };

  programs._1password-gui.polkitPolicyOwners = lib.mkIf config.hdwlinux.features._1password-gui.enable [
    username
  ];
}
