/*
 * File: create.swift
 *
 * bootoption © vulgo 2018 - A command line utility for managing a
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

/*
 *  Function for command: create
 */

func create() {
        
        Debug.log("Setting up command line", type: .info)
        let loaderPathOption = StringOption(shortFlag: "l", longFlag: "loader", required: 1,  helpMessage: "the PATH to an EFI loader executable")
        let loaderDescriptionOption = StringOption(shortFlag: "d", longFlag: "description", required: 1, helpMessage: "display LABEL in firmware boot manager")
        let loaderCommandLineOption = StringOption(shortFlag: "a", longFlag: "arguments", helpMessage: "an optional STRING passed to the loader command line", precludes: "f")
        let ucs2EncodingOption = BoolOption(shortFlag: "u", helpMessage: "pass command line arguments as UCS-2 (default is ASCII)")
        let fileDataOption = StringOption(shortFlag: "f", longFlag: "file", helpMessage: "append binary optional data from FILE", precludes: "au")
        commandLine.invocationHelpMessage = "create -l PATH -d LABEL [-a STRING] [-u] [-f FILE]"
        commandLine.setOptions(loaderPathOption, loaderDescriptionOption, loaderCommandLineOption, ucs2EncodingOption, fileDataOption)
        
        func createMain() {
                
                var fileData: Data?
                
                /* Check root */
                
                if NSUserName() != "root" {
                        Debug.log("Only root can set NVRAM variables", type: .error)
                        Debug.fault("Permission denied")
                }
                
                var status = EX_OK
                
                /* Read data from file if path specified */
                
                if let filePath = fileDataOption.value {
                        guard FileManager.default.fileExists(atPath: filePath) else {
                                Debug.fault("\(filePath) not found")
                        }
                        let data = NSData.init(contentsOfFile: filePath)
                        guard data != nil else {
                                Debug.fault("Data from \(filePath) should no longer be nil")
                        }
                        fileData = data as Data?
                }
                
                Debug.terminate(1)
                
                /* Set a new load option */
                
                if let loaderPath = loaderPathOption.value, let description = loaderDescriptionOption.value {
                        let option = EfiLoadOption(createFromLoaderPath: loaderPath, descriptionString: description, optionalDataString: loaderCommandLineOption.value, ucs2OptionalData: ucs2EncodingOption.value, optionalDataRaw: fileData)
                        if Nvram.shared.setNewEfiLoadOption(data: option.data, addingToBootOrder: true) == nil {
                                print("Error setting boot option", to: &standardError)
                                status = EX_DATAERR
                        }
                } else {
                        status = EX_NOINPUT
                }
                
                Debug.terminate(status)
        }
        
        /*
         *  Parse command line
         */
        
        commandLine.parseOptions(strict: true)
        switch commandLine.parserStatus {
        case .success:
                createMain()     
        default:
                commandLine.printErrorAndUsage()
                Debug.terminate(EX_USAGE)
        }
}
