import Foundation
import Sparkle

/// Manages Sparkle integration for in-app updates.
///
/// Sparkle is currently OFF by default because we don't have a published appcast feed yet
/// (set `SUFeedURL` in Info.plist + `enabled` to true to turn it on).
@MainActor
final class UpdateManager: ObservableObject {

    /// Set this to true and add `SUFeedURL` to Info.plist when the update feed is live.
    static let enabled: Bool = false

    private var updaterController: SPUStandardUpdaterController?

    @Published var automaticallyChecksForUpdates: Bool = false {
        didSet {
            updaterController?.updater.automaticallyChecksForUpdates = automaticallyChecksForUpdates
        }
    }

    init() {
        guard Self.enabled else {
            Log.updates.debug("Sparkle disabled (no appcast feed configured)")
            return
        }
        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        self.updaterController = controller
        self.automaticallyChecksForUpdates = controller.updater.automaticallyChecksForUpdates
    }

    /// Triggers an explicit check for updates (e.g. from a button)
    func checkForUpdates() {
        guard let controller = updaterController else {
            Log.updates.info("Updates not yet available")
            return
        }
        controller.checkForUpdates(nil)
    }
}
