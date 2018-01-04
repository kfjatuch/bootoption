## mkbootoption.sh

An experimental and potentially dangerous shell script that will attempt to add a boot option to your EFI using Apple's nvram command.

#### Usage

```
sudo ./mkbootoption.sh "path" "description"
required parameters:
path                  path to an EFI executable
description           description for the new boot menu entry
```
