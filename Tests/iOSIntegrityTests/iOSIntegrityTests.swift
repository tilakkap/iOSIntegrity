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

    func testAES() throws {
        let publicKeyPem = URL.init(fileURLWithPath: "/Users/thomas/Projects/react-native/reactNativeTemplate/keys/public.pem")
        let cipherBase64 = RSAUtils.encrypt(publicKeyPem: publicKeyPem, message: "test123")
        debugPrint(cipherBase64)

        let privateKeyPem = URL.init(fileURLWithPath: "/Users/thomas/Projects/react-native/reactNativeTemplate/keys/private.pem")
        let plain = RSAUtils.decrypt(privateKeyPem: privateKeyPem, base64Cipher: cipherBase64)
        debugPrint(plain)

        XCTAssertEqual(plain, "test123")
    }

    func testCreateBundleFile() throws {
        let bundlePath = URL.init(fileURLWithPath: "/Users/thomas/Library/Developer/Xcode/Archives/2565-09-01/kerry_wallet_dev 1-9-2565 BE 15.16.xcarchive/Products/Applications/kerry_wallet.app")
        let expectation = expectation(description: "SomeService does stuff and runs the callback closure")


        iOSIntegrity.createBundleCheckSum(bundlePath: bundlePath, completion: { (result) -> () in
            // do stuff with the result
            expectation.fulfill()
            debugPrint(result)
            XCTAssertEqual(result.count, 2)

        })
        waitForExpectations(timeout: 30)

    }

}
