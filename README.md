#  bootoption

![bootoption screenshot](https://github.com/vulgo/bootoption/raw/master/Images/screenshot.png "bootoption screenshot")

A command line utility for managing a firmware's boot menu. Report bugs [here](https://github.com/vulgo/bootoption/issues).

## Usage

bootoption <strong>VERB</strong> [options] where <strong>VERB</strong> is one from the following:

- <strong>LIST</strong>&nbsp;&nbsp;show the firmware boot menu
- <strong>INFO</strong>&nbsp;&nbsp;show an option's properties
- <strong>SET</strong>&nbsp;&nbsp;set/modify variables in NVRAM
- <strong>CREATE</strong>&nbsp;&nbsp;create a new boot option
- <strong>ORDER</strong>&nbsp;&nbsp;re-arrange the boot order
- <strong>DELETE</strong>&nbsp;&nbsp;delete variables from NVRAM
- <strong>SAVE</strong>&nbsp;&nbsp;print or save boot variable data in different formats

bootoption <strong>VERB</strong> without options will show the usage or options for that verb, where available


### Create a new boot option in NVRAM and add it to the boot order

```
sudo bootoption create -l "/Volumes/EFI/shell.efi" -L "EFI Shell"
```

Making changes to the boot menu requires sudo and working hardware NVRAM - for instance, emulated NVRAM will not work.

### Save

Supported output modes:

- raw hex
- XML
- [EDK2 dmpstore](https://github.com/tianocore/edk2/blob/master/ShellPkg/Library/UefiShellDebug1CommandsLib/DmpStore.c) format
- string formatted for [Apple's nvram system command](https://opensource.apple.com/source/system_cmds/system_cmds-790/nvram.tproj/nvram.c.auto.html)

A stored representation of the variable data can be used to work around situations where it is problematic to modify BootOrder, BootXXXX etc. in hardware NVRAM, while targeting a specific device path from inside the operating system (for instance, generated during loader installation, stored and then added from an EFI context - see also [Punchdrum](https://github.com/vulgo/Punchdrum)).

bootoption save -l <em>PATH</em> -L <em>LABEL</em> [ -u <em>STRING</em> ] [ -o <em>FILE</em> | -a | -x [ -k <em>KEY</em> ] ]

#### Store to XML property list

```
bootoption save -l "/Volumes/EFI/EFI/CLOVER/CLOVERX64.EFI" -L "Clover" -x -k "Payload" > /Volumes/EFI/boot.plist
```
#### /Volumes/EFI/boot.plist

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>Payload</key>
        <data>
        AQAAAGYAQwBsAG8AdgBlAHIAAAAEASoAAQAAAAAIAAAAAAAAAEAGAAAAAADVqM8+f4xe
        SKkOqRfx+n2lAgIEBDgAXABFAEYASQBcAEMATABPAFYARQBSAFwAQwBMAE8AVgBFAFIA
        WAA2ADQALgBFAEYASQAAAH//BAA=
        </data>
</dict>
</plist>
```

The data element contains the base 64 encoded variable data conforming to the EFI_LOAD_OPTION structure, as defined in section 3.1.3 of the UEFI Specification 2.7.

#### Store to EDK2 dmpstore format

```
bootoption save -l "/Volumes/EFI/EFI/CLOVER/CLOVERX64.EFI" -L "Clover" -o "/Volumes/USB-FAT32/vars.dmpstore"
````

The resulting file can be read from the EFI shell. To load and set the variables:

```
FS0:\> dmpstore -l vars.dmpstore
```

## License

GPL version 3
