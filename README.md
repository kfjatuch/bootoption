#  bootoption

A program to create / save an EFI boot option - so that it might be added to the firmware menu later. May be used to work around situations where it is problematic to manipulate the menu in NVRAM, while targeting a given instance of a bootloader from the booted OS e.g. during bootloader installation.

## Usage

```
bootoption -p path -d description -o file
    -p path to EFI executable
    -d boot option description
    -o file to write to (XML property list)
```

Example usage

```
bootoption -p /Volumes/EFI/EFI/CLOVER/CLOVERX64.EFI -d Clover -o /Volumes/EFI/boot.plist
```
Example output

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Boot</key>
    <data>AQAAAGYAQwBsAG8AdgBlAHIAAAAEASoAAQAAAAAIAAAAAAAAAEAGAAAAAADVqM8+f4xeSKkOqRfx+n2lAgIEBDgAXABFAEYASQBcAEMATABPAFYARQBSAFwAQwBMAE8AVgBFAFIAWAA2ADQALgBFAEYASQAAAH//BAA=</data>
</dict>
</plist>
```

## License

GPL version 3
