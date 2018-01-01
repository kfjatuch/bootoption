#  bootoption

A program to create and save an EFI boot load option - so that it might be added to the firmware menu later. May be used to work around situations where it is problematic to modify BootOrder, BootXXXX in NVRAM, while targeting a given instance of a loader from the booted OS: during loader installation, for example.

## Usage

```
bootoption -p path -d description -o file
    -p path to EFI executable
    -d boot option description
    -o file to write to (XML property list)
```

### Sample usage

```
bootoption -p /Volumes/EFI/EFI/CLOVER/CLOVERX64.EFI -d Clover -o /Volumes/EFI/boot.plist
```
The command above creates /Volumes/EFI/boot.plist with the following contents:

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Boot</key>
    <data>
    AQAAAGYAQwBsAG8AdgBlAHIAAAAEASoAAQAAAAAIAA
    AAAAAAAEAGAAAAAADVqM8+f4xeSKkOqRfx+n2lAgIE
    BDgAXABFAEYASQBcAEMATABPAFYARQBSAFwAQwBMAE
    8AVgBFAFIAWAA2ADQALgBFAEYASQAAAH//BAA=
    </data>
</dict>
</plist>
```

The data element contains the base 64 encoded variable data conforming to the EFI_LOAD_OPTION structure, as defined in section 3.1.3 of the UEFI Specification 2.7.

## mkbootoption.sh

Somewhat experimental, potentially dangerous shell script that will attempt to add a boot option to EFI using Apple's nvram command. Requires bootoption and nvrambytes (factory defaults: the binaries should be located in the same directory as the script). Usage:

```
./mkbootoption.sh "path" "description"
     required parameters:
     path                        path to EFI executable
     description                 name for boot menu entry
```

## License

GPL version 3
