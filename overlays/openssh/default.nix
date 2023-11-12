{ channels, ... }:
final: prev: {
  openssh = prev.openssh.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./openssh.patch ];
    doCheck = false;
  });
}