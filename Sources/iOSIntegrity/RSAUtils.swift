//
// Created by Thomas Hoppe on 31/8/2022 AD.
//

import Foundation
import CryptoKit

public struct RSAUtils {

    public struct KeyPair: Codable {
        var privateKey: String
        var publicKey: String
    }

    public static func encrypt(publicKeyPem: URL, message: String) -> String {
        do {
            let publicKeyPemString = try String(contentsOf: publicKeyPem, encoding: .utf8)
            return self.encrypt(publicKeyPem: publicKeyPemString, message: message)
        } catch {
            print("error encrypt")
            return ""
        }

    }

    public static func encrypt(publicKeyPem: String, message: String) -> String {

        let keyString = publicKeyPem
                .replacingOccurrences(
                        of: "-----BEGIN PUBLIC KEY-----\n",
                        with: "")
                .replacingOccurrences(
                        of: "\n-----END PUBLIC KEY-----",
                        with: "")
                .replacingOccurrences(
                        of: "\n",
                        with: "")
        let keyBytes = Data(base64Encoded: keyString)! as CFData
        let attributes = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits: 2048,
            kSecAttrKeyClass: kSecAttrKeyClassPublic
        ] as CFDictionary

        var error: Unmanaged<CFError>?
        let publicKey = SecKeyCreateWithData(keyBytes, attributes, &error)!
        let message = Data(message.utf8)
        let ciphertext = SecKeyCreateEncryptedData(publicKey, .rsaEncryptionPKCS1, message as CFData, &error)! as Data

        let base64String = ciphertext.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        return base64String
    }

    public static func decrypt(privateKeyPem: URL, base64Cipher: String) -> String {
        do {
            let privateKeyPemString = try String(contentsOf: privateKeyPem, encoding: .utf8)
            return self.decrypt(privateKeyPem: privateKeyPemString, base64Cipher: base64Cipher)
        } catch {
            print("error decrypt")
            return ""
        }


    }

    public static func decrypt(privateKeyPem: String, base64Cipher: String) -> String {

        let keyString = privateKeyPem
                .replacingOccurrences(
                        of: "-----BEGIN RSA PRIVATE KEY-----\n",
                        with: "")
                .replacingOccurrences(
                        of: "\n-----END RSA PRIVATE KEY-----",
                        with: "")
                .replacingOccurrences(
                        of: "\n",
                        with: "")
        let keyBytes = Data(base64Encoded: keyString)! as CFData
        let attributes = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits: 2048,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate
        ] as CFDictionary

        var error: Unmanaged<CFError>?
        let privateKey = SecKeyCreateWithData(keyBytes, attributes, &error)!

        let cipherText = Data(base64Encoded: base64Cipher)!

        let plainTextData = SecKeyCreateDecryptedData(privateKey, .rsaEncryptionPKCS1, cipherText as CFData, &error)! as Data
        let plainText = String(data: plainTextData, encoding: .utf8) ?? "Non UTF8"
        return plainText
    }

    public static func generateKeyPair() -> KeyPair? {

        let tag = "".data(using: .utf8)!
        let attributes: [String: Any] = [
            kSecAttrType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag
            ]
        ]
        var error: Unmanaged<CFError>?
        let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error)
        let publicKey = SecKeyCopyPublicKey(privateKey!)

        guard let pubKeyRep = SecKeyCopyExternalRepresentation(publicKey!, &error) as Data? else {
            // Handle error
            return nil
        }
        let pubKeyBase64Encoded = pubKeyRep.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])

        guard let privateKeyRep = SecKeyCopyExternalRepresentation(privateKey!, &error) as Data? else {
            // Handle error
            return nil
        }
        let privateKeyBase64Encoded = privateKeyRep.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])

        return KeyPair(privateKey: [
            "-----BEGIN RSA PRIVATE KEY-----",
            privateKeyBase64Encoded,
            "-----END RSA PRIVATE KEY-----"
        ].joined(separator: "\n"), publicKey: [
            "-----BEGIN PUBLIC KEY-----",
            pubKeyBase64Encoded,
            "-----END PUBLIC KEY-----"
        ].joined(separator: "\n"))
    }

}
