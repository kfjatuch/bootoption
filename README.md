#  bootoption

A command line program that generates EFI boot load options. Outputs variable data as an XML property list, or as a formatted string for use with Apple's nvram system command. The generated property list be used to work around situations where it is problematic to modify BootOrder, BootXXXX etc. in hardware NVRAM, while targeting a given instance of a loader from the booted OS, during loader installation, for example.

## Usage

```
bootoption -p path -d description [-o file]
    -p path to an EFI executable
    -d description for the boot option
    -o output to file (XML property list)
```

### Example 1

```
bootoption -p "/Volumes/EFI/EFI/CLOVER/CLOVERX64.EFI" -d "Clover" -o "/Volumes/EFI/boot.plist"
```
/Volumes/EFI/boot.plist:

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>Boot</key>
        <data>
        AQAAAGYAQwBsAG8AdgBlAHIAAAAEASoAAQAAAAAIAAAAAAAAAEAGAAAAAADVqM8+f4xe
        SKkOqRfx+n2lAgIEBDgAXABFAEYASQBcAEMATABPAFYARQBSAFwAQwBMAE8AVgBFAFIA
        WAA2ADQALgBFAEYASQAAAH//BAA=
        </data>
</dict>
</plist>
```

The data element contains the base 64 encoded variable data conforming to the EFI_LOAD_OPTION structure, as defined in section 3.1.3 of the UEFI Specification 2.7.

### Example 2

```
bootoption -p "/Volumes/EFI/EFI/CLOVER/CLOVERX64.EFI" -d "Clover"
```

Output:

```
%01%00%00%00%66%00%43%00%6c%00%6f%00%76%00%65%00%72%00%00%00%04%01%2a%00%01%00%00%00%00%08%00%00%00%00%00%00%00%40%06%00%00%00%00%00%d5%a8%cf%3e%7f%8c%5e%48%a9%0e%a9%17%f1%fa%7d%a5%02%02%04%04%38%00%5c%00%45%00%46%00%49%00%5c%00%43%00%4c%00%4f%00%56%00%45%00%52%00%5c%00%43%00%4c%00%4f%00%56%00%45%00%52%00%58%00%36%00%34%00%2e%00%45%00%46%00%49%00%00%00%7f%ff%04%00
```

## mkbootoption.sh

An experimental and potentially dangerous shell script that will attempt to add a boot option to EFI using Apple's nvram command. Usage:

```
sudo ./mkbootoption.sh "path" "description"
     required parameters:
     path                  path to an EFI executable
     description           description for the new boot menu entry
```

## License

GPL version 3
