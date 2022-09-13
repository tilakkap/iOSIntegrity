import ArgumentParser
import Foundation
import iOSIntegrity

struct iOSIntegrityCli: ParsableCommand {
    @Argument(help: "The Bundle Path.")
    var bundlePath: String
    @Option(help: "Suffix for checksum for negative test")
    var suffix: String?

    mutating func run() throws {
        let bundleURL = URL.init(fileURLWithPath: bundlePath)
        let checkSum = iOSIntegrity.createIntegrityFile(bundlePath: bundleURL, suffix: (suffix ?? ""))
        print(checkSum);

    }
}
iOSIntegrityCli.main()