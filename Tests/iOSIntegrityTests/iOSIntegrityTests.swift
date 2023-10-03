import XCTest
@testable import iOSIntegrity
final class iOSIntegrityTests: XCTestCase {

    func testRSA() throws {
        let publicKeyPem = URL.init(fileURLWithPath: "/Users/thomas/Projects/react-native/reactNativeTemplate/keys/public.pem")
        let cipherBase64 = RSAUtils.encrypt(publicKeyPem: publicKeyPem, message: "test123")
        debugPrint(cipherBase64)

        let privateKeyPem = URL.init(fileURLWithPath: "/Users/thomas/Projects/react-native/reactNativeTemplate/keys/private.pem")
        let plain = RSAUtils.decrypt(privateKeyPem: privateKeyPem, base64Cipher: cipherBase64)
        debugPrint(plain)

        XCTAssertEqual(plain, "test123")
    }

    func testPef2() throws {
        let publicKeyPem = URL.init(fileURLWithPath: "/Users/thomas/Projects/react-native/reactNativeTemplate/keys/public.pem")
        let aesEncrypted = Pef2.encrypt(publicKeyPem: publicKeyPem, data: "test1234")
        debugPrint(aesEncrypted)

        let privateKeyPem = URL.init(fileURLWithPath: "/Users/thomas/Projects/react-native/reactNativeTemplate/keys/private.pem")
        let plain = Pef2.decrypt(privateKeyPem: privateKeyPem, encrypted: aesEncrypted)
        debugPrint(plain)

        XCTAssertEqual(plain, "test1234")
    }

    func testPef2WithString() throws {
        let keyPair = RSAUtils.generateKeyPair()

        let aesEncrypted = Pef2.encrypt(publicKeyPem: keyPair?.publicKey ?? "", data: "test1234")
        debugPrint(aesEncrypted)

        let plain = Pef2.decrypt(privateKeyPem: keyPair?.privateKey ?? "", encrypted: aesEncrypted)
        debugPrint(plain)

        XCTAssertEqual(plain, "test1234")
    }

    func testAES() throws {
        let publicKeyPem = URL.init(fileURLWithPath: "/Users/thomas/Projects/react-native/reactNativeTemplate/keys/public.pem")
        let cipherBase64 = RSAUtils.encrypt(publicKeyPem: publicKeyPem, message: "test123")
        debugPrint(cipherBase64)

        let privateKeyPem = URL.init(fileURLWithPath: "/Users/thomas/Projects/react-native/reactNativeTemplate/keys/private.pem")
        let plain = RSAUtils.decrypt(privateKeyPem: privateKeyPem, base64Cipher: cipherBase64)
        debugPrint(plain)

        XCTAssertEqual(plain, "test123")
    }

    func testCreateBundleCheckSum() throws {
        let bundlePath = URL.init(fileURLWithPath: "/Users/thomas/Library/Developer/Xcode/Archives/2565-09-01/kerry_wallet_dev 1-9-2565 BE 15.16.xcarchive/Products/Applications/kerry_wallet.app")
        let checkSum = iOSIntegrity.createBundleCheckSum(bundlePath: bundlePath)
        XCTAssertEqual(checkSum.count, 2)
    }

    func testGenerateKeyPair() throws {
       let key = RSAUtils.generateKeyPair()
        debugPrint(key)
        XCTAssertNotNil(key)
    }

    func testRSAWithGenerateKeyPair() throws {

        let keyPair = RSAUtils.generateKeyPair()

        let cipherBase64 = RSAUtils.encrypt(publicKeyPem: keyPair?.publicKey ?? "", message: "test123")
        debugPrint(cipherBase64)

        let plain = RSAUtils.decrypt(privateKeyPem: keyPair?.privateKey ?? "", base64Cipher: cipherBase64)
        debugPrint(plain)

        XCTAssertEqual(plain, "test123")
    }

    func testCreateIntegrityFile() throws {

        let bundlePath = URL.init(fileURLWithPath: "/Users/thomas/Library/Developer/Xcode/Archives/2565-09-01/kerry_wallet_dev 1-9-2565 BE 15.16.xcarchive/Products/Applications/kerry_wallet.app")

        let integrityFilePath = bundlePath.appendingPathComponent("integrity.txt")
        do {
            try FileManager.default.removeItem(at: integrityFilePath)
            print("TEST - Integrity file has been deleted")
        } catch {
            print(error)
        }

        let keyPath = bundlePath.appendingPathComponent("private.key")
        do {
            try FileManager.default.removeItem(at: keyPath)
            print("TEST - Private key file has been deleted")
        } catch {
            print(error)
        }

        let checkSum = iOSIntegrity.createIntegrityFile(bundlePath: bundlePath)
        let isExistInterityFile = (try integrityFilePath.resourceValues(forKeys: [.isRegularFileKey])).isRegularFile
        let isExistPrivateKeyFile = (try integrityFilePath.resourceValues(forKeys: [.isRegularFileKey])).isRegularFile



        XCTAssertEqual(checkSum.count, 2)
        XCTAssertEqual(isExistInterityFile, true)
        XCTAssertEqual(isExistPrivateKeyFile, true)
    }

    func testCheckBundleCheckSum() throws {

        let bundlePath = URL.init(fileURLWithPath: "/Users/thomas/Library/Developer/Xcode/Archives/2565-09-01/kerry_wallet_dev 1-9-2565 BE 15.16.xcarchive/Products/Applications/kerry_wallet.app")
        let checkSum: Bool = iOSIntegrity.checkBundleCheckSum(bundlePath: bundlePath)
        XCTAssertEqual(checkSum, true)
    }

    func testCreateBundleCheckSumWithOffset() throws {
        let bundlePath = URL.init(fileURLWithPath: "/Users/thomas/Library/Developer/Xcode/Archives/2565-09-01/kerry_wallet_dev 1-9-2565 BE 15.16.xcarchive/Products/Applications/kerry_wallet.app")
        let checkSum = iOSIntegrity.createBundleCheckSum(bundlePath: bundlePath, suffix: "a")
        XCTAssertEqual(checkSum.count, 2)

    }

    func testRSASignature() throws {

        let privateKeyPem = URL.init(fileURLWithPath: "/Users/thomas/Projects/react-native/reactNativeTemplate/keys/private.pem")
        let signature = RSAUtils.sign(message: "Test", privateKeyPem: privateKeyPem)
        debugPrint(signature)
    }
}


