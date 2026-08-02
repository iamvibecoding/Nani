import Foundation

// MARK: - Sound Asset

/// Represents a sound file that can be assigned to a port.
struct SoundAsset: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let fileName: String
    let fileExtension: String
    let duration: TimeInterval  // seconds
    let isBuiltIn: Bool
    let category: SoundCategory

    /// Full display string for duration (e.g., "0.8s")
    var durationText: String {
        String(format: "%.1fs", duration)
    }

    /// File URL for built-in sounds (from the Swift Package module bundle).
    /// SwiftPM places `.process("Resources")` files into Bundle.module, NOT Bundle.main.
    var bundleURL: URL? {
        guard isBuiltIn else { return nil }
        return Bundle.module.url(forResource: fileName, withExtension: fileExtension)
    }

    /// File URL for custom sounds (from Application Support)
    var customURL: URL? {
        guard !isBuiltIn else { return nil }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let soundsDir = appSupport.appendingPathComponent("Nani/Sounds", isDirectory: true)
        return soundsDir.appendingPathComponent("\(fileName).\(fileExtension)")
    }

    /// Resolved file URL (bundle for built-in, app support for custom)
    var fileURL: URL? {
        isBuiltIn ? bundleURL : customURL
    }
}

// MARK: - Sound Category

enum SoundCategory: String, Codable, CaseIterable {
    case exclamation = "Exclamations"
    case reaction = "Reactions"
    case greeting = "Greetings"
    case custom = "Custom"
}

// MARK: - Built-in Sound Library

extension SoundAsset {
    /// Default built-in sounds shipped with the app.
    /// These will be replaced with actual commissioned audio files.
    static let builtInSounds: [SoundAsset] = {
        guard let urls = Bundle.module.urls(forResourcesWithExtension: "mp3", subdirectory: nil) else {
            return []
        }
        
        // Custom definitions for the 5 default port assignments
        let customIDs: [String: (id: String, name: String, category: SoundCategory, duration: TimeInterval)] = [
            "anime_wow": ("nani", "Anime Wow", .exclamation, 0.8),
            "yamete_kudasai": ("ara_ara", "Yamete Kudasai", .reaction, 1.2),
            "gambare_gambare": ("yatta", "Gambare", .exclamation, 0.7),
            "ehhh_cute_anime": ("wow", "Ehhh Cute", .exclamation, 0.6),
            "tuturu": ("tuturu", "Tuturu!", .greeting, 0.9)
        ]
        
        var assets: [SoundAsset] = []
        for url in urls {
            let fileName = url.deletingPathExtension().lastPathComponent
            
            if let custom = customIDs[fileName] {
                assets.append(SoundAsset(
                    id: custom.id,
                    name: custom.name,
                    fileName: fileName,
                    fileExtension: "mp3",
                    duration: custom.duration,
                    isBuiltIn: true,
                    category: custom.category
                ))
            } else {
                let display = fileName.replacingOccurrences(of: "_", with: " ").capitalized
                assets.append(SoundAsset(
                    id: fileName,
                    name: display,
                    fileName: fileName,
                    fileExtension: "mp3",
                    duration: 1.0,
                    isBuiltIn: true,
                    category: .exclamation
                ))
            }
        }
        return assets.sorted { $0.name < $1.name }
    }()

    /// Default sound assignments for each port type
    static let defaultAssignments: [PortType: String] = [
        .usbC: "nani",
        .usbA: "wow",
        .hdmi: "ara_ara",
        .headphoneJack: "tuturu",
        .charger: "yatta",
    ]
}
