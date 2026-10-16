{
  # The location marker: only this node provides location:raeford; the
  # location's other modules provide their domain identity and require the
  # location context. Location-common system configuration lives here.
  config.substrate.modules.locations.raeford = {
    provides = [ "location:raeford" ];

    # Context caps are only ever required (never swept), so a single tag is
    # enough under the tags finder too.
    tags = [ "raeford" ];

    nixos = {
      time.timeZone = "America/Chicago";
    };
  };
}
