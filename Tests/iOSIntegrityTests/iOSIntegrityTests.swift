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
        let expected = "97833f8d98a1b99ff59e717adb9a2e91509197ef60ad317b04206b73e2fdc5b2"
        let bundlePath = URL.init(fileURLWithPath: "/Users/pakdee.p/Library/Developer/Xcode/Archives/2566-10-24/kerry_wallet_UAT 24-10-2566 BE 14.23.xcarchive/Products/Applications/kerry_wallet.app")
        let checkSum = iOSIntegrity.createBundleCheckSum(bundlePath: bundlePath,version: "1.1.0",build: "224")
        XCTAssertEqual(checkSum, expected)
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
        let expected = "0a90c7fd169991bd75c30a488f531141c5657e250f0b5ea89cb3086edf1db2d2"
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

        let checkSum = iOSIntegrity.createIntegrityFile(bundlePath: bundlePath,version: "1.0.0",build: "100")
        XCTAssertEqual(checkSum, expected)
    }

    func testCheckBundleCheckSum() throws {

        let ck = "97833f8d98a1b99ff59e717adb9a2e91509197ef60ad317b04206b73e2fdc5b2"
        let bundlePath = URL.init(fileURLWithPath: "/Users/pakdee.p/Library/Developer/Xcode/Archives/2566-10-24/kerry_wallet_UAT 24-10-2566 BE 20.06.xcarchive/Products/Applications/kerry_wallet.app")
        let checkSum: Bool = iOSIntegrity.checkBundleCheckSum(bundlePath: bundlePath,version: "1.1.0",build: "224",dataCheck: ck)
        XCTAssertEqual(checkSum, true)
    }

    func testCreateBundleCheckSumWithOffset() throws {
        let expected = "97833f8d98a1b99ff59e717adb9a2e91509197ef60ad317b04206b73e2fdc5b2"
        let bundlePath = URL.init(fileURLWithPath: "/Users/pakdee.p/Library/Developer/Xcode/Archives/2566-10-24/kerry_wallet_UAT 24-10-2566 BE 14.23.xcarchive/Products/Applications/kerry_wallet.app")
        let checkSum = iOSIntegrity.createBundleCheckSum(bundlePath: bundlePath,version: "1.1.0",build: "224")
        XCTAssertEqual(checkSum, expected)

    }
    func testPostIntegrity() {

            // An expectation for finishing the network call
            let expectation = self.expectation(description: "Request should succeed")


            //let token = "YOUR_BEARER_TOKEN"

            let parameters: [String: Any] = [
                "merchant_id": "M14",
                "type": "app_integrity",
                "data": [
                    "builds":
                        [
                           [ "app_id": "kex_app",
                            "version": "1.1.0",
                            "build": "214",
                            "integrity": "",
                             "os": "ios"
                           ]
                        ],

                   
                    
                ]
            ]


        let endpoint = "https://api-uat.vdc.co.th/merchant/v1/setting?mode=add&property=builds"
        let token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoia2V4LW1vYmlsZS1hcHAiLCJ0eXBlIjoic2l0ZSIsImVudGl0eSI6WyJLRVgiXSwiaWF0IjoxNjk4MjE4MzQ4LCJpc3MiOiJzYWJ1eXRlY2guY29tIn0.296KkzqtQSB3vAMM8-Or5wFSFK_O2B848zOpxS8o1yHqb3bX74Fq28lW-tYZVyToi7AUEH28w559I0SUJIknHYqynCtDI-BDkUr6LfylQEjNbvnFC_f0ii-nD5TDpz9BEiQnJtIHaSAtHVnAfJ1U6gRJWF5kNlT03myJiZc_ZGyvrzK1oAVb5PtZx9kGYENu8NcrRAh1S15HyhQu3-6Q0k8j2pNY4VvGMERGDC6953O1Xq-NdLBWZ8bei18e-_RxddNPNJdR3hitmzjSsZfah0pj1EDgEQJbsBdhfYd_QMy4XdfOfLTND7E9y2j6zB_EGNW3joyUCK5WjNuDfvtw1g"
        
        

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


