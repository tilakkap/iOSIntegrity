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
                        NSLog("INTEGRITYCHECK \(fileKey)")
                        if let crc = sha256(url: fileURL) {
                            let calculatedHash = crc.map {
                                        String(format: "%02hhx", $0)
                                    }
                                    .joined()
                            NSLog("INTEGRITYCHECK \(calculatedHash)")
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
        print(integrity)
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
        let plistCheck = checkPlist(template: templateUrl, bundle: bundlePath.appendingPathComponent("Info.plist") )
        if plistCheck == false {
            return plistCheck
        }
        let currentCheckSum = createBundleCheckSum(bundlePath: bundlePath, machoHash: machoCheckSum!);
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

    public static func checkPlist(template: URL, bundle: URL = Bundle.main.bundleURL) -> Bool {
        let templatePlist = iOSIntegrity.getInfoPlist(url: template);
        let bundlePlist = iOSIntegrity.getInfoPlist(url: bundle);

        for (key, value) in templatePlist! {
            if ((bundlePlist?[key] as AnyObject).description != (value as AnyObject).description) {
                return false
            }
        }
        return true
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