{ pkgs, ... }: {
    home.file.".ssh/id_rsa.pub".source = ./config/id_rsa.pub;

    programs.ssh.enable = true;
}
