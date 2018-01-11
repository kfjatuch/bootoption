#  bootoption

A command line utility for managing a firmware's boot menu.

## Usage

bootoption <strong>VERB</strong> [options] where <strong>VERB</strong> is one from the following:

- <strong>LIST</strong>&nbsp;&nbsp;print the current entries from the firmware boot menu
- <strong>SET</strong>&nbsp;&nbsp;set EFI variables in NVRAM
- <strong>MAKE</strong>&nbsp;&nbsp;print or save boot variable data in different formats
- <strong>DELETE</strong>&nbsp;&nbsp;remove an entry from the firmware boot menu

### Set

bootoption set &nbsp;[ -l <em>PATH</em> -L <em>LABEL</em> [ -u <em>STRING</em> ] ] &nbsp;[ -t <em>SECONDS</em> ]

<table>
        <tr>
                        <td style="width: 3em">-l</td>
                        <td style="width: 8.5em">--loader</td>
                        <td>the <em>PATH</em> to an EFI loader executable</td>
        </tr>
        <tr>
                        <td>-L</td>
                        <td>--label</td>
                        <td>display <em>LABEL</em> in firmware boot manager</td>
        </tr>
        <tr>
                        <td>-u</td>
                        <td>--unicode</td>
                        <td>an optional <em>STRING</em> passed to the loader command line</td>
        </tr>
        <tr>
                        <td>-t</td>
                        <td>--timeout</td>
                        <td>set the boot menu timeout in <em>SECONDS</em></td>
        </tr>
</table>

#### Set a new boot option in NVRAM and add it to the boot order

```
sudo bootoption set -l "/Volumes/EFI/shell.efi" -L "EFI Shell"
```

Set requires working hardware NVRAM - for instance, emulated NVRAM will not work.

### Make

Supported output modes:

- raw hex
- XML
- [EDK2 dmpstore](https://github.com/tianocore/edk2/blob/master/ShellPkg/Library/UefiShellDebug1CommandsLib/DmpStore.c) format
- string formatted for [Apple's nvram system command](https://opensource.apple.com/source/system_cmds/system_cmds-790/nvram.tproj/nvram.c.auto.html)

A stored representation of the variable data can be used to work around situations where it is problematic to modify BootOrder, BootXXXX etc. in hardware NVRAM, while targeting a specific device path from inside the operating system (for instance, generated during loader installation, stored and then added from an EFI context - see also [Punchdrum](https://github.com/vulgo/Punchdrum)).

bootoption make -l <em>PATH</em> -L <em>LABEL</em> [ -u <em>STRING</em> ] [ -o <em>FILE</em> | -a | -x [ -k <em>KEY</em> ] ]

<table>
        <tr>
                <td style="width: 3em">-l</td>
                <td style="width: 8.5em">--loader</td>
                <td>the <em>PATH</em> to an EFI loader executable</td>
        </tr>
        <tr>
                <td>-L</td>
                <td>--label</td>
                <td>display <em>LABEL</em> in firmware boot manager</td>
        </tr>
        <tr>
                <td>-u</td>
                <td>--unicode</td>
                <td>an optional <em>STRING</em> passed to the loader command line</td>
        </tr>
        <tr>
                <td>-o</td>
                <td>--output</td>
                <td>write to <em>FILE</em> for use with EDK2 dmpstore</td>
        </tr>
        <tr>
                <td>-a</td>
                <td>--apple</td>
                <td>print Apple nvram-style string instead of raw hex</td>
        </tr>
        <tr>
                <td>-x</td>
                <td>--xml</td>
                <td>print an XML serialization instead of raw hex</td>
        </tr>
        <tr>
                <td>-k</td>
                <td>--key</td>
                <td>specify named <em>KEY</em>, for use with option -x</td>
        </tr>
</table>


#### Store to XML property list

```
bootoption make -l "/Volumes/EFI/EFI/CLOVER/CLOVERX64.EFI" -L "Clover" -x -k "Payload" > /Volumes/EFI/boot.plist
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
bootoption make -l "/Volumes/EFI/EFI/CLOVER/CLOVERX64.EFI" -L "Clover" -o "/Volumes/USB-FAT32/vars.dmpstore"
````

The resulting file can be read from the EFI shell. To load and set the variables:

```
FS0:\> dmpstore -l vars.dmpstore
```

## License

GPL version 3
