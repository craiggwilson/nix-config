## Getting Started

### Install Git

```
nix-env -iA nixos.git
```

### Clone Nix Config

```
git clone https://github.com/craiggwilson/nix-config

```

### Partitioning
```
sudo nix --extra-experimental-features nix-commands --extra-experimental-features flakes run github:nix-community/disko -- --mode disko --flake github:craiggwilson/nix-config#playground
```

### Install NixOS

```
nix-shell -p git

git clone https://github.com/craiggwilson/nix-config /tmp/nix-config

sudo nixos-install --impure --flake /tmp/nix-config#playground
```

## After Install

```
mkdir -p ~/Projects/github.com/craiggwilson
cd ~/Projects/github.com/craiggwilson
git submodule update --init --recursive
nix-config-switch
```

### Rebuild and Switch

```
sudo nixos-rebuild switch --flake .#playground
```

### Offload Steam to NVIDIA

```
mkdir -p ~/.local/share/applications
sed 's/^Exec=/&nvidia-offload /' /etc/profiles/per-user/craig/share/applications/steam.desktop > ~/.local/share/applications/steam.desktop
```

## Manual Steps

### Setup Onedrive

```
onedrive --resync
```

### Add Streamdeck into the system (Ubuntu)
```
sudo apt-get install libhidapi-libusb0
sudo sh -c 'echo "SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"0fd9\", TAG+=\"uaccess\"" > /etc/udev/rules.d/70-streamdeck.rules'
sudo udevadm trigger
```

