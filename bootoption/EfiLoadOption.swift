/*
 * File: EfiLoadOption.swift
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
        
struct EfiLoadOption {
        
        var bootNumber: Int?
        
        /* Device paths */
        
        var hardDrive: MediaHardDriveDevicePath?
        var loaderPath: MediaFilePathDevicePath?
        
        var loaderPathString: String? {
                if var data = loaderPath?.devicePath {
                        return data.removeEfiString()
                } else {
                        return nil
                }
        }
        
        /* Data */
        
        var attributes: UInt32
        var devicePathListLength: UInt16
        var description: Data?
        var devicePathList = Data()
        var optionalData: Data?
        var data: Data {
                var data = Data.init()
                var buffer32: UInt32 = attributes
                data.append(UnsafeBufferPointer(start: &buffer32, count: 1))
                var buffer16: UInt16 = devicePathListLength
                data.append(UnsafeBufferPointer(start: &buffer16, count: 1))
                if let description: Data = description {
                        data.append(description)
                }
                data.append(devicePathList)
                if let buffer: Data = optionalData {
                        data.append(buffer)
                }
                return data
        }
        var devicePathDescription = String()
        
        /* Properties */
        
        var order: Int?
        var enabled: Bool? {
                return attributes & 0x1 == 0x1 ? true : false
        }
        var hidden: Bool? {
                return attributes & 0x8 == 0x8 ? true : false
        }
        var descriptionString: String? {
                get {
                        var data: Data? = description
                        return data?.removeEfiString() ?? nil
                }
                set {
                        description = newValue?.efiStringData() ?? nil
                }
        }
        var optionalDataString: String? {
                get {
                        var data: Data? = optionalData
                        return data?.removeEfiString() ?? nil
                }
                set {
                        optionalData = newValue?.efiStringData(withNullTerminator: false) ?? nil
                }
        }
        var optionalDataHexView: String? {
                if var data: Data = optionalData {
                        var dataString = String()
                        var ascii = String()
                        var n: Int = 0
                        while !data.isEmpty {
                                if n != 0 && n % 8 == 0 {
                                        dataString.append("\(ascii)\n")
                                        ascii = String()
                                }
                                if data.count == 1 {
                                        let byte = data.remove8()
                                        let byteString = NSString(format: "%02x", byte) as String
                                        dataString.append(byteString)
                                } else {
                                        let bytes = data.remove16()
                                        let byteString = NSString(format: "%04x", bytes) as String
                                        if bytes > 0x20 {
                                                if let c = UnicodeScalar(bytes), c.isASCII {
                                                        let str = String(c)
                                                        ascii.append(str)
                                                } else {
                                                        ascii.append(" ")
                                                }
                                        } else {
                                                ascii.append(" ")
                                        }
                                        dataString.append(byteString + " ")
                                }
                                n += 1
                        }
                        for _ in 1...(8 - n % 8) {
                                dataString.append("     ")
                        }
                        dataString.append("\(ascii)")
                        return dataString
                } else {
                        return nil
                }
        }
        
        /* Init from variable */
        
        init(fromBootNumber number: Int, data: Data, details: Bool = false) {
                bootNumber = number
                order = nvram.positionInBootOrder(number: number) ?? -1
                var buffer: Data = data
                // attributes
                attributes = buffer.remove32()
                // device path list length
                devicePathListLength = buffer.remove16()
                // description
                description = Data()
                for _ in buffer {
                        var bytes: UInt16 = buffer.remove16()
                        description!.append(UnsafeBufferPointer(start: &bytes, count: 1))
                        if bytes == 0 {
                                break
                        }
                }
                if details {
                        // device path list
                        devicePathList = buffer.remove(bytesAsData: Int(devicePathListLength))
                        parseDevicePathList(rawDevicePathList: devicePathList)
                        if !buffer.isEmpty {
                                optionalData = buffer
                        }
                }


        }
        
        /* Init create from path */
        
        init(createFromLoaderPath loader: String, descriptionString: String, optionalDataString: String?) {

                /* Attributes */
                
                Log.info("Using default attributes")
                attributes = 0x1
                
                /* Description */
                
                Log.info("Generating description")
                if descriptionString.containsOutlawedCharacters() {
                        Log.error("Forbidden character(s) found in description")
                }
                
                description = descriptionString.efiStringData()
                guard description != nil else {
                        Log.logExit(EX_SOFTWARE, "Failed to set description, did String.efiStringData() return nil?")
                }
                
                /* Device path list */
                
                Log.info("Generating device path list")
                let hardDrive = MediaHardDriveDevicePath(createUsingFilePath: loader)
                let file = MediaFilePathDevicePath(createUsingFilePath: loader, mountPoint: hardDrive.mountPoint)
                let end = EndDevicePath()
                devicePathList = Data.init()
                devicePathList.append(hardDrive.data)
                devicePathList.append(file.data)
                devicePathList.append(end.data)
                
                /* Device path list length */
                
                Log.info("Generating device path list length")
                devicePathListLength = UInt16(devicePathList.count)
                
                /* Optional data */
                
                if let stringToData: Data = optionalDataString?.efiStringData(withNullTerminator: false) {
                        Log.info("Generating optional data")
                        optionalData = stringToData
                } else {
                        Log.info("Not generating optional data")
                }
                
        }
        
        mutating func appendUnsupportedDescription(type: UInt8, subType: UInt8) {
                switch type {
                case DevicePath.HARDWARE_DEVICE_PATH.rawValue:
                        if let string: String = HardwareDevicePath(rawValue: subType)?.description {
                                devicePathDescription.append("/" + string)
                        } else {
                                devicePathDescription.append("/HW_UNKNOWN")
                        }
                case DevicePath.ACPI_DEVICE_PATH.rawValue:
                        if let string: String = AcpiDevicePath(rawValue: subType)?.description {
                                devicePathDescription.append("/" + string)
                        } else {
                                devicePathDescription.append("/ACPI_UNKNOWN")
                        }
                case DevicePath.MESSAGING_DEVICE_PATH.rawValue:
                        if let string: String = MessagingDevicePath(rawValue: subType)?.description {
                                devicePathDescription.append("/" + string)
                        } else {
                                devicePathDescription.append("/MSG_UNKNOWN")
                        }
                case DevicePath.MEDIA_DEVICE_PATH.rawValue:
                        if let string: String = MediaDevicePath(rawValue: subType)?.description {
                                devicePathDescription.append("/" + string)
                        } else {
                                devicePathDescription.append("/MEDIA_UNKNOWN")
                        }
                case DevicePath.BBS_DEVICE_PATH.rawValue:
                        devicePathDescription.append("/BIOS_BOOT_SPECIFICATION")
                case DevicePath.END_DEVICE_PATH_TYPE.rawValue:
                        break
                default:
                        devicePathDescription.append("/UNKNOWN_DP_TYPE")
                        break
                }
        }
        
        /* Device path parsing */
        
        mutating func parseDevicePathList(rawDevicePathList: Data) {
                var buffer = rawDevicePathList
                while !(buffer.isEmpty) {
                        let type = buffer.remove8()
                        let subType = buffer.remove8()
                        let length = buffer.remove16()
                        // Right now we only care about paths to files on GPT hard drives
                        switch type {
                        case DevicePath.MEDIA_DEVICE_PATH.rawValue: // Found type 4, media device path
                                switch subType {
                                case MediaDevicePath.MEDIA_HARDDRIVE_DP.rawValue: // Found type 4, sub-type 1, hard drive device path
                                        hardDrive = MediaHardDriveDevicePath()
                                        var hardDriveDevicePath = buffer.remove(bytesAsData: Int(length) - 4)
                                        if !parseHardDriveDevicePath(buffer: &hardDriveDevicePath) {
                                                Log.logExit(EX_IOERR, "Error parsing hard drive device path")
                                        }
                                        if let string: String = MediaDevicePath(rawValue: subType)?.description {
                                                devicePathDescription.append("/" + string)
                                        }
                                        break;
                                case MediaDevicePath.MEDIA_FILEPATH_DP.rawValue: // Found type 4, sub-type 4, file path
                                        loaderPath = MediaFilePathDevicePath()
                                        let pathData = buffer.remove(bytesAsData: Int(length) - 4)
                                        loaderPath?.devicePath = pathData
                                        if let string: String = MediaDevicePath(rawValue: subType)?.description {
                                                devicePathDescription.append("/" + string)
                                        }
                                        break;
                                default: // Found some other sub-type
                                        appendUnsupportedDescription(type: type, subType: subType)
                                        let numberOfBytes = (Int(length) - 4 <= buffer.count) ? Int(length) - 4 : 0
                                        if numberOfBytes > 0 {
                                                buffer.remove(bytesAsData: numberOfBytes)
                                        } else {
                                                buffer = Data.init()
                                        }
                                        break; 
                                }
                                break;
                        default: // Found some other type
                                appendUnsupportedDescription(type: type, subType: subType)
                                let numberOfBytes = (Int(length) - 4 <= buffer.count) ? Int(length) - 4 : 0
                                if numberOfBytes > 0 {
                                        buffer.remove(bytesAsData: numberOfBytes)
                                } else {
                                        buffer = Data.init()
                                }
                                break;
                        }
                }
        }
        
        mutating func parseHardDriveDevicePath(buffer: inout Data) -> Bool {
                hardDrive?.partitionNumber = buffer.remove32()
                hardDrive?.partitionStart = buffer.remove64()
                hardDrive?.partitionSize = buffer.remove64()
                hardDrive?.partitionSignature = buffer.remove(bytesAsData: 16)
                hardDrive?.partitionFormat = buffer.remove8()
                hardDrive?.signatureType = buffer.remove8()
                if !buffer.isEmpty {
                        print("parseHardDriveDevicePath(): Error", to: &standardError)
                        return false
                }
                if hardDrive?.signatureType != 2 || hardDrive?.partitionFormat != 2 {
                        print("parseHardDriveDevicePath(): Only GPT is supported at this time", to: &standardError)
                        return false
                }
                return true
        }

}
