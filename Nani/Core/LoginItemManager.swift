import Foundation
import ServiceManagement

// MARK: - Login Item Manager

/// Manages the "Launch at Login" feature via SMAppService (macOS 13+).
@MainActor
final class LoginItemManager: ObservableObject {

    @Published var isEnabled: Bool = false

    private let service = SMAppService.mainApp

    init() {
        checkStatus()
    }

    /// Check the current registration status.
    func checkStatus() {
        isEnabled = service.status == .enabled
    }

    /// Toggle the login item registration.
    func toggle() {
        do {
            if isEnabled {
                try service.unregister()
                isEnabled = false
                Log.login.info("Login item disabled")
            } else {
                try service.register()
                isEnabled = true
                Log.login.info("Login item enabled")
            }
        } catch {
            Log.login.error("Failed to toggle login item: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Set the login item state explicitly.
    func setEnabled(_ enabled: Bool) {
        if enabled != isEnabled {
            toggle()
        }
    }
}
