import Foundation

struct HardDriveMediaDevicePath {
        
        var data: Data {
                get {
                        var data = Data.init()
                        data.append(type)
                        data.append(subType)
                        data.append(length)
                        data.append(partitionNumber)
                        data.append(partitionStart)
                        data.append(partitionSize)
                        data.append(partitionSignature)
                        data.append(partitionFormat)
                        data.append(signatureType)
                        return data
                }
        }
        
        let mountPoint: String
        let type: Data = Data.init(bytes: [4])
        let subType: Data = Data.init(bytes: [1])
        let length: Data = Data.init(bytes: [42, 0])
        let partitionFormat = Data.init(bytes: [2])
        let signatureType = Data.init(bytes: [2])
        var partitionNumber = Data.init()
        var partitionStart = Data.init()
        var partitionSize = Data.init()
        var partitionSignature = Data.init()
        
        init(forFile path: String) {
                let fm: FileManager = FileManager()
                
                guard fm.fileExists(atPath: path) else {
                        print("MediaDescription: File not found")
                        exit(1)
                }
                
                guard let session:DASession = DASessionCreate(kCFAllocatorDefault) else {
                        print("MediaDescription: Failed to create DASession")
                        exit(1)
                }
                
                guard let volumes:[URL] = fm.mountedVolumeURLs(includingResourceValuesForKeys: nil) else {
                        print("MediaDescription: Failed to get mounted volume URLs")
                        exit(1)
                }
                
                /*
                 *  Find a mounted volume path from our loader path
                 */
                
                var longest: Int = 0
                var mountedVolumePath: String?
                let prefix: String = "file://"
                
                /* To do - eliminate anything that doesn't start with "file://" */
                
                for i in volumes {
                        let v: String = i.absoluteString.replacingOccurrences(of: prefix, with: "")
                        let c: Int = v.characters.count
                        let start = v.index(v.startIndex, offsetBy: 0), end = v.index(v.startIndex, offsetBy: c)
                        let test: String = String(path[start..<end])
                        
                        /*
                         *  Check if v is the start of our loader path string and
                         *  the longest mounted volume path thats also a string match
                         */
                        
                        if test == v && c > longest {
                                mountedVolumePath = v
                                longest = c
                        }
                }
                
                mountPoint = mountedVolumePath!
                
                /*
                 *  Find DAMedia registry path
                 */
                
                let cfMountPoint: CFString = mountPoint as CFString
                
                guard let url: CFURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, cfMountPoint, CFURLPathStyle(rawValue: 0)!, true) else {
                        print("MediaDescription: Failed to create CFURL for mount point")
                        exit(1)
                }
                guard let disk: DADisk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url) else {
                        print("MediaDescription: Failed to create DADisk from volume URL")
                        exit(1)
                }
                guard let cfDescription: CFDictionary = DADiskCopyDescription(disk) else {
                        print("MediaDescription: Failed to get volume description CFDictionary")
                        exit(1)
                }
                guard let description: [String: Any] = cfDescription as? Dictionary else {
                        print("MediaDescription: Failed to get volume description as Dictionary")
                        exit(1)
                }
                guard let registryPath = description["DAMediaPath"] as? String else {
                        print("MediaDescription: Failed to get DAMediaPath as String")
                        exit(1)
                }
                
                /*
                 *  Get the registry object for our partition
                 */
                
                let partitionProperties = RegistryEntry.init(from: registryPath)
                
                /* To do - Check disk is GPT */
                
                let ioPreferredBlockSize: Int? = partitionProperties.intFrom(key: "Preferred Block Size")
                let ioPartitionID: Int? = partitionProperties.intFrom(key: "Partition ID")
                let ioBase: Int? = partitionProperties.intFrom(key: "Base")
                let ioSize: Int? = partitionProperties.intFrom(key: "Size")
                let ioUUID: String? = partitionProperties.stringFrom(key: "UUID")
                
                if (ioPreferredBlockSize == nil || ioPartitionID == nil || ioBase == nil || ioSize == nil || ioUUID == nil) {
                        print ("MediaDescription: Failed to get registry values")
                        exit(1)
                }
                
                let blockSize = ioPreferredBlockSize!
                let uuid = ioUUID!
                var idValue = UInt32(ioPartitionID!)
                partitionNumber.append(UnsafeBufferPointer(start: &idValue, count: 1))
                var startValue = UInt64(ioBase! / blockSize)
                partitionStart.append(UnsafeBufferPointer(start: &startValue, count: 1))
                var sizeValue = UInt64(ioSize! / blockSize)
                partitionSize.append(UnsafeBufferPointer(start: &sizeValue, count: 1))
                
                
                /*
                 *  EFI Signature from volume GUID string
                 */
                
                func subStr(string: String, from: Int, to: Int) -> String {
                        let start = string.index(string.startIndex, offsetBy: from)
                        let end = string.index(string.startIndex, offsetBy: to)
                        return String(string[start..<end])
                }
                
                func hexStringToData(string: String, swap: Bool = false) -> Data? {
                        var strings: [String] = []
                        let width: Int = 2
                        let max: Int = string.characters.count
                        if swap {
                                var start: Int = max - width, end: Int = max
                                while start >= 0 {
                                        strings.append(subStr(string: string, from: start, to: end))
                                        start -= width; end = start + width
                                }
                        } else {
                                var start: Int = 0, end: Int = start + width
                                while end <= max {
                                        strings.append(subStr(string: string, from: start, to: end))
                                        start += width; end = start + width
                                }
                        }
                        let bytes: [UInt8] = strings.map{UInt8(strtoul((String($0)), nil, 16))}
                        return bytes.withUnsafeBufferPointer{Data(buffer: $0)}
                }
                
                var part: [String] = uuid.components(separatedBy: "-")
                partitionSignature.append(hexStringToData(string: part[0], swap: true)!)
                partitionSignature.append(hexStringToData(string: part[1], swap: true)!)
                partitionSignature.append(hexStringToData(string: part[2], swap: true)!)
                partitionSignature.append(hexStringToData(string: part[3])!)
                partitionSignature.append(hexStringToData(string: part[4])!)
                
        }
}

struct FilePathMediaDevicePath {
        
        var data: Data {
                get {
                        var data = Data.init()
                        data.append(type)
                        data.append(subType)
                        data.append(length)
                        data.append(path)
                        return data
                }
        }
        
        let type: Data = Data.init(bytes: [4])
        let subType: Data = Data.init(bytes: [4])
        var path = Data.init()
        var length = Data.init()
        
        init(path localPath: String, mountPoint: String) {
                
                /* Path */
                let c = mountPoint.characters.count
                let i = localPath.index(localPath.startIndex, offsetBy: c)
                var efiPath = "/" + localPath[i...]
                efiPath = efiPath.uppercased().replacingOccurrences(of: "/", with: "\\")
                var pathData = efiPath.data(using: String.Encoding.utf16)!
                pathData.removeFirst()
                pathData.removeFirst()
                pathData.append(contentsOf: [0, 0])
                path = pathData
                
                /* Length */
                var lengthValue = UInt16(pathData.count + 4)
                length.append(UnsafeBufferPointer(start: &lengthValue, count: 1))
                
        }
        
}

struct EndDevicePath {
        let data = Data.init(bytes: [127, 255, 4, 0])
}

