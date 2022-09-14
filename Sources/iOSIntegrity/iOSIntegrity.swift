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

                    if (fileKey != "integrity.txt" && fileKey != "private.key") {
                        debugPrint(fileKey)

                        //let crcHex = fileData.crc32().toHexString() + (suffix ?? "")
                        //integrity.append(CheckSum(checkSum: String(crcHex), file: String(fileKey)))
                        if let crc = sha256(url: fileURL) {
                            let calculatedHash = crc.map { String(format: "%02hhx", $0) }.joined()
                            debugPrint(calculatedHash)
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
}



