{ pkgs, ... }: {
    home.packages = with pkgs; [
        awscli2
    ];

    home.file.".aws/export-sso-creds.go".source = ./config/export-sso-creds.go;
}
