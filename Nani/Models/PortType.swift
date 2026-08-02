import Foundation

// MARK: - Port Types

/// Represents the physical port types Nani can monitor.
enum PortType: String, CaseIterable, Codable, Identifiable {
    case usbC = "USB-C"
    case usbA = "USB-A"
    case hdmi = "HDMI"
    case headphoneJack = "Headphone Jack"
    case charger = "Charger"

    var id: String { rawValue }

    /// SF Symbol name for each port type
    var iconName: String {
        switch self {
        case .usbC: return "cable.connector.horizontal"
        case .usbA: return "cable.connector"
        case .hdmi: return "tv"
        case .headphoneJack: return "headphones"
        case .charger: return "battery.100.bolt"
        }
    }

    /// Human-readable description
    var displayName: String { rawValue }
}

// MARK: - Port Events

/// Represents a hardware port event.
enum PortEvent {
    case connected(PortType)
    case disconnected(PortType)

    var portType: PortType {
        switch self {
        case .connected(let type), .disconnected(let type):
            return type
        }
    }

    var isConnected: Bool {
        switch self {
        case .connected: return true
        case .disconnected: return false
        }
    }
}

// MARK: - Port Status

/// Tracks the current connection state of a port.
struct PortStatus: Identifiable {
    let portType: PortType
    var isConnected: Bool
    var isEnabled: Bool  // User toggle
    var assignedSoundID: String?

    var id: String { portType.rawValue }

    var statusText: String {
        if !isEnabled { return "Disabled" }
        switch portType {
        case .charger:
            return isConnected ? "Charging" : "Not charging"
        default:
            return isConnected ? "Connected" : "No device"
        }
    }
}
