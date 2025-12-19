{
  config.substrate.modules.security.pam = {
    nixos = {
      security.pam.services.hyprlock.text = ''
        auth sufficient pam_unix.so try_first_pass likeauth nullok
        auth sufficient pam_fprintd.so
        auth include login
      '';
    };
  };
}

