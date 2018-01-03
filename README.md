#  bootoption

A command line program that generates EFI boot load options for file media. Outputs data as an XML property list, raw hex or formatted string. A stored representation of the variable data can be used to work around situations where it is problematic to modify BootOrder, BootXXXX etc. in hardware NVRAM, while targeting a specific device path from inside the operating system (for instance, generated during loader installation, stored and then added from an EFI context).

## Usage


<div style="font-family: Monospace; margin-bottom: 1em">
bootoption -p <em>PATH</em> -d <em>LABEL</em> [ -u <em>STRING</em> ]<br />
<span style="margin-left: 4em">&nbsp;</span>
[ -o <em>FILENAME</em> | -x | -f ] [ -k <em>KEY</em> ]
</div>
<table style="margin-left: 2em;"">
        <tr style="vertical-align: top">
                <td style="width: 3em">-p</td>
                <td style="width: 8.5em">--path</td>
                <td><em style="font-family: Monospace">PATH</em> to an EFI loader</td>
        </tr>
        <tr style="vertical-align: top">
                <td>-d</td>
                <td>--description</td>
                <td>description (boot manager display <em style="font-family: Monospace">LABEL</em>)</td>
        </tr>
        <tr style="vertical-align: top">
                <td>-u</td>
                <td>--unicode</td>
                <td>unicode <em style="font-family: Monospace">STRING</em> passed to loader (command line arguments)</td>
        </tr>
        <tr style="vertical-align: top">
                <td>-o</td>
                <td>--output</td>
                <td>output to <em style="font-family: Monospace">FILENAME</em> (XML property list)</td>
        </tr>
        <tr style="vertical-align: top">
                <td>-x</td>
                <td>--xml</td>
                <td>print XML instead of raw hex</td>
        </tr>
        <tr style="vertical-align: top">
                <td>-f</td>
                <td>--format</td>
                <td>print format string instead of raw hex</td>
        </tr>
        <tr style="vertical-align: top">
                <td>-k</td>
                <td>--key</td>
                <td>specify <dict> <em style="font-family: Monospace">KEY</em> (XML property list, defaults to Boot)</td>
        </tr>
</table>


#### Example 1

```
bootoption -l "/Volumes/EFI/EFI/CLOVER/CLOVERX64.EFI" -L "Clover" -o "/Volumes/EFI/boot.plist" -k "Payload"
```
##### /Volumes/EFI/boot.plist:

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

#### Example 2

```
bootoption -l "/Volumes/EFI/EFI/CLOVER/CLOVERX64.EFI" -L "Clover" -f
```

##### Output:

```
%01%00%00%00%66%00%43%00%6c%00%6f%00%76%00%65%00%72%00%00%00%04%01%2a%00%01%00%00%00%00%08%00%00%00%00%00%00%00%40%06%00%00%00%00%00%d5%a8%cf%3e%7f%8c%5e%48%a9%0e%a9%17%f1%fa%7d%a5%02%02%04%04%38%00%5c%00%45%00%46%00%49%00%5c%00%43%00%4c%00%4f%00%56%00%45%00%52%00%5c%00%43%00%4c%00%4f%00%56%00%45%00%52%00%58%00%36%00%34%00%2e%00%45%00%46%00%49%00%00%00%7f%ff%04%00
```

#### mkbootoption.sh

An experimental and potentially dangerous shell script that will attempt to add a boot option to your EFI using Apple's nvram command. Usage:

```
sudo ./mkbootoption.sh "path" "description"
     required parameters:
     path                  path to an EFI executable
     description           description for the new boot menu entry
```

## License

GPL version 3
