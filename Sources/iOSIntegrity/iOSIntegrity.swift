//
//  FileUtils.swift
//  integrity
//
//  Created by Thomas Hoppe on 3/4/2565 BE.
//

import Foundation
import CommonCrypto
import MachO

public enum IntegrityCheckerImageTarget {
    // Default image
    case `default`

    // Custom image with a specified name
    case custom(String)
}



public class iOSIntegrity {

    public static func sha256(url: URL) -> Data? {
        do {
            let bufferSize = 1024 * 1024
            // Open file for reading:
            let file = try FileHandle(forReadingFrom: url)
            defer {
                file.closeFile()
            }

            // Create and initialize SHA256 context:
            var context = CC_SHA256_CTX()
            CC_SHA256_Init(&context)

            // Read up to `bufferSize` bytes, until EOF is reached, and update SHA256 context:
            while autoreleasepool(invoking: {
                // Read up to `bufferSize` bytes
                let data = file.readData(ofLength: bufferSize)
                if data.count > 0 {
                    data.withUnsafeBytes {
                        _ = CC_SHA256_Update(&context, $0.bindMemory(to: UInt8.self).baseAddress!, numericCast(data.count))
                    }
                    // Continue
                    return true
                } else {
                    // End of file
                    return false
                }
            }) { }

            // Compute the SHA256 digest:
            var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
            digest.withUnsafeMutableBytes {
                _ = CC_SHA256_Final($0.bindMemory(to: UInt8.self).baseAddress!, &context)
            }

            return digest
        } catch {
            print(error)
            return nil
        }
    }

    public struct CheckSum: Codable, Equatable {
        var checkSum: String
        var file: String
    }

    public static func createBundleCheckSum(bundlePath: URL, suffix: String? = nil) -> [CheckSum] {

        var integrity = [CheckSum]()

        let fileManager = FileManager.default
        do {
            let fileUrls = try fileManager.contentsOfDirectory(at:bundlePath, includingPropertiesForKeys: nil)
            for fileURL in fileUrls {
                let fileAttributes = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                if fileAttributes.isRegularFile! {
                    let fileKey = fileURL.absoluteString.replacingOccurrences(of: bundlePath.absoluteString, with: "")

                    if (fileKey == "Info.plist" || fileKey == "main.jsbundle"){
                        NSLog("INTEGRITYCHECK \(fileKey)")
                        //let crcHex = fileData.crc32().toHexString() + (suffix ?? "")
                        //integrity.append(CheckSum(checkSum: String(crcHex), file: String(fileKey)))
                        if let crc = sha256(url: fileURL) {
                            let calculatedHash = crc.map { String(format: "%02hhx", $0) }.joined()
                            NSLog("INTEGRITYCHECK \(calculatedHash)")
                            integrity.append(CheckSum(checkSum: calculatedHash, file: String(fileKey)))
                        }

                    }
                }

            }
        } catch {
            print("Error while enumerating files: \(error.localizedDescription)")
        }

//        if let enumerator = FileManager.default.enumerator(at: bundlePath, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
//            for case let fileURL as URL in enumerator {
//                do {
//                    let fileAttributes = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
//                    if fileAttributes.isRegularFile! {
//
//                        let fileKey = fileURL.absoluteString.replacingOccurrences(of: bundlePath.absoluteString, with: "")
//
//                        if (fileKey != "integrity.txt" && fileKey != "private.key") {
//
//                                //let crcHex = fileData.crc32().toHexString() + (suffix ?? "")
//                                //integrity.append(CheckSum(checkSum: String(crcHex), file: String(fileKey)))
//                                if let crc = sha256(url: fileURL) {
//                                    let calculatedHash = crc.map { String(format: "%02hhx", $0) }.joined()
//                                    integrity.append(CheckSum(checkSum: calculatedHash, file: String(fileKey)))
//                                }
//
//                       }
//                    }
//                } catch {
//                    print(error, fileURL)
//                }
//            }
//        }
        integrity.sort{ $0.file < $1.file }
        print(integrity)
        return integrity
    }

