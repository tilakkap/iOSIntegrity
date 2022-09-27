//
//  FileUtils.swift
//  integrity
//
//  Created by Thomas Hoppe on 3/4/2565 BE.
//

import Foundation
import CommonCrypto

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
            }) {
            }

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

    public static func createBundleCheckSum(bundlePath: URL, machoHash: String) -> [CheckSum] {

        var integrity = [CheckSum]()

        let fileManager = FileManager.default
        do {
            let fileUrls = try fileManager.contentsOfDirectory(at: bundlePath, includingPropertiesForKeys: nil)
            for fileURL in fileUrls {
                let fileAttributes = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                if fileAttributes.isRegularFile! {
                    let fileKey = fileURL.absoluteString.replacingOccurrences(of: bundlePath.absoluteString, with: "")

                    if (fileKey == "main.jsbundle" ||  fileKey ==  "templ.plist") {

                        if let crc = sha256(url: fileURL) {
                            let calculatedHash = crc.map {
                                        String(format: "%02hhx", $0)
                                    }
                                    .joined()

                            integrity.append(CheckSum(checkSum: calculatedHash, file: String(fileKey)))
                        }
                    }
                }

            }
            integrity.append(CheckSum(checkSum: machoHash, file: "executable"))
        } catch {
            print("Error while enumerating files: \(error.localizedDescription)")
        }
        integrity.sort {
            $0.file < $1.file
        }
        NSLog("INTEGRITYCHECK \(integrity)")
        print("INTEGRITYCHECK \(integrity)")
        return integrity
    }

    public static func createIntegrityFile(bundlePath: URL, machoHash: String) -> [CheckSum] {

        //create checksum
        let integrity = createBundleCheckSum(bundlePath: bundlePath, machoHash: machoHash)
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
        let templateUrl = bundlePath.appendingPathComponent("templ.plist")
        let machoCheckSum = MachOParse().getTextSectionDataSHA256Value()
        NSLog("MachoCheckSum:\(machoCheckSum)")
        let currentCheckSum = createBundleCheckSum(bundlePath: bundlePath, machoHash: machoCheckSum!);
        NSLog("CURRENT CHECKSUM:\(currentCheckSum)")
        let integrityFileUrl = bundlePath.appendingPathComponent("integrity.txt")
        let privateKeyPemFileUrl = bundlePath.appendingPathComponent("private.key")
        let decoder = JSONDecoder()
        let integrityJson = try! Data(contentsOf: integrityFileUrl)
        let encryptedOutput = try! decoder.decode(AESUtils.EncryptedOutput.self, from: integrityJson)
        let encryptedBase64 = Pef2.decrypt(privateKeyPem: privateKeyPemFileUrl, encrypted: encryptedOutput)
        let encrypted = Data(base64Encoded: encryptedBase64)
        let bundleCheckSum = try! JSONDecoder().decode([CheckSum].self, from: encrypted!)
        NSLog("BUNDLE CHECKSUM:\(bundleCheckSum)")
        return bundleCheckSum == currentCheckSum
    }

    public static func getInfoPlist(url: URL = Bundle.main.bundleURL.appendingPathComponent("Info.plist")) -> NSDictionary? {
        let plist = NSDictionary(contentsOf: url);
        let data = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        let str = String(decoding: data, as: UTF8.self)
        let components = str.components(withMaxLength: 1000)

        for (index, component) in components.enumerated() {
            NSLog("PLIST\(index):\(component)")
        }
        return plist
    }

    public static func checkPlist(template: URL, OSVersion: String, models: Array<String>) -> Bool {
        let templatePlist = iOSIntegrity.getInfoPlist(url: template);
        return true
    }

    public static func getModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    @objc static func isFridaRunning() -> Bool {
        func swapBytesIfNeeded(port: in_port_t) -> in_port_t {
            let littleEndian = Int(OSHostByteOrder()) == OSLittleEndian
            return littleEndian ? _OSSwapInt16(port) : port
        }

        var serverAddress = sockaddr_in()
        serverAddress.sin_family = sa_family_t(AF_INET)
        serverAddress.sin_addr.s_addr = inet_addr("127.0.0.1")
        serverAddress.sin_port = swapBytesIfNeeded(port: in_port_t(27042))
        let sock = socket(AF_INET, SOCK_STREAM, 0)

        let result = withUnsafePointer(to: &serverAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.stride))
            }
        }
        if result != -1 {
            return true
        }
        return false
    }

    @objc static func checkDYLD() -> Bool {
        let suspiciousLibraries = [
            "FridaGadget",
            "frida",
            "cynject",
            "libcycript"
        ]
        for libraryIndex in 0..<_dyld_image_count() {

            guard let loadedLibrary = String(validatingUTF8: _dyld_get_image_name(libraryIndex)) else { continue }
            for suspiciousLibrary in suspiciousLibraries {
                if loadedLibrary.lowercased().contains(suspiciousLibrary.lowercased()) {
                    return true
                }
            }
        }
        return false
    }

}


