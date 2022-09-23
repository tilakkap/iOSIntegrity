import ArgumentParser
import Foundation
import iOSIntegrity

struct iOSIntegrityCli: ParsableCommand {
    @Argument(help: "The Bundle Path.")
    var bundlePath: String
    @Argument(help: "Suffix for checksum for negative test")
    var plistTemplatePath: String

    mutating func run() throws {
        let bundleURL = URL.init(fileURLWithPath: bundlePath);
        let plistTemplURL = URL.init(fileURLWithPath: plistTemplatePath);
        let checkSum = iOSIntegrity.createIntegrityFile(bundlePath: bundleURL, plistTempl: plistTemplURL)
        print(checkSum);

    }
}
iOSIntegrityCli.main()