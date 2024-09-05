# Installing

## NixOS-Anywhere

```
echo -n "<password>" > /tmp/secret.key
nix run github:nix-community/nixos-anywhere -- --flake .#<hostname> --disk-encryption-keys /tmp/secret.key /tmp/secret.key <user>@<ip>
```

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

```
echo -n "<password>" > /tmp/secret.key
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode disko --flake github:craiggwilson/nix-config#<host>
```

### Install NixOS

```
git clone https://github.com/craiggwilson/nix-config /tmp/nix-config

sudo nixos-install --impure --flake /tmp/nix-config#<host>
```

# After Install

## Push private key

```
scp /path/to/key user@ip:/path/to/key
```

## Pull down config flake

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
