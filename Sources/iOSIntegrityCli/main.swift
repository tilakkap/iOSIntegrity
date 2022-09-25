import ArgumentParser
import Foundation
import iOSIntegrity

struct iOSIntegrityCli: ParsableCommand {
    @Argument(help: "The Bundle Path.")
    var bundlePath: String
    @Argument(help: "Macho Hash")
    var machoHash: String

    mutating func run() throws {
        let bundleURL = URL.init(fileURLWithPath: bundlePath);
        let checkSum = iOSIntegrity.createIntegrityFile(bundlePath: bundleURL, machoHash: machoHash)
        print(checkSum);
    }
}
iOSIntegrityCli.main()