#
#  File: mkbootoption.sh
#
#  bootoption © vulgo 2017 - A program to create / save an EFI boot
#  option - so that it might be added to the firmware menu later
#
#  mkbootoption.sh - script to add a boot option to firmware
#  * note 1: hardware syncs unreliably even with 'native' nvram
#  * note 2: allow unrestricted nvram access in CSR flags
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

cd "$(dirname "$0")"
NVRAMBYTES=./nvrambytes
BOOTOPTION=./bootoption
EFI_GLOBAL_GUID="8BE4DF61-93CA-11D2-AA0D-00E098032B8C"
NVRAM=/usr/sbin/nvram
PLIST="$TMPDIR/boot.plist"
EMPTY_BOOT_VARIABLE_WITH_GUID="none"

function usage {
        echo "Usage: $(basename $0) \"path\" \"description\""
        echo "     required parameters:"
        echo "     path                        path to EFI executable"
        echo "     description                 name for boot menu entry"
}

function error {
        # error message exit_code
        echo
        printf "Error: $1 ($2)\n"
        silent rm -f $PLIST
        usage
        exit 1
}

function on_error {
        # on_error message exit_code
        if [ $2 -ne 0 ]; then
                error "$1" $2
        fi
}

function silent {
        "$@" > /dev/null 2>&1
}

# Check root

if [ "$(id -u)" != "0" ]; then
        printf "Run it as root: sudo $(basename $0) $@"
        exit 1
fi

# Start

if [ "$#" != "2" ]; then
        usage
        exit 1
fi

silent rm -f $PLIST
$BOOTOPTION -p "$1" -d "$2" -o "$PLIST"
on_error "Failed to create variable data" $?
DATA=$($NVRAMBYTES "$PLIST")
on_error "Failed to generate formatted string" $?
for i in $(seq 0 255); do
        EFI_VARIABLE_NAME=$(printf "Boot%04X\n" "$i")
        TEST="$EFI_GLOBAL_GUID:$EFI_VARIABLE_NAME"
        silent $NVRAM -p $TEST
        if [ "$?" != "0" ]; then
                EMPTY_BOOT_VARIABLE_WITH_GUID=$TEST
                break
        fi
done
if [ $EMPTY_BOOT_VARIABLE_WITH_GUID = "none" ]; then
        error "Couldn't find an empty boot variable" 1
fi
$NVRAM -d "$EMPTY_BOOT_VARIABLE_WITH_GUID"
$NVRAM "$EMPTY_BOOT_VARIABLE_WITH_GUID=$DATA"
on_error "Failed to set boot variable" $?
echo "Variable $EMPTY_BOOT_VARIABLE_WITH_GUID was set."
echo "You can check if it really exists in firmware settings..."
silent rm -f $PLIST
exit 0
