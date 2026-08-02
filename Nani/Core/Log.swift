import Foundation
import os

/// Unified logger for Nani. Replaces ad-hoc `print()` calls so logs are
/// queryable via Console.app and routed to OSLog with proper levels.
enum Log {
    private static let subsystem = "app.nani"

    static let app      = Logger(subsystem: subsystem, category: "app")
    static let ports    = Logger(subsystem: subsystem, category: "ports")
    static let audio    = Logger(subsystem: subsystem, category: "audio")
    static let sounds   = Logger(subsystem: subsystem, category: "sounds")
    static let license  = Logger(subsystem: subsystem, category: "license")
    static let updates  = Logger(subsystem: subsystem, category: "updates")
    static let dnd      = Logger(subsystem: subsystem, category: "dnd")
    static let login    = Logger(subsystem: subsystem, category: "login")
}
