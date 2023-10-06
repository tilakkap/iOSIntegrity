import ArgumentParser
import Foundation
import iOSIntegrity

struct iOSIntegrityCli: ParsableCommand {
    @Argument(help: "The Bundle Path.")
    var bundlePath: String
    @Option(help: "Version for checksum for negative test")
    var version: String?
    @Option(help: "Build ID for checksum for negative test")
    var build: String?

    mutating func run() throws {
        
        let bundleURL = URL.init(fileURLWithPath: bundlePath)
        let checkSum = iOSIntegrity.createIntegrityFile(bundlePath: bundleURL, version: version, build: build)
        print(checkSum);

    }
}
iOSIntegrityCli.main()