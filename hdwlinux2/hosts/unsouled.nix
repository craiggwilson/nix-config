{
  config,
  ...
}:
{
  hosts.unsouled = {
    system = "x86_64-linux";
    users = [ "craig" ];
    modules = with config.flake.modules.nixos; [
      base
    ];
  };
}
