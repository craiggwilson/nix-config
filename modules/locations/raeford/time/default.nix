{
  config.substrate.modules.locations.raeford.time = {
    tags = [
      "location:raeford"
    ];
    nixos = {
      time.timeZone = "America/Chicago";
    };
  };
}
