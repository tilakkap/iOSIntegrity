//
// Created by Thomas Hoppe on 31/8/2022 AD.
//
import Foundation

public struct RSAUtils {

    public static func encrypt(publicKeyPem: URL, message: String) -> String {
        do {
            let publickKeyPemString = try String(contentsOf: publicKeyPem, encoding: .utf8)

            let keyString = publickKeyPemString
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
        } catch {
            print("error encrypt")
            return ""
        }

    }

    public static func decrypt(privateKeyPem: URL, base64Cipher: String) -> String {
        do {
            let privateKeyPemString = try String(contentsOf: privateKeyPem, encoding: .utf8)
            let keyString = privateKeyPemString
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
        } catch {
            print("error decrypt")
            return ""
        }


    }

}
