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
        
        /* Device paths */
        
        var hardDriveDevicePath: HardDriveDevicePath?
        var filePathDevicePath: FilePathDevicePath?

        /* Data */
        
        private var attributes: UInt32
        private var devicePathListLength: UInt16
        private var description: Data?
        private var devicePathList: Data?
        private var optionalData: Data?
        
        /* Properties */
        
        var bootNumber: Int?
        var data: Data {
                get {
                        var attributes: UInt32 = self.attributes
                        var devicePathListLength: UInt16 = self.devicePathListLength
                        guard let description: Data = self.description, let devicePathList = self.devicePathList, let optionalData: Data = self.optionalData else {
                                Log.logExit(EX_DATAERR)
                        }
                        var buffer = Data.init()
                        buffer.append(UnsafeBufferPointer(start: &attributes, count: 1))
                        buffer.append(UnsafeBufferPointer(start: &devicePathListLength, count: 1))
                        buffer.append(description)
                        buffer.append(devicePathList)
                        buffer.append(optionalData)
                        return buffer
                }
        }
        var devicePathDescription = String()
        var order: Int?
        var active: Bool {
                /*  LOAD_OPTION_ACTIVE 0x00000001 */
                get {
                        return attributes & 0x1 == 0x1 ? true : false
                }
                set {
                        if newValue == true {
                                attributes = attributes | 0x1
                        }
                        if newValue == false {
                                attributes = attributes & 0xFFFFFFFE
                        }
                }
        }
        var hidden: Bool {
                /*  LOAD_OPTION_HIDDEN 0x00000008 */
                get {
                        return attributes & 0x8 == 0x8 ? true : false
                }
                set {
                        if newValue == true {
                                attributes = attributes | 0x8
                        }
                        if newValue == false {
                                attributes = attributes & 0xFFFFFFF7
                        }
                }
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
        var optionalDataStringView: String? {
                get {
                        var data: Data? = optionalData
                        return data?.removeEfiString() ?? nil
                }
                set {
                        optionalData = newValue?.efiStringData(withNullTerminator: false) ?? nil
                }
        }
        var optionalDataHexView: String? {
                func getAscii(bytes: UInt16) -> String {
                        var ascii: String = " "
                        if bytes > 0x20, let scalar = UnicodeScalar(bytes), scalar.isASCII {
                                ascii = String(scalar)
                        }
                        return ascii
                }
                if var buffer: Data = optionalData, !buffer.isEmpty {
                        var rows = String()
                        var asciiColumn = String()
                        var columnNumber: Int = 0
                        repeat {
                                switch buffer.count > 1 {
                                case true:
                                        let bytes = buffer.remove16()
                                        let bytesString = NSString(format: "%04x", bytes) as String
                                        asciiColumn.append(getAscii(bytes: bytes))
                                        rows.append(bytesString + " ")
                                default:
                                        let byte = buffer.remove8()
                                        rows.append(NSString(format: "%02x", byte) as String)
                                        rows.append("   ")
                                }
                                columnNumber += 1; if columnNumber % 8 == 0 {
                                        rows.append("\(asciiColumn)\n")
                                        asciiColumn = String()
                                }
                        } while !buffer.isEmpty
                        for _ in 1...(8 - columnNumber % 8) {
                                rows.append("     ")
                        }
                        rows.append(asciiColumn)
                        return rows
                }
                return nil
        }
        
        /* Methods */
        
        mutating func removeOptionalData() {
                optionalData = nil
        }
        
        /* Init from NVRAM variable */
        
        init(fromBootNumber number: Int, data: Data, details: Bool = false) {
                bootNumber = number
                order = nvram.positionInBootOrder(number: number) ?? -1
                var buffer: Data = data
                
                /* Attributes */
                
                attributes = buffer.remove32()
                
                /* Device path list length */
                
                devicePathListLength = buffer.remove16()
                
                /* Description */
                
                description = Data()
                for _ in buffer {
                        var bytes: UInt16 = buffer.remove16()
                        description!.append(UnsafeBufferPointer(start: &bytes, count: 1))
                        if bytes == 0 {
                                break
                        }
                }
                if details {
                        
                        /* Device path list */
                        
                        devicePathList = buffer.remove(bytesAsData: Int(devicePathListLength))
                        parseDevicePathList(rawDevicePathList: devicePathList!)
                        
                        /* Optional data */
                        
                        if !buffer.isEmpty {
                                optionalData = buffer
                        }
                }

        }
        
        /* Init create from local filesystem path */
        
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
                let hardDrive = HardDriveDevicePath(createUsingFilePath: loader)
                let file = FilePathDevicePath(createUsingFilePath: loader, mountPoint: hardDrive.mountPoint)
                let end = EndDevicePath()
                devicePathList = Data.init()
                devicePathList?.append(hardDrive.data)
                devicePathList?.append(file.data)
                devicePathList?.append(end.data)
                
                /* Device path list length */
                
                Log.info("Generating device path list length")
                devicePathListLength = UInt16(devicePathList!.count)
                
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
                                devicePathDescription.append("\\" + string)
                        } else {
                                devicePathDescription.append("\\HW_UNKNOWN")
                        }
                case DevicePath.ACPI_DEVICE_PATH.rawValue:
                        if let string: String = AcpiDevicePath(rawValue: subType)?.description {
                                devicePathDescription.append("\\" + string)
                        } else {
                                devicePathDescription.append("\\ACPI_UNKNOWN")
                        }
                case DevicePath.MESSAGING_DEVICE_PATH.rawValue:
                        if let string: String = MessagingDevicePath(rawValue: subType)?.description {
                                devicePathDescription.append("\\" + string)
                        } else {
                                devicePathDescription.append("\\MSG_UNKNOWN")
                        }
                case DevicePath.MEDIA_DEVICE_PATH.rawValue:
                        if let string: String = MediaDevicePath(rawValue: subType)?.description {
                                devicePathDescription.append("\\" + string)
                        } else {
                                devicePathDescription.append("\\MEDIA_UNKNOWN")
                        }
                case DevicePath.BBS_DEVICE_PATH.rawValue:
                        devicePathDescription.append("\\BIOS_BOOT_SPECIFICATION")
                case DevicePath.END_DEVICE_PATH_TYPE.rawValue:
                        break
                default:
                        devicePathDescription.append("\\UNKNOWN_DP_TYPE")
                        break
                }
        }
        
        /* Device path list parsing */
        
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
                                        hardDriveDevicePath = HardDriveDevicePath()
                                        let devicePathData = buffer.remove(bytesAsData: Int(length) - 4)
                                        if hardDriveDevicePath!.parseHardDriveDevicePath(data: devicePathData) == false {
                                                Log.logExit(EX_IOERR, "Error parsing hard drive device path")
                                        }
                                        if let string: String = MediaDevicePath(rawValue: subType)?.description {
                                                devicePathDescription.append("\\" + string)
                                        }
                                        break;
                                case MediaDevicePath.MEDIA_FILEPATH_DP.rawValue: // Found type 4, sub-type 4, file path
                                        filePathDevicePath = FilePathDevicePath()
                                        let devicePathData = buffer.remove(bytesAsData: Int(length) - 4)
                                        filePathDevicePath?.setDevicePath(data: devicePathData)
                                        if let string: String = MediaDevicePath(rawValue: subType)?.description {
                                                devicePathDescription.append("\\" + string)
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
}
