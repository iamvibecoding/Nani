import Foundation
import Combine

/// Manages Lemon Squeezy license key validation.
@MainActor
final class LicenseManager: ObservableObject {
    
    // MARK: - Published State
    
    @Published var licenseKey: String = ""
    @Published var isValid: Bool = true
    @Published var isChecking: Bool = false
    @Published var errorMessage: String?
    
    init() {}
    
    // MARK: - Validation
    
    func validateLicense() async {
        // No-op for now as we are bypassing auth.
    }
    
    func deactivateLicense() {
        // No-op
    }
}
