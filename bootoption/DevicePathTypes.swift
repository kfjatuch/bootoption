/*
 * File: DevicePathTypes.swift
 *
 * bootoption © vulgo 2017-2018 - A command line utility for managing a
 * firmware's EFI boot menu
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import Foundation

enum DevicePath: UInt8 {
        case HARDWARE_DEVICE_PATH = 0x1
        case ACPI_DEVICE_PATH = 0x2
        case MESSAGING_DEVICE_PATH = 0x3
        case MEDIA_DEVICE_PATH = 0x4
        case BBS_DEVICE_PATH = 0x5
        case END_DEVICE_PATH_TYPE = 0x7f
        var description: String {
                switch self {
                case .HARDWARE_DEVICE_PATH:
                        return "HARDWARE_DEVICE_PATH"
                case .ACPI_DEVICE_PATH:
                        return "ACPI_DEVICE_PATH"
                case .MESSAGING_DEVICE_PATH:
                        return "MESSAGING_DEVICE_PATH"
                case .MEDIA_DEVICE_PATH:
                        return "MEDIA_DEVICE_PATH"
                case .BBS_DEVICE_PATH:
                        return "BBS_DEVICE_PATH"
                case .END_DEVICE_PATH_TYPE:
                        return "END_DEVICE_PATH_TYPE"
                }
        }
}

enum MediaDevicePath: UInt8 {
        case MEDIA_HARDDRIVE_DP = 0x1
        case MEDIA_CDROM_DP = 0x2
        case MEDIA_VENDOR_DP = 0x3
        case MEDIA_FILEPATH_DP = 0x4
        case MEDIA_PROTOCOL_DP = 0x5
        case MEDIA_PIWG_FW_FILE_DP = 0x6
        case MEDIA_PIWG_FW_VOL_DP = 0x7
        case MEDIA_RELATIVE_OFFSET_RANGE_DP = 0x8
        case MEDIA_RAM_DISK_DP = 0x9
        var description: String {
                switch self {
                case .MEDIA_HARDDRIVE_DP:
                        return "MEDIA_HARDDRIVE_DP"
                case .MEDIA_CDROM_DP:
                        return "MEDIA_CDROM_DP"
                case .MEDIA_VENDOR_DP:
                        return "MEDIA_VENDOR_DP"
                case .MEDIA_FILEPATH_DP:
                        return "MEDIA_FILEPATH_DP"
                case .MEDIA_PROTOCOL_DP:
                        return "MEDIA_PROTOCOL_DP"
                case .MEDIA_PIWG_FW_FILE_DP:
                        return "MEDIA_PIWG_FW_FILE_DP"
                case .MEDIA_PIWG_FW_VOL_DP:
                        return "MEDIA_PIWG_FW_VOL_DP"
                case .MEDIA_RELATIVE_OFFSET_RANGE_DP:
                        return "MEDIA_RELATIVE_OFFSET_RANGE_DP"
                case .MEDIA_RAM_DISK_DP:
                        return "MEDIA_RAM_DISK_DP"
                }
        }
}

enum HardwareDevicePath: UInt8 {
        case HW_PCI_DP = 0x1
        case HW_PCCARD_DP = 0x2
        case HW_MEMMAP_DP = 0x3
        case HW_VENDOR_DP = 0x4
        case HW_CONTROLLER_DP = 0x5
        case HW_BMC_DP = 0x6
        var description: String {
                switch self {
                case .HW_PCI_DP:
                        return "HW_PCI_DP"
                case .HW_PCCARD_DP:
                        return "HW_PCCARD_DP"
                case .HW_MEMMAP_DP:
                        return "HW_MEMMAP_DP"
                case .HW_VENDOR_DP:
                        return "HW_VENDOR_DP"
                case .HW_CONTROLLER_DP:
                        return "HW_CONTROLLER_DP"
                case .HW_BMC_DP:
                        return "HW_BMC_DP"
                }
        }
}

enum AcpiDevicePath: UInt8 {
        case ACPI_DP = 0x1
        case ACPI_EXTENDED_DP = 0x2
        case ACPI_ADR_DP = 0x3
        var description: String {
                switch self {
                case .ACPI_DP:
                        return "ACPI_DP"
                case .ACPI_EXTENDED_DP:
                        return "ACPI_EXTENDED_DP"
                case .ACPI_ADR_DP:
                        return "ACPI_ADR_DP"
                }
        }
}

enum MessagingDevicePath: UInt8 {
        case MSG_ATAPI_DP = 0x1
        case MSG_SCSI_DP = 0x2
        case MSG_FIBRECHANNEL_DP = 0x3
        case MSG_1394_DP = 0x4
        case MSG_USB_DP = 0x5
        case MSG_I2O_DP = 0x6
        case MSG_INFINIBAND_DP = 0x9
        case MSG_VENDOR_DP = 0xa
        case MSG_MAC_ADDR_DP = 0xb
        case MSG_IPv4_DP = 0xc
        case MSG_IPv6_DP = 0xd
        case MSG_UART_DP = 0xe
        case MSG_USB_CLASS_DP = 0xf
        case MSG_USB_WWID_DP = 0x10
        case MSG_DEVICE_LOGICAL_UNIT_DP = 0x11
        case MSG_SATA_DP = 0x12
        case MSG_ISCSI_DP = 0x13
        case MSG_VLAN_DP = 0x14
        case MSG_FIBRECHANNELEX_DP = 0x15
        case MSG_SASEX_DP = 0x16
        case MSG_NVME_NAMESPACE_DP = 0x17
        case MSG_URI_DP = 0x18
        case MSG_UFS_DP = 0x19
        case MSG_SD_DP = 0x1a
        case MSG_BLUETOOTH_DP = 0x1b
        case MSG_WIFI_DP = 0x1c
        case MSG_EMMC_DP = 0x1d
        case MSG_BLUETOOTH_LE_DP = 0x1e
        case MSG_DNS_DP = 0x1f
        var description: String {
                switch self {
                case .MSG_ATAPI_DP:
                        return "MSG_ATAPI_DP"
                case .MSG_SCSI_DP:
                        return "MSG_SCSI_DP"
                case .MSG_FIBRECHANNEL_DP:
                        return "MSG_FIBRECHANNEL_DP"
                case .MSG_1394_DP:
                        return "MSG_1394_DP"
                case .MSG_USB_DP:
                        return "MSG_USB_DP"
                case .MSG_I2O_DP:
                        return "MSG_I2O_DP"
                case .MSG_INFINIBAND_DP:
                        return "MSG_INFINIBAND_DP"
                case .MSG_VENDOR_DP:
                        return "MSG_VENDOR_DP"
                case .MSG_MAC_ADDR_DP:
                        return "MSG_MAC_ADDR_DP"
                case .MSG_IPv4_DP:
                        return "MSG_IPv4_DP"
                case .MSG_IPv6_DP:
                        return "MSG_IPv6_DP"
                case .MSG_UART_DP:
                        return "MSG_UART_DP"
                case .MSG_USB_CLASS_DP:
                        return "MSG_USB_CLASS_DP"
                case .MSG_USB_WWID_DP:
                        return "MSG_USB_WWID_DP"
                case .MSG_DEVICE_LOGICAL_UNIT_DP:
                        return "MSG_DEVICE_LOGICAL_UNIT_DP"
                case .MSG_SATA_DP:
                        return "MSG_SATA_DP"
                case .MSG_ISCSI_DP:
                        return "MSG_ISCSI_DP"
                case .MSG_VLAN_DP:
                        return "MSG_VLAN_DP"
                case .MSG_FIBRECHANNELEX_DP:
                        return "MSG_FIBRECHANNELEX_DP"
                case .MSG_SASEX_DP:
                        return "MSG_SASEX_DP"
                case .MSG_NVME_NAMESPACE_DP:
                        return "MSG_NVME_NAMESPACE_DP"
                case .MSG_URI_DP:
                        return "MSG_URI_DP"
                case .MSG_UFS_DP:
                        return "MSG_UFS_DP"
                case .MSG_SD_DP:
                        return "MSG_SD_DP"
                case .MSG_BLUETOOTH_DP:
                        return "MSG_BLUETOOTH_DP"
                case .MSG_WIFI_DP:
                        return "MSG_WIFI_DP"
                case .MSG_EMMC_DP:
                        return "MSG_EMMC_DP"
                case .MSG_BLUETOOTH_LE_DP:
                        return "MSG_BLUETOOTH_LE_DP"
                case .MSG_DNS_DP:
                        return "MSG_DNS_DP"
                }
        }
}

enum EndDevicePathEnum: UInt8 {
        case END_INSTANCE_DEVICE_PATH_SUBTYPE = 0x1
        case END_ENTIRE_DEVICE_PATH_SUBTYPE = 0xff
        var description: String {
                switch self {
                case .END_INSTANCE_DEVICE_PATH_SUBTYPE:
                        return "END_INSTANCE_DEVICE_PATH_SUBTYPE"
                case .END_ENTIRE_DEVICE_PATH_SUBTYPE:
                        return "END_ENTIRE_DEVICE_PATH_SUBTYPE"
                }
        }
}