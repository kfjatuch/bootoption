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
        
        private var attributes: UInt32
        private var devicePathListLength: UInt16
        private var description: Data?
        private var devicePathList: Data?
        
        var hardDriveDevicePath: HardDriveDevicePath?
        var filePathDevicePath: FilePathDevicePath?
        var optionalData = OptionalData()
        
        var bootNumber: BootNumber?
        var devicePathDescription = ""
        
        var isClover: Bool {
                if let loaderPath = filePathDevicePath?.path {
                        if loaderPath.lowercased().contains("cloverx64.efi") {
                                return true
                        }
                }
                return false
        }
        
        var positionInBootOrder: Int? {
                if let bootNumber = bootNumber {
                        return Nvram.shared.bootOrderArray.index(of: bootNumber)
                } else {
                        return nil
                }
        }
        
        var data: Data {
                /* Buffer EfiLoadOption */
                guard description != nil, devicePathList != nil else {
                        Debug.fault("EfiLoadOption instance is not fully initialized, can't return data")
                }
                var buffer = Data.init()
                buffer.append(attributes.data)
                buffer.append(devicePathListLength.data)
                buffer.append(description!)
                buffer.append(devicePathList!)
                if let optionalData = self.optionalData.data {
                        buffer.append(optionalData)
                }
                return buffer
        }
        
        var dataString: String {
                let strings = data.map { String(format: "%02x", $0) }
                let dataString = strings.joined()
                return dataString
        }

        /*  LOAD_OPTION_ACTIVE 0x00000001 */
        
        var active: Bool {
                get {
                        return attributes & 0x00000001 == 0x00000001 ? true : false
                }
                set {
                        if newValue == true {
                                attributes = attributes | 0x00000001
                        }
                        if newValue == false {
                                attributes = attributes & 0xFFFFFFFE
                        }
                }
        }
        
        /*  LOAD_OPTION_HIDDEN 0x00000008 */
        
        var hidden: Bool {
                get {
                        return attributes & 0x00000008 == 0x00000008 ? true : false
                }
                set {
                        if newValue == true {
                                attributes = attributes | 0x00000008
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
        
        /* Methods */
        
        mutating func removeOptionalData() {
                optionalData.data = nil
        }
        
        /* Init from NVRAM variable */
        
        init(fromBootNumber number: BootNumber, data: Data, details: Bool = false) {
                
                bootNumber = number
                var buffer: Data = data
                
                /* Attributes */
                
                attributes = buffer.remove32()
                
                /* Device path list length */
                
                devicePathListLength = buffer.remove16()
                
                /* Description */
                
                description = Data()
                for _ in buffer {
                        let char = buffer.removeData(bytes: MemoryLayout<UInt16>.size)
                        description!.append(char)
                        if char.uint16 == 0x0000 {
                                break
                        }
                }
                
                if details {
                        /* Device path list */
                        devicePathList = buffer.removeData(bytes: Int(devicePathListLength))
                        parseDevicePathList(rawDevicePathList: devicePathList!)
                        
                        /* Optional data */
                        if !buffer.isEmpty {
                                optionalData.data = buffer
                        }
                }
                
                if let positionInBootOrder = positionInBootOrder {
                        Debug.log("%@ at position %@ in BootOrder", type: .info, argsList: number.variableName, positionInBootOrder)
                } else {
                        Debug.log("%@ not found in BootOrder", type: .info, argsList: number.variableName)
                }

        }
        
        /* Init create from local filesystem path */
        
        init(createFromLoaderPath loader: String, descriptionString: String, optionalData: Any?, ucs2OptionalData: Bool = false) {
                Debug.log("Initializing EfiLoadOption from loader filesystem path", type: .info)

                /* Attributes */
                attributes = 0x00000001
                Debug.log("Default attributes: %@", type: .info, argsList: String(attributes, radix: 2).leftPadding(toLength: 32, withPad: "0"))
                
                
                /* Description */
                if descriptionString.containsOutlawedCharacters() {
                        Debug.log("Forbidden character(s) found in description", type: .error)
                }
                
                description = descriptionString.efiStringData()
                guard description != nil else {
                        Debug.fault("Failed to set EfiLoadOption.description")
                }
                Debug.log("Description string: '%@', data: %@", type: .info, argsList: descriptionString, description!)
                
                /* Device path list */
                let hardDrive = HardDriveDevicePath(fromFilePath: loader)
                let file = FilePathDevicePath(createUsingFilePath: loader, mountPoint: hardDrive.mountPoint)
                let end = EndDevicePath()
                devicePathList = Data.init()
                devicePathList?.append(hardDrive.data)
                devicePathList?.append(file.data)
                devicePathList?.append(end.data)
                
                /* Device path list length */
                devicePathListLength = UInt16(devicePathList!.count)
                Debug.log("Device path list length: %@", type: .info, argsList: devicePathListLength)
                
                if DEBUG {
                        let originalDevicePathList = devicePathList
                        Debug.log("******************************************", type: .info)
                        Debug.log("DEBUG: Re-init device path list from data ", type: .info)
                        parseDevicePathList(rawDevicePathList: devicePathList!)
                        Debug.log("New device path list length: %@", type: .info, argsList: devicePathListLength)
                        Debug.log("String describing device path list: %@", type: .info, argsList: devicePathDescription)
                        Debug.log("DEBUG: Reverting device path list data ", type: .info)
                        Debug.log("******************************************", type: .info)
                        devicePathList = originalDevicePathList
                }
                
                /* Optional data */
                
                if let string = optionalData as? String {
                        self.optionalData.setOptionalData(string: string, clover: isClover, ucs: ucs2OptionalData)
                } else if let data = optionalData as? Data {
                        Debug.log("Optional data initialized from data", type: .info)
                        self.optionalData.data = data
                } else {
                        Debug.log("Not generating optional data", type: .info)
                }
                
                Debug.log("EfiLoadOption initialized from loader filesystem path", type: .info)
        }
        
        mutating func appendUnsupportedDescription(type: UInt8, subType: UInt8) {
                var descriptionComponent: String?
                switch type {
                case DevicePath.HARDWARE_DEVICE_PATH.rawValue:
                        if let string: String = HardwareDevicePath(rawValue: subType)?.description {
                                descriptionComponent = string
                        } else {
                                descriptionComponent = "HW_UNKNOWN"
                        }
                case DevicePath.ACPI_DEVICE_PATH.rawValue:
                        if let string: String = AcpiDevicePath(rawValue: subType)?.description {
                                descriptionComponent = string
                        } else {
                                descriptionComponent = "ACPI_UNKNOWN"
                        }
                case DevicePath.MESSAGING_DEVICE_PATH.rawValue:
                        if let string: String = MessagingDevicePath(rawValue: subType)?.description {
                                descriptionComponent = string
                        } else {
                                descriptionComponent = "MSG_UNKNOWN"
                        }
                case DevicePath.MEDIA_DEVICE_PATH.rawValue:
                        if let string: String = MediaDevicePath(rawValue: subType)?.description {
                                descriptionComponent = string
                        } else {
                                descriptionComponent = "MEDIA_UNKNOWN"
                        }
                case DevicePath.BBS_DEVICE_PATH.rawValue:
                        descriptionComponent = "BIOS_BOOT_SPECIFICATION"
                case DevicePath.END_DEVICE_PATH_TYPE.rawValue:
                        break
                default:
                        descriptionComponent = "UNKNOWN_DP_TYPE"
                        break
                }
                
                if let string = descriptionComponent {
                        Debug.log("DP List: Found type %@, sub-type %@, %@", type: .info, argsList: type, subType, string)
                        devicePathDescription.append("\\\(string)")
                }
        }
        
        /* Device path list parsing */
        
        mutating func parseDevicePathList(rawDevicePathList: Data) {
                Debug.log("Parsing device path list...", type: .info)
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
                                        Debug.log("DP List: Found type 4, sub-type 1, MEDIA_HARDDRIVE_DP", type: .info)
                                        let devicePathData = buffer.removeData(bytes: Int(length) - 4)
                                        hardDriveDevicePath = HardDriveDevicePath(devicePathData: devicePathData)
                                        if let string: String = MediaDevicePath(rawValue: subType)?.description {
                                                devicePathDescription.append("\\" + string)
                                        }
                                        break;
                                case MediaDevicePath.MEDIA_FILEPATH_DP.rawValue: // Found type 4, sub-type 4, file path
                                        Debug.log("DP List: Found type 4, sub-type 4, MEDIA_FILEPATH_DP", type: .info)
                                        filePathDevicePath = FilePathDevicePath()
                                        let devicePathData = buffer.removeData(bytes: Int(length) - 4)
                                        filePathDevicePath?.setDevicePath(data: devicePathData)
                                        if let string: String = MediaDevicePath(rawValue: subType)?.description {
                                                devicePathDescription.append("\\" + string)
                                        }
                                        break;
                                default: // Found some other sub-type
                                        appendUnsupportedDescription(type: type, subType: subType)
                                        let numberOfBytes = (Int(length) - 4 <= buffer.count) ? Int(length) - 4 : 0
                                        if numberOfBytes > 0 {
                                                buffer.removeData(bytes: numberOfBytes)
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
                                        buffer.removeData(bytes: numberOfBytes)
                                } else {
                                        buffer = Data.init()
                                }
                                break;
                        }
                }
        }
        
        var formatString: String {
                let strings = data.map { String(format: "%%%02x", $0) }
                let formatString = strings.joined()
                return formatString
        }
        
        var xmlString: String {
                let key: String = "Boot"
                let dictionary: NSDictionary = ["\(key)": data]
                var propertyList: Data
                do {
                        propertyList = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
                } catch let error as NSError {
                        let errorDescription = error.localizedDescription
                        let errorCode = error.code
                        print(errorDescription)
                        Debug.log("%@ (%@)", type: .error, argsList: errorDescription, errorCode)
                        Debug.fault("Error serializing to XML")
                }
                guard let xml = String(data: propertyList, encoding: .utf8) else {
                        Debug.fault("Error generating XML string")
                }
                let xmlString = String(xml.filter { !"\n\t\r".contains($0) })
                return xmlString
        }
}
