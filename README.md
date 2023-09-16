## Manual Steps

### Install 1Password

```

```

### Add Streamdeck into the system (Ubuntu)
```
sudo apt-get install libhidapi-libusb0
sudo sh -c 'echo "SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"0fd9\", TAG+=\"uaccess\"" > /etc/udev/rules.d/70-streamdeck.rules'
sudo udevadm trigger
```

