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
        
        /* data */
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
        
        /* properties */
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
        
        init(fromBootNumber number: Int, data: Data) {
                self.bootNumber = number
                self.order = nvram.positionInBootOrder(number: number) ?? -1
                var buffer: Data = data
                // attributes
                self.attributes = buffer.remove32()
                // device path list
                self.devicePathListLength = buffer.remove16()
                // description
                for _ in buffer {
                        var bytes: UInt16 = buffer.remove16()
                        self.description.append(UnsafeBufferPointer(start: &bytes, count: 1))
                        if bytes == 0 {
                                break
                        }
                }
                // device path list
                

        }
        
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
                let hardDrive = HardDriveMediaDevicePath(forFile: loader)
                let file = FilePathMediaDevicePath(path: loader, mountPoint: hardDrive.mountPoint)
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
}