    public static func createIntegrityFile(bundlePath: URL, suffix: String? = nil) -> [CheckSum] {
        //create checksum
        let integrity = createBundleCheckSum(bundlePath: bundlePath, suffix: suffix)
        //create key
        let keyPair = RSAUtils.generateKeyPair()
        //Set filename for integrity data
        let integrityFileUrl = bundlePath.appendingPathComponent("integrity.txt")
        //Set filename for private key
        let privateKeyURL = bundlePath.appendingPathComponent("private.key")
        //convert Data to Json
        let integrityJson = try! JSONEncoder().encode(integrity)
        //encrypt base64 encoded json data
        let integrityEncrypted = Pef2.encrypt(publicKeyPem: keyPair?.publicKey ?? "", data: integrityJson.base64EncodedString())
        //convert encrypted data to Json
        let integrityEncryptedJson = try! JSONEncoder().encode(integrityEncrypted)
        //write encrypted json data to file
        try! integrityEncryptedJson.write(to: integrityFileUrl)
        //write private key to file
        let privateKeyString = keyPair?.privateKey ?? ""
        try! privateKeyString.write(to: privateKeyURL, atomically: false, encoding: .utf8)
        return integrity
    }

    @objc
    public static func checkBundleCheckSum(bundlePath: URL = Bundle.main.bundleURL) -> Bool {
        let currentCheckSum = createBundleCheckSum(bundlePath: bundlePath);
        let integrityFileUrl = bundlePath.appendingPathComponent("integrity.txt")
        let privateKeyPemFileUrl = bundlePath.appendingPathComponent("private.key")
        let decoder = JSONDecoder()
        let integrityJson = try! Data(contentsOf: integrityFileUrl)
        let encryptedOutput = try! decoder.decode(AESUtils.EncryptedOutput.self, from: integrityJson)
        let encryptedBase64 = Pef2.decrypt(privateKeyPem: privateKeyPemFileUrl, encrypted: encryptedOutput)
        let encrypted = Data(base64Encoded: encryptedBase64)
        let bundleCheckSum = try! JSONDecoder().decode([CheckSum].self, from: encrypted!)
        return bundleCheckSum == currentCheckSum
    }

    // Get hash value of Mach-O "__TEXT.__text" data with a specified image target
    static func getMachOFileHashValue(_ target: IntegrityCheckerImageTarget = .default) -> String? {
        switch target {
        case .custom(let imageName):
            return MachOParse(imageName: imageName).getTextSectionDataSHA256Value()
        case .default:
            return MachOParse().getTextSectionDataSHA256Value()
        }
    }
}

// MARK: - MachOParse

private struct SectionInfo {
    var section: UnsafePointer<section_64>
    var addr: UInt64
}

private struct SegmentInfo {
    var segment: UnsafePointer<segment_command_64>
    var addr: UInt64
}

// Convert (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8) to String
@inline(__always)
private func convert16BitInt8TupleToString(int8Tuple: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8)) -> String {
    let mirror = Mirror(reflecting: int8Tuple)

    return mirror.children.map {
                String(UnicodeScalar(UInt8($0.value as! Int8)))
            }.joined().replacingOccurrences(of: "\0", with: "")
}

private class MachOParse {
    private var base: UnsafePointer<mach_header>?
    private var slide: Int?

    init() {
        base    = _dyld_get_image_header(0)
        slide   = _dyld_get_image_vmaddr_slide(0)
    }

    init(header: UnsafePointer<mach_header>, slide: Int) {
        self.base   = header
        self.slide  = slide
    }

    init(imageName: String) {
        for index in 0..<_dyld_image_count() {
            if let cImgName = _dyld_get_image_name(index), String(cString: cImgName).contains(imageName),
               let header  = _dyld_get_image_header(index) {
                self.base   = header
                self.slide  = _dyld_get_image_vmaddr_slide(index)
            }
        }
    }

    private func vm2real(_ vmaddr: UInt64) -> UInt64? {
        guard let slide = slide else {
            return nil
        }

        return UInt64(slide) + vmaddr
    }