extension String {
    func components(withMaxLength length: Int) -> [String] {
        return stride(from: 0, to: self.count, by: length).map {
            let start = self.index(self.startIndex, offsetBy: $0)
            let end = self.index(start, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            return String(self[start..<end])
        }
    }
}

//iPhone1,1 : iPhone
//iPhone1,2 : iPhone 3G
//iPhone2,1 : iPhone 3GS
//iPhone3,1 : iPhone 4
//iPhone3,2 : iPhone 4 GSM Rev A
//iPhone3,3 : iPhone 4 CDMA
//iPhone4,1 : iPhone 4S
//iPhone5,1 : iPhone 5 (GSM)
//iPhone5,2 : iPhone 5 (GSM+CDMA)
//iPhone5,3 : iPhone 5C (GSM)
//iPhone5,4 : iPhone 5C (Global)
//iPhone6,1 : iPhone 5S (GSM)
//iPhone6,2 : iPhone 5S (Global)
//iPhone7,1 : iPhone 6 Plus
//iPhone7,2 : iPhone 6
//iPhone8,1 : iPhone 6s
//iPhone8,2 : iPhone 6s Plus
//iPhone8,4 : iPhone SE (GSM)
//iPhone9,1 : iPhone 7
//iPhone9,2 : iPhone 7 Plus
//iPhone9,3 : iPhone 7
//iPhone9,4 : iPhone 7 Plus
//iPhone10,1 : iPhone 8
//iPhone10,2 : iPhone 8 Plus
//iPhone10,3 : iPhone X Global
//iPhone10,4 : iPhone 8
//iPhone10,5 : iPhone 8 Plus
//iPhone10,6 : iPhone X GSM
//iPhone11,2 : iPhone XS
//iPhone11,4 : iPhone XS Max
//iPhone11,6 : iPhone XS Max Global
//iPhone11,8 : iPhone XR
//iPhone12,1 : iPhone 11
//iPhone12,3 : iPhone 11 Pro
//iPhone12,5 : iPhone 11 Pro Max
//iPhone12,8 : iPhone SE 2nd Gen
//iPhone13,1 : iPhone 12 Mini
//iPhone13,2 : iPhone 12
//iPhone13,3 : iPhone 12 Pro
//iPhone13,4 : iPhone 12 Pro Max
//iPhone14,2 : iPhone 13 Pro
//iPhone14,3 : iPhone 13 Pro Max
//iPhone14,4 : iPhone 13 Mini
//iPhone14,5 : iPhone 13
//iPhone14,6 : iPhone SE 3rd Gen
//iPhone14,7 : iPhone 14
//iPhone14,8 : iPhone 14 Plus
//iPhone15,2 : iPhone 14 Pro
//iPhone15,3 : iPhone 14 Pro Max
