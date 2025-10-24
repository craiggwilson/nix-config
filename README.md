# nix-config

A non-flake NixOS configuration using npins for dependency management.

## Structure

```
.
├── default.nix          # Main entry point
├── lib/                 # Top-level utility functions
│   └── default.nix      # Module discovery, overlay/package/shell loaders
├── hdwlinux/            # All hdwlinux-specific configuration
│   ├── homes/           # Home Manager configurations
│   ├── lib/             # Custom library functions (types, themes, etc.)
│   ├── modules/         # NixOS and Home Manager modules
│   ├── overlays/        # Nixpkgs overlays
│   ├── packages/        # Custom packages
│   ├── shells/          # Development shells
│   └── systems/         # NixOS system configurations
└── npins/               # Dependency management
```

## Usage

### Building packages

```bash
nix-build -E '(import ./default.nix).packages.x86_64-linux.<package-name>'
```

### Entering development shells

```bash
nix-shell -E "(import ./default.nix).devShells.x86_64-linux.<shell-name>"
```

### Building NixOS system

```bash
sudo nixos-rebuild switch -I nixos-config=/path/to/nix-config/hdwlinux/systems/x86_64-linux/<host>/default.nix
```

# Installing

## Manual

### Install Git

```
nix-env -iA nixos.git
```

### Clone Nix Config

```
git clone https://github.com/craiggwilson/nix-config

```

### Partitioning

Use disko to partition the disk according to your host configuration.

### Install NixOS

```
git clone https://github.com/craiggwilson/nix-config /tmp/nix-config

sudo nixos-install --impure -I nixos-config=/tmp/nix-config/hdwlinux/systems/x86_64-linux/<host>/default.nix
```

# After Install

## Push private key

```
scp /path/to/key user@ip:/path/to/key
```

## Pull down config

```
mkdir -p ~/Projects/github.com/craiggwilson
cd ~/Projects/github.com/craiggwilson
git clone git@github.com:craiggwilson/nix-config
git clone git@github.com:craiggwilson/nix-private
```

## Firefox

Configure sideberry by enabling a prefix and using `XXX`.

## Setup Onedrive

```
onedrive --synchronize
```

## Fingerprints

```
sudo fprintd-enroll -f right-index-finger
```

### Optional 

## Offload Steam to NVIDIA

```
mkdir -p ~/.local/share/applications
sed 's/^Exec=/&nvidia-offload /' /etc/profiles/per-user/craig/share/applications/steam.desktop > ~/.local/share/applications/steam.desktop
```
## Add Streamdeck into the system (Ubuntu)

```
sudo apt-get install libhidapi-libusb0
sudo sh -c 'echo "SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"0fd9\", TAG+=\"uaccess\"" > /etc/udev/rules.d/70-streamdeck.rules'
sudo udevadm trigger
```