    func findLoadedDylibs() -> [String]? {
        guard let header = base else {
            return nil
        }

        guard var curCmd = UnsafeMutablePointer<segment_command_64>(bitPattern: UInt(bitPattern: header) + UInt(MemoryLayout<mach_header_64>.size)) else {
            return nil
        }

        var array: [String] = Array()
        var segCmd: UnsafeMutablePointer<segment_command_64>!

        for _ in 0..<header.pointee.ncmds {
            segCmd = curCmd
            if segCmd.pointee.cmd == LC_LOAD_DYLIB || segCmd.pointee.cmd == LC_LOAD_WEAK_DYLIB {
                if let dylib = UnsafeMutableRawPointer(segCmd)?.assumingMemoryBound(to: dylib_command.self),
                   let cName = UnsafeMutableRawPointer(dylib)?.advanced(by: Int(dylib.pointee.dylib.name.offset)).assumingMemoryBound(to: CChar.self) {
                    let dylibName = String(cString: cName)
                    array.append(dylibName)
                }
            }

            curCmd = UnsafeMutableRawPointer(curCmd).advanced(by: Int(curCmd.pointee.cmdsize)).assumingMemoryBound(to: segment_command_64.self)
        }

        return array
    }

    func findSegment(_ segname: String) -> SegmentInfo? {
        guard let header = base else {
            return nil
        }

        guard var curCmd = UnsafeMutablePointer<segment_command_64>(bitPattern: UInt(bitPattern: header)+UInt(MemoryLayout<mach_header_64>.size)) else {
            return nil
        }

        var segCmd: UnsafeMutablePointer<segment_command_64>!

        for _ in 0..<header.pointee.ncmds {
            segCmd = curCmd
            if segCmd.pointee.cmd == LC_SEGMENT_64 {
                let segName = convert16BitInt8TupleToString(int8Tuple: segCmd.pointee.segname)

                if segname == segName,
                   let vmaddr = vm2real(segCmd.pointee.vmaddr) {
                    let segmentInfo = SegmentInfo(segment: segCmd, addr: vmaddr)
                    return segmentInfo
                }
            }

            curCmd = UnsafeMutableRawPointer(curCmd).advanced(by: Int(curCmd.pointee.cmdsize)).assumingMemoryBound(to: segment_command_64.self)
        }

        return nil
    }

    func findSection(_ segname: String, secname: String) -> SectionInfo? {
        guard let header = base else {
            return nil
        }

        guard var curCmd = UnsafeMutablePointer<segment_command_64>(bitPattern: UInt(bitPattern: header)+UInt(MemoryLayout<mach_header_64>.size)) else {
            return nil
        }

        var segCmd: UnsafeMutablePointer<segment_command_64>!

        for _ in 0..<header.pointee.ncmds {
            segCmd = curCmd
            if segCmd.pointee.cmd == LC_SEGMENT_64 {
                let segName = convert16BitInt8TupleToString(int8Tuple: segCmd.pointee.segname)

                if segname == segName {
                    for sectionID in 0..<segCmd.pointee.nsects {
                        guard let sect = UnsafeMutablePointer<section_64>(bitPattern: UInt(bitPattern: curCmd) + UInt(MemoryLayout<segment_command_64>.size) + UInt(sectionID)) else {
                            return nil
                        }

                        let secName = convert16BitInt8TupleToString(int8Tuple: sect.pointee.sectname)

                        if secName == secname,
                           let addr = vm2real(sect.pointee.addr) {
                            let sectionInfo = SectionInfo(section: sect, addr: addr)
                            return sectionInfo
                        }
                    }
                }
            }

            curCmd = UnsafeMutableRawPointer(curCmd).advanced(by: Int(curCmd.pointee.cmdsize)).assumingMemoryBound(to: segment_command_64.self)
        }

        return nil
    }

    func getTextSectionDataSHA256Value() -> String? {
        guard let sectionInfo = findSection(SEG_TEXT, secname: SECT_TEXT) else {
            return nil
        }

        guard let startAddr = UnsafeMutablePointer<Any>(bitPattern: Int(sectionInfo.addr)) else {
            return nil
        }

        let size = sectionInfo.section.pointee.size

        // Hash: SHA256
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = CC_SHA256(startAddr, CC_LONG(size), &hash)

        return Data(hash).hexEncodedString()
    }
}

extension Data {
    fileprivate func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}


