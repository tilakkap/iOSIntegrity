import XCTest
@testable import iOSIntegrity
final class iOSIntegrityTests: XCTestCase {

    func testRSA() throws {
        let publicKeyPem = URL.init(fileURLWithPath: "/Users/pakdee.p/public.pem")
        let cipherBase64 = RSAUtils.encrypt(publicKeyPem: publicKeyPem, message: "test123")
        debugPrint(cipherBase64)

        let privateKeyPem = URL.init(fileURLWithPath: "/Users/pakdee.p/private.pem")
        let plain = RSAUtils.decrypt(privateKeyPem: privateKeyPem, base64Cipher: cipherBase64)
        debugPrint(plain)

        XCTAssertEqual(plain, "test123")
    }

    func testPef2() throws {
        let publicKeyPem = URL.init(fileURLWithPath: "/Users/pakdee.p/public.pem")
        let aesEncrypted = Pef2.encrypt(publicKeyPem: publicKeyPem, data: "test1234")
        debugPrint(aesEncrypted)

        let privateKeyPem = URL.init(fileURLWithPath: "/Users/pakdee.p/private.pem")
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
        let publicKeyPem = URL.init(fileURLWithPath: "/Users/pakdee.p/public.pem")
        let cipherBase64 = RSAUtils.encrypt(publicKeyPem: publicKeyPem, message: "test123")
        debugPrint(cipherBase64)

        let privateKeyPem = URL.init(fileURLWithPath: "/Users/pakdee.p/private.pem")
        let plain = RSAUtils.decrypt(privateKeyPem: privateKeyPem, base64Cipher: cipherBase64)
        debugPrint(plain)

        XCTAssertEqual(plain, "test123")
    }

    func testCreateBundleCheckSum() throws {
        let bundlePath = URL.init(fileURLWithPath: "/Users/pakdee.p/Library/Developer/Xcode/Archives/2566-10-24/kerry_wallet_UAT 24-10-2566 BE 14.23.xcarchive/Products/Applications/kerry_wallet.app")
        let checkSum = iOSIntegrity.createBundleCheckSum(bundlePath: bundlePath,version: "1.1.0",build: "224")
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

        let bundlePath = URL.init(fileURLWithPath: "/Users/pakdee.p/Library/Developer/Xcode/Archives/2566-10-04/kerry_wallet_UAT 4-10-2566 BE 14.46.xcarchive/Products/Applications/kerry_wallet.app")

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

        let checkSum = iOSIntegrity.createIntegrityFile(bundlePath: bundlePath,version: "1.1.0",build: "218")
        XCTAssertEqual(checkSum.count, 2)
    }

    func testCheckBundleCheckSum() throws {

        let ck = "[{\"checkSum\":\"bb8ce668b14a98cf4a06b2291d440c07fd5234b8948dc7c1df5c72606f0214f1\",\"build\":\"223\",\"file\":\"Info.plist\",\"version\":\"1.1.0\"},{\"checkSum\":\"97833f8d98a1b99ff59e717adb9a2e91509197ef60ad317b04206b73e2fdc5b2\",\"build\":\"223\",\"file\":\"main.jsbundle\",\"version\":\"1.1.0\"}]"
        let bundlePath = URL.init(fileURLWithPath: "/Users/pakdee.p/Library/Developer/Xcode/Archives/2566-10-24/kerry_wallet_UAT 24-10-2566 BE 14.23.xcarchive/Products/Applications/kerry_wallet.app")
        let checkSum: Bool = iOSIntegrity.checkBundleCheckSum(bundlePath: bundlePath,version: "1.1.0",build: "224",dataCheck: ck)
        XCTAssertEqual(checkSum, true)
    }

    func testCreateBundleCheckSumWithOffset() throws {
        let bundlePath = URL.init(fileURLWithPath: "/Users/pakdee.p/Library/Developer/Xcode/Archives/2566-10-24/kerry_wallet_UAT 24-10-2566 BE 14.23.xcarchive/Products/Applications/kerry_wallet.app")
        let checkSum = iOSIntegrity.createBundleCheckSum(bundlePath: bundlePath,version: "1.1.0",build: "224")
        XCTAssertEqual(checkSum.count, 2)

    }
    func testPostIntegrity() {

            // An expectation for finishing the network call
            let expectation = self.expectation(description: "Request should succeed")


            //let token = "YOUR_BEARER_TOKEN"

            let parameters: [String: Any] = [
                "merchant_id": "M12846",
                "type": "app_integrity",
                "data": [
                    "builds":
                        [
                           [ "app_id": "kex_app",
                            "version": "1.1.0",
                            "build": "214",
                            "integrity": [
                                "plist": "json"
                            ],
                             "os": "ios"
                           ]
                        ],

                   
                    
                ]
            ]


        let endpoint = "https://api-test.vdc.co.th/merchant/v1/setting?mode=add&property=builds"
        let token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoia2V4LW1vYmlsZS1hcHAiLCJ0eXBlIjoic2l0ZSIsImVudGl0eSI6WyJLRVgiXSwiaWF0IjoxNjk3NTMyMzU1LCJpc3MiOiJzYWJ1eXRlY2guY29tIn0.uQXNw1SuN9-hzELY4Y85UABuLvzKUFQldVgrghxxYPuukvwkSPptBPv7ZJQwTdp1yOQXR2Jig5650mxpqHQ0pFeKTGYPQv9w_qt3QnNxOh7syEClwsKeW8fFrBA3f856irmAEFOFE-FJBo7xfWd0flZsxBZGxqiz2DMUEBftsFcf2MzLHV3xVlAy6Y1DqchM2A4VmtrC4zEovHW4sq4BkJ3ilN6SorqchPp5tLNnbmswFLH6wAny5gUmOBUy996ENrUKTcSXTEvThFiktSKd5EG5gslUOonnGN7c5AjAFokES1SK32-GpggtqELGeAIBfu3seg9d7UQWHh0lFeD6Zw"
        
        

        iOSIntegrity.patchData(with: endpoint, parameters: parameters, token: token) { result in
                switch result {
                case .success(let data):
                    XCTAssertNotNil(data, "Data should not be nil")
                    print(data)
                        // Further assertions based on expected response
                case .failure(let error):
                    print("error= \(error)")
                    XCTFail("Request failed with error: \(error)")
                }
                expectation.fulfill()
            }
            // Wait for the expectation to be fulfilled
            waitForExpectations(timeout: 10) { error in
                if let error = error {
                    XCTFail("waitForExpectations error: \(error)")
                }
            }
        }
}


