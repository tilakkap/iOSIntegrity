//
//  FileUtils.swift
//  integrity
//
//  Created by Thomas Hoppe on 3/4/2565 BE.
//

import Foundation
import CryptoSwift

public struct iOSIntegrity {

    public struct CheckSum: Codable, Equatable {
        var checkSum: String
        var file: String
    }

    public static func createBundleCheckSum(bundlePath: URL) -> [CheckSum]  {

        var integrity = [CheckSum]()

        if let enumerator = FileManager.default.enumerator(at: bundlePath, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                for case let fileURL as URL in enumerator {
                    do {
                        let fileAttributes = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                        if fileAttributes.isRegularFile! {

                            let exname: String = (fileURL.pathExtension)

                                let fileKey = fileURL.absoluteString.replacingOccurrences(of: bundlePath.absoluteString, with: "")

                                if(fileKey == "Info.plist" || fileKey == "main.jsbundle"){
                                    if let fileData = try? Data(contentsOf: fileURL) {
                                        debugPrint(String(fileKey))
                                        let crcHex = fileData.crc32().toHexString()
                                        debugPrint(crcHex)
                                        integrity.append(CheckSum(checkSum: String(crcHex), file: String(fileKey)))
                                    }
                                }
                        }
                    } catch {
                        print(error, fileURL)
                    }
                }
            }
            return integrity
    }

    public static func createIntegrityFile(bundlePath: URL) -> [CheckSum] {
        //create checksum
        let integrity = createBundleCheckSum(bundlePath: bundlePath)
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



