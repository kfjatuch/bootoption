#  bootoption

<p align="center">
<picture>
<source srcset="https://github.com/vulgo/bootoption/raw/master/Images/screenshot.png, https://github.com/vulgo/bootoption/raw/master/Images/screenshot@2x.png 2x" />
<img src="https://github.com/vulgo/bootoption/raw/master/Images/screenshot@2x.png" alt="bootoption screenshot" width="750" />
</picture>
</p>

A command line utility for managing a UEFI firmware's boot menu on macOS. Like efibootmgr. Report bugs [here on GitHub](https://github.com/vulgo/bootoption/issues).

## Installing

Install bootoption with [Homebrew](https://brew.sh)

```
brew tap vulgo/repo
brew install bootoption
```

## Usage

bootoption \<command> [options]

available commands:

- <strong>list</strong>&nbsp;&nbsp;show the firmware boot menu
- <strong>info</strong>&nbsp;&nbsp;show an option's properties
- <strong>set</strong>&nbsp;&nbsp;set/modify variables in NVRAM
- <strong>create</strong>&nbsp;&nbsp;create a new EFI load option
- <strong>order</strong>&nbsp;&nbsp;re-arrange the boot order
- <strong>delete</strong>&nbsp;&nbsp;delete variables from NVRAM
- <strong>reboot</strong>&nbsp;&nbsp;reboot to firmware settings

bootoption \<command> without options will show the usage or options for that command, where available. Making changes to the boot menu requires sudo and working hardware NVRAM - for instance, emulated NVRAM will not work.


#### Create a new option and add it to the boot order

```
sudo bootoption create -l /Volumes/EFI/EFI/GRUB/GRUBX64.EFI -d "GNU GRUB"
```

#### Move an option from 4th to 1st in the boot order

```
sudo bootoption order 4 to 1
```

#### Disable an option

```
sudo bootoption set -n Boot0002 --active=0
```

#### Change the boot menu timeout to 10 seconds

```
sudo bootoption set -t 10
```

#### Set an option's command line argmuments

```
sudo bootoption set -n Boot0000 -a "initrd=/initramfs.img root=/dev/disk/by-uuid/346d9a61-f7e5-4f58-bad7-026bb5376e0f"
```

#### Reboot to firmware settings

```
sudo bootoption reboot
```

## License

bootoption is free software: you are free to change and redistribute it. See the GNU GPL version 3 or later [http://gnu.org/licenses/gpl.html](http://gnu.org/licenses/gpl.html)
