import Foundation
import IOKit

class RegistryEntry {
        
        var registryEntry:io_registry_entry_t = io_registry_entry_t.init()
        
        init(from: String) {
                registryEntry = IORegistryEntryFromPath(kIOMasterPortDefault, from)
                guard registryEntry != 0 else {
                        print("RegistryEntry: Error getting registry entry from path")
                        exit(1)
                }
        }
        
        private func valueFrom(key: String, type: CFTypeID) -> Any? {
                let registryKey:CFString = key as CFString
                let registryValue:Unmanaged<CFTypeRef>? = (IORegistryEntryCreateCFProperty(registryEntry, registryKey , kCFAllocatorDefault, 0))
                
                guard (registryValue != nil) else {
                        return nil
                }
                
                let value = registryValue!.takeRetainedValue()
                let valueType = CFGetTypeID(value)
                
                guard valueType == type else {
                        print("Error: valueFrom(): Expected '\(CFCopyTypeIDDescription(type))' type for '\(key)' Instead: '\(CFCopyTypeIDDescription(valueType))'")
                        return nil
                }
                
                return value
        }
        
        func dataFrom(key: String) -> Data? {
                
                guard let data:Data = valueFrom(key: key, type: CFDataGetTypeID() ) as? Data else {
                        return nil
                }
                
                return data
        }
        
        func intFrom(key: String) -> Int? {
                
                guard let int:Int = valueFrom(key: key, type: CFNumberGetTypeID()) as? Int else {
                        return nil
                }
                
                return int
        }
        
        func stringFrom(key: String) -> String? {
                
                guard let string:String = valueFrom(key: key, type: CFStringGetTypeID()) as? String else {
                        return nil
                }
                
                return string
        }
        
}

