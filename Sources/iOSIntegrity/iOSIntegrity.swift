//
//  FileUtils.swift
//  integrity
//
//  Created by Thomas Hoppe on 3/4/2565 BE.
//

import Foundation
import CommonCrypto
import MachO
import SwiftUI

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
        var version: String
        var build: String
    }
    
    public static func createBundleCheckSum(bundlePath: URL, version:String, build:String) -> [CheckSum] {
        
        var integrity = [CheckSum]()
        
        let fileManager = FileManager.default
        do {
            let fileUrls = try fileManager.contentsOfDirectory(at:bundlePath, includingPropertiesForKeys: nil)
            for fileURL in fileUrls {
                let fileAttributes = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                if fileAttributes.isRegularFile! {
                    let fileKey = fileURL.absoluteString.replacingOccurrences(of: bundlePath.absoluteString, with: "")
                    
                    do {
                        let resources = try fileURL.resourceValues(forKeys:[.fileSizeKey])
                        let fileSize = resources.fileSize!
                        NSLog ("\(bundlePath.absoluteString)/\(fileKey) \(fileSize)")
                        
                    }
                    catch {
                        print("Error: \(error)")}
                    
                    if (fileKey == "Info.plist" || fileKey == "main.jsbundle"){
                        NSLog("INTEGRITYCHECK \(fileKey)")
                        //let crcHex = fileData.crc32().toHexString() + (suffix ?? "")
                        //integrity.append(CheckSum(checkSum: String(crcHex), file: String(fileKey)))
                        if let crc = sha256(url: fileURL) {
                            let calculatedHash = crc.map { String(format: "%02hhx", $0) }.joined()
                            NSLog("INTEGRITYCHECK \(calculatedHash)")
                            integrity.append(CheckSum(checkSum: calculatedHash, file: String(fileKey),version: version,build: build))
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
        return integrity
    }
    
    
    
    
//        public static func getToken(token:String) -> String{
//            return token
//        }
    
    
        public enum APIError: Error {
      
            case requestFailed
            case jsonSerializationError(Error)
            case invalidData
            case responseProcessingError(Error)
        }
    
        
        public static func patchData(with url: String, parameters: [String: Any], token: String, completion: @escaping (Result<[String: Any], APIError>) -> Void) {
            
           
            
            guard let url = URL(string: url) else{
                completion(.failure(.invalidData))
                print("invalid url")
                return
            }
            
            
            
            var request = URLRequest(url: url)
            
            request.httpMethod = "PATCH"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            } catch let error {
                completion(.failure(.jsonSerializationError(error)))
                print(error.localizedDescription)
            }
            

            URLSession.shared.dataTask(with: request) { (data, response, error) in
                
                        guard error == nil else {
                              completion(.failure(.requestFailed))
                              return
                          }

                          guard let responseData = data else {
                              return
                          }

                          do {
                              //print(String(data: responseData, encoding: .utf8))
                              if let jsonResponse = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as? [String: Any] {
                                  completion(.success(jsonResponse))
                              } else {
                                  completion(.failure(.invalidData))
                              }
                              
                          } catch let jsonError {
                              completion(.failure(.responseProcessingError(jsonError)))
                          }
                
            }.resume()
        }


    
    public static func createIntegrityFile(bundlePath: URL,version: String,build:String) -> [CheckSum] {
        // call patch api in this func
        
        let integrity = createBundleCheckSum(bundlePath: bundlePath, version:version,build:build)
        let integrityJson = try! JSONEncoder().encode(integrity)
        
        //let jsonString =  String(data: integrityJson, encoding: .utf8)
        
       
        let endpoint = "https://api-test.vdc.co.th/merchant/v1/setting?mode=add&property=builds"
        let token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoia2V4LW1vYmlsZS1hcHAiLCJ0eXBlIjoic2l0ZSIsImVudGl0eSI6WyJLRVgiXSwiaWF0IjoxNjk3NjkxMDQ3LCJpc3MiOiJzYWJ1eXRlY2guY29tIn0.ABQIEqkMrs_CX8syBl2cFbxjBpcgNpmWRyu9FxzTGIOdHp6v5OmqP10SJpb8KJwYrbuCzAhkLIw0nkQZCBzOWXOYYdLWRJKrc2rQhwIAJKQBi3EhRpzGguUGSd1glbdb0TIUZ372TEfChQoyoAwpEvmkkONb78F4IZSUUbeAvmJiFn4mhJVmRH1is9Wq7MJ4E8z6SFlVXqXiGFM9RtJk_bHPF_lkZrBTrX0gi6abiyBB8hhywWE1YuuDE4LSjOX7RARZDTeCDT9S7-_FWePDPU_PNLraaIeln6EJQHYe0xxVd9e6RC759-sXTDSmP2V1OXyiZQFhczdqBFAfLcPDWg"

        
        let jsonObject: [String: Any] = [
            "merchant_id": "M12846",
            "type": "app_integrity",
            "data": [
                "builds":
                    [
                       [ "app_id": "kex_app",
                        "version": version,
                        "build": build,
                        "integrity": [
                            "plist": integrityJson
                        ],
                         "os": "ios"
                       ]
                    ],

               
                
            ]
        ]
    
        
      
 
        NSLog("jsonString \(integrityJson)")
        
        patchData(with: endpoint, parameters: jsonObject, token: token){ result in
            switch result {
            case .success(let data):
                NSLog("PATCH DATA \(data)")
            case .failure(let error):
                NSLog("PATCH ERROR \(error)")
            }
        }


       
        NSLog("INTEGRITY CHECKSUM \(integrity)")
        return integrity
    }

    @objc
    public static func checkBundleCheckSum(bundlePath: URL = Bundle.main.bundleURL,version: String,build:String) -> Bool {

        let currentCheckSum = createBundleCheckSum(bundlePath: bundlePath,version:version,build:build);

        
        //call api https://api.vdc.co.th/merchant/setting?type=integrity&build_id=84935893
        //  return datafrom api == currentCheckSum
        NSLog("INTEGRITY CHECKSUM \(currentCheckSum)")

        return true
    }
}




