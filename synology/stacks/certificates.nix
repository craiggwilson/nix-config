_: {
  compose.services = { };

  lifecycle = false;

  directories = [ "secrets" ];

  files = {
    "issue-global.sh" = builtins.readFile ./certificates/files/issue-global.sh;
    "renew.sh" = builtins.readFile ./certificates/files/renew.sh;
  };

  commands.download =
    { pkgs, ... }:
    pkgs.writeShellApplication {
      name = "synology-certificates-download";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.openssh
      ];
      text = ''
        host="''${1:-synology}"
        outputDirectory="''${2:-$HOME/Downloads/unifi-cert-upload}"
        remoteDirectory="/tmp/unifi-cert-upload-$USER-$$"

        mkdir -p "$outputDirectory"
        chmod 700 "$outputDirectory"

        cleanup() {
          ssh -tt "$host" "sudo rm -rf '$remoteDirectory'" >/dev/null 2>&1 || true
        }
        trap cleanup EXIT

        ssh -tt "$host" "
          set -eu
          certificateDirectory=\$(sudo find /usr/local/share/acme.sh \\
            -maxdepth 1 -type d -name '*.wilsonfamilyhq.com_ecc' \\
            -print -quit)
          keyFile=\$(sudo find \"\$certificateDirectory\" \\
            -maxdepth 1 -type f -name '*.wilsonfamilyhq.com.key' \\
            -print -quit)
          test -n \"\$certificateDirectory\"
          test -n \"\$keyFile\"
          sudo install -d -o craiggwilson -g users -m 700 '$remoteDirectory'
          sudo install -o craiggwilson -g users -m 600 \\
            \"\$certificateDirectory/fullchain.cer\" \\
            '$remoteDirectory/fullchain.cer'
          sudo install -o craiggwilson -g users -m 600 \\
            \"\$keyFile\" '$remoteDirectory/controller.key'
        "

        scp -O "$host:$remoteDirectory/fullchain.cer" "$outputDirectory/fullchain.cer"
        scp -O "$host:$remoteDirectory/controller.key" "$outputDirectory/controller.key"
        chmod 600 "$outputDirectory/fullchain.cer" "$outputDirectory/controller.key"

        echo "Certificate bundle: $outputDirectory/fullchain.cer"
        echo "Private key:       $outputDirectory/controller.key"
      '';
    };

  secrets = {
    "secrets/namecheap_api_key" = "ACME_NAMECHEAP_API_KEY";
    "secrets/namecheap_source_ip" = "ACME_NAMECHEAP_SOURCE_IP";
    "secrets/namecheap_username" = "ACME_NAMECHEAP_USERNAME";
  };
}
