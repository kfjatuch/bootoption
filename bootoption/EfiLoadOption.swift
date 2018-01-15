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
                return string
        }
        var optionalDataString: String {
                if self.optionalData != nil {
                        var data = self.optionalData
                        let string = data!.removeEfiString()
                        return string
                } else {
                        return ""
                }
        }
        
        /* Device paths */
        
        var hardDriveDevicePath: HardDriveMediaDevicePath?
        var fileDevicePath = Data.init()
        
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
                        case 4: // Found type 4, media device path
                                switch subType {
                                case 1: // Found type 4, sub-type 1, hard drive device path
                                        var hardDriveDevicePath = buffer.remove(bytesAsData: Int(length) - 4)
                                        if !parseHardDriveDevicePath(buffer: &hardDriveDevicePath) {
                                                Log.logExit(EX_IOERR, "Error parsing hard drive device path")
                                        }
                                        break;
                                case 4: // Found type 4, sub-type 4, file path
                                        let pathData = buffer.remove(bytesAsData: Int(length) - 4)
                                        self.fileDevicePath = pathData
                                        buffer = Data.init()
                                        break;
                                default: // Found some other sub-type
                                        buffer = Data.init()
                                        break; 
                                }
                                break;
                        default: // Found some other type
                                buffer = Data.init()
                                break;
                        }
                }
        }
        
        mutating func parseHardDriveDevicePath(buffer: inout Data) -> Bool {
                self.hardDriveDevicePath = HardDriveMediaDevicePath.init()
                self.hardDriveDevicePath?.partitionNumber = buffer.remove32()
                self.hardDriveDevicePath?.partitionStart = buffer.remove64()
                self.hardDriveDevicePath?.partitionSize = buffer.remove64()
                self.hardDriveDevicePath?.partitionSignature = buffer.remove(bytesAsData: 16)
                self.hardDriveDevicePath?.partitionFormat = buffer.remove8()
                self.hardDriveDevicePath?.signatureType = buffer.remove8()
                if !buffer.isEmpty || self.hardDriveDevicePath?.signatureType != 2 {
                        print("parseHardDriveDevicePath(): Error", to: &standardError)
                        return false
                }
                return true
        }
}
