{
  config.substrate.modules.locations.raeford.time = {
    tags = [
      "raeford"
    ];
    nixos = {
      time.timeZone = "America/Chicago";
    };
  };
}
