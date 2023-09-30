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
# If using luks, write out password to /tmp/secret.key
echo -n "<password>" > /tmp/secret.key

sudo nix --extra-experimental-features nix-commands --extra-experimental-features flakes run github:nix-community/disko -- --mode disko --flake github:craiggwilson/nix-config#<host>
```

### Install NixOS

```
nix-shell -p git

git clone https://github.com/craiggwilson/nix-config /tmp/nix-config

sudo nixos-install --impure --flake /tmp/nix-config#<host>
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
nix-config-switch
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
