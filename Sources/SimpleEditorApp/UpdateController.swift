import Foundation
import Sparkle

@MainActor
final class UpdateController: ObservableObject {
    private let updaterController: SPUStandardUpdaterController?

    init() {
        guard Self.hasValidSparkleConfiguration else {
            updaterController = nil
            return
        }
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var isAvailable: Bool {
        updaterController != nil
    }

    func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }

    private static var hasValidSparkleConfiguration: Bool {
        guard let feedString = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String,
              let feedURL = URL(string: feedString),
              feedURL.scheme == "https",
              let publicKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String,
              Data(base64Encoded: publicKey)?.count == 32 else {
            return false
        }
        return true
    }
}
