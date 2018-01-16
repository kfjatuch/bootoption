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
        
        /* Data */
        
        var attributes: UInt32
        var devicePathListLength: UInt16
        var description = Data()
        var devicePathList = Data()
        var optionalData: Data?
        var data: Data {
                var data = Data.init()
                var buffer32: UInt32 = self.attributes
                data.append(UnsafeBufferPointer(start: &buffer32, count: 1))
                var buffer16: UInt16 = self.devicePathListLength
                data.append(UnsafeBufferPointer(start: &buffer16, count: 1))
                data.append(description)
                data.append(devicePathList)
                if (optionalData != nil) {
                        data.append(optionalData!)
                }
                return data
        }
        var devicePathDescription = String()
        
        /* Properties */
        
        var order: Int?
        var enabled: Bool? {
                return self.attributes & 0x1 == 0x1 ? true : false
        }
        var hidden: Bool? {
                return self.attributes & 0x8 == 0x8 ? true : false
        }
        var descriptionString: String {
                var data = self.description
                let string = data.removeEfiString()
                return string ?? (data as NSData).debugDescription
        }
        var optionalDataString: String? {
                if self.optionalData != nil {
                        var data = self.optionalData!
                        if let string = data.removeEfiString() {
                                return string
                        } else {
                                return nil
                        }
                } else {
                       return nil
                }
        }
        var optionalDataBytesString: String? {
                if self.optionalData != nil {
                        var dataString = String()
                        var data = self.optionalData!
                        var n: Int = 0
                        while !data.isEmpty {
                                if n != 0 && n % 8 == 0 {
                                        dataString.append("\n               ")
                                }
                                if data.count == 1 {
                                        let byte = data.remove8()
                                        let byteString = NSString(format: "%02x", byte) as String
                                        dataString.append(byteString)
                                } else {
                                        let bytes = data.remove16()
                                        let byteString = NSString(format: "%04x", bytes) as String
                                        dataString.append(byteString + " ")
                                }
                                n += 1
                        }
                        return dataString
                } else {
                        return nil
                }
        }
        
        /* Device paths */
        
        var hardDriveDevicePath = HardDriveMediaDevicePath()
        var fileDevicePath = Data.init()
        
        var pathString: String {
                if !self.fileDevicePath.isEmpty {
                        var data = fileDevicePath
                        if let string = data.removeEfiString() {
                                return string
                        }
                }
                return ""
        }
        
        /* Init from variable */
        
        init(fromBootNumber number: Int, data: Data, details: Bool = false) {
                self.bootNumber = number
                self.order = nvram.positionInBootOrder(number: number) ?? -1
                var buffer: Data = data
                // attributes
                self.attributes = buffer.remove32()
                // device path list length
                self.devicePathListLength = buffer.remove16()
                // description
                for _ in buffer {
                        var bytes: UInt16 = buffer.remove16()
                        self.description.append(UnsafeBufferPointer(start: &bytes, count: 1))
                        if bytes == 0 {
                                break
                        }
                }
                if details {
                        // device path list
                        self.devicePathList = buffer.remove(bytesAsData: Int(self.devicePathListLength))
                        parseDevicePathList(rawDevicePathList: self.devicePathList)
                        if !buffer.isEmpty {
                                self.optionalData = buffer
                        }
                }


        }
        
        /* Init create from path */
        
        init(createFromLoaderPath loader: String, label: String, unicode: String?) {

                /* Attributes */
                
                Log.info("Using default attributes")
                self.attributes = 0x1
                
                /* Description */
                
                Log.info("Generating description")
                if label.containsOutlawedCharacters() {
                        Log.error("Forbidden character(s) found in description")
                }
                
                self.description = label.efiStringData()
                
                /* Device path list */
                
                Log.info("Generating device path list")
                let hardDrive = HardDriveMediaDevicePath(createUsingFilePath: loader)
                let file = FilePathMediaDevicePath(createUsingFilePath: loader, mountPoint: hardDrive.mountPoint)
                let end = EndDevicePath()
                self.devicePathList = Data.init()
                self.devicePathList.append(hardDrive.data)
                self.devicePathList.append(file.data)
                self.devicePathList.append(end.data)
                
                /* Device path list length */
                
                Log.info("Generating device path list length")
                self.devicePathListLength = UInt16(self.devicePathList.count)
                
                /* Optional data */
                
                if unicode != nil {
                        Log.info("Generating optional data")
                        self.optionalData = unicode!.efiStringData(withNullTerminator: false)
                } else {
                        Log.info("Not generating optional data, none specified")
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
                        
                        case 0x4: // Found type 4, media device path
                                if self.devicePathDescription.isEmpty {
                                        self.devicePathDescription.append("\(devicePathTypes.media.description) ")
                                }
                                switch subType {
                                case 0x1: // Found type 4, sub-type 1, hard drive device path
                                        self.devicePathDescription.append("/ \(mediaSubTypes.mediaHardDrive.description) ")
                                        var hardDriveDevicePath = buffer.remove(bytesAsData: Int(length) - 4)
                                        if !parseHardDriveDevicePath(buffer: &hardDriveDevicePath) {
                                                Log.logExit(EX_IOERR, "Error parsing hard drive device path")
                                        }
                                        break;
                                case 0x4: // Found type 4, sub-type 4, file path
                                        self.devicePathDescription.append("/ \(mediaSubTypes.mediaFilePath.description) ")
                                        let pathData = buffer.remove(bytesAsData: Int(length) - 4)
                                        self.fileDevicePath = pathData
                                        buffer = Data.init()
                                        break;
                                case 0x2, 0x3, 0x5:
                                        switch subType {
                                        case 0x2:
                                                self.devicePathDescription.append("/ \(mediaSubTypes.mediaCdRom.description) ")
                                        case 0x3:
                                                self.devicePathDescription.append("/ \(mediaSubTypes.mediaVendor.description) ")
                                        case 0x5:
                                                self.devicePathDescription.append("/ \(mediaSubTypes.mediaProtocol.description) ")
                                        default:
                                                break
                                        }
                                default: // Found some other sub-type
                                        buffer = Data.init()
                                        break; 
                                }
                                break;
                        
                        case 0x1, 0x2, 0x3, 0x5, 0x7f:
                                switch type {
                                case 0x1:
                                        self.devicePathDescription.append("\(devicePathTypes.hardware.description) ")
                                case 0x2:
                                        self.devicePathDescription.append("\(devicePathTypes.acpi.description) ")
                                case 0x3:
                                        self.devicePathDescription.append("\(devicePathTypes.messaging.description) ")
                                case 0x5:
                                        self.devicePathDescription.append("\(devicePathTypes.bbs.description) ")
                                case 0x7f:
                                        self.devicePathDescription.append("\(devicePathTypes.end.description) ")
                                default:
                                        break
                                }
                                fallthrough
                        default: // Found some other type
                                buffer = Data.init()
                                break;
                        }
                }
        }
        
        mutating func parseHardDriveDevicePath(buffer: inout Data) -> Bool {
                self.hardDriveDevicePath.partitionNumber = buffer.remove32()
                self.hardDriveDevicePath.partitionStart = buffer.remove64()
                self.hardDriveDevicePath.partitionSize = buffer.remove64()
                self.hardDriveDevicePath.partitionSignature = buffer.remove(bytesAsData: 16)
                self.hardDriveDevicePath.partitionFormat = buffer.remove8()
                self.hardDriveDevicePath.signatureType = buffer.remove8()
                if !buffer.isEmpty || self.hardDriveDevicePath.signatureType != 2 {
                        print("parseHardDriveDevicePath(): Error", to: &standardError)
                        return false
                }
                return true
        }

}
