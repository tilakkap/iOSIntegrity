//
//  Pef2.swift
//  integrity
//
//  Created by Thomas Hoppe on 9/4/2565 BE.
//

import Foundation

public struct Pef2 {

    public static func encrypt(publicKeyPem: URL, data: String) -> AESUtils.EncryptedOutput {
        var aesEncrypted = AESUtils.encrypt(data: data)
        aesEncrypted.key = RSAUtils.encrypt(publicKeyPem: publicKeyPem, message: aesEncrypted.key)
        return aesEncrypted
    }

    public static func encrypt(publicKeyPem: String, data: String) -> AESUtils.EncryptedOutput {
        var aesEncrypted = AESUtils.encrypt(data: data)
        aesEncrypted.key = RSAUtils.encrypt(publicKeyPem: publicKeyPem, message: aesEncrypted.key)
        return aesEncrypted
    }

    public static func decrypt(privateKeyPem: URL, encrypted: AESUtils.EncryptedOutput) -> String {
        var encrypted = encrypted
        encrypted.key = RSAUtils.decrypt(privateKeyPem: privateKeyPem, base64Cipher: encrypted.key)
        return AESUtils.decrypt(encrypted: encrypted)
    }

    public static func decrypt(privateKeyPem: String, encrypted: AESUtils.EncryptedOutput) -> String {
        var encrypted = encrypted
        encrypted.key = RSAUtils.decrypt(privateKeyPem: privateKeyPem, base64Cipher: encrypted.key)
        return AESUtils.decrypt(encrypted: encrypted)
    }
}