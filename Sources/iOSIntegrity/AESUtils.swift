//
// Created by Thomas Hoppe on 31/8/2022 AD.
//

import Foundation
import CryptoSwift

public struct AESUtils {

    public struct EncryptedOutput : Codable {
        var cipher: String
        var iv: String
        var key: String
    }

    public static func encrypt(data: String) -> EncryptedOutput {
        let password = [UInt8](repeating: 0, count: 16)
        let salt = [UInt8](repeating: 0, count: 16)
        /* Generate a key from a `password`. Optional if you already have a key */
        let key = try! PKCS5.PBKDF2(
                password: password,
                salt: salt,
                iterations: 4096,
                keyLength: 32, /* AES-256 */
                variant: .sha2(SHA2.Variant.sha256)
        ).calculate()

        /* Generate random IV value. IV is public value. Either need to generate, or get it from elsewhere */
        let iv = AES.randomIV(AES.blockSize)

        /* AES cryptor instance */
        let aes = try! AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7)
        let encryptedBytes = try! aes.encrypt(data.bytes)

        let output = EncryptedOutput(cipher: Data(encryptedBytes).base64EncodedString(),
                iv: Data(iv).base64EncodedString(),
                key: Data(key).base64EncodedString())
        return output
    }

    public static func decrypt(encrypted: EncryptedOutput) -> String {

        let iv = Data(base64Encoded: encrypted.iv)?.bytes
        let key = Data(base64Encoded: encrypted.key)?.bytes
        let cipher = Data(base64Encoded: encrypted.cipher)?.bytes

        /* AES cryptor instance */
        let aes = try! AES(key: key!, blockMode: CBC(iv: iv!), padding: .pkcs7)
        let decryptedBytes = try! aes.decrypt(cipher!)
        let decryptedData = Data(decryptedBytes)
        return String(decoding: decryptedData, as: UTF8.self)
    }
}