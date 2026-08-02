import Foundation
import Combine

// MARK: - Sound Manager

/// Manages the mapping between port types and sounds.
/// Persists assignments in UserDefaults and handles the built-in + custom sound library.
@MainActor
final class SoundManager: ObservableObject {

    // MARK: - Published State

    @Published var builtInSounds: [SoundAsset] = SoundAsset.builtInSounds
    @Published var customSounds: [SoundAsset] = []
    @Published var portAssignments: [PortType: String] = [:]  // PortType → SoundAsset.id
    @Published var playOnDisconnect: Bool = false

    // MARK: - Dependencies

    let soundPlayer: SoundPlayer

    // MARK: - Persistence Keys

    private enum Keys {
        static let portAssignments = "nani.portAssignments"
        static let customSounds = "nani.customSounds"
        static let playOnDisconnect = "nani.playOnDisconnect"
        static let volume = "nani.volume"
    }

    // MARK: - Init

    init(soundPlayer: SoundPlayer) {
        self.soundPlayer = soundPlayer
        loadPersistedState()
        soundPlayer.preloadBuiltInSounds()
    }

    // MARK: - Sound Assignment

    /// Assign a sound to a port type.
    func assignSound(_ soundID: String, to portType: PortType) {
        portAssignments[portType] = soundID
        savePortAssignments()
    }

    /// Get the assigned sound for a port type.
    func assignedSound(for portType: PortType) -> SoundAsset? {
        guard let soundID = portAssignments[portType] else { return nil }
        return allSounds.first { $0.id == soundID }
    }

    /// All available sounds (built-in + custom).
    var allSounds: [SoundAsset] {
        builtInSounds + customSounds
    }

    // MARK: - Event Handling

    /// Handle a port event — play the assigned sound if enabled.
    func handlePortEvent(_ event: PortEvent, isPortEnabled: Bool) {
        guard isPortEnabled else { return }

        switch event {
        case .connected(let portType):
            if let soundID = portAssignments[portType] {
                soundPlayer.play(soundID: soundID)
            }
        case .disconnected(let portType):
            if playOnDisconnect, let soundID = portAssignments[portType] {
                soundPlayer.play(soundID: soundID)
            }
        }
    }

    // MARK: - Custom Sound Import

    /// Import a custom sound from a file URL.
    func importCustomSound(from url: URL) -> Bool {
        guard let asset = soundPlayer.loadCustomSound(from: url) else {
            return false
        }
        customSounds.append(asset)
        saveCustomSounds()
        return true
    }

    /// Remove a custom sound.
    func removeCustomSound(_ asset: SoundAsset) {
        customSounds.removeAll { $0.id == asset.id }

        // Remove from any port assignments
        for (portType, soundID) in portAssignments {
            if soundID == asset.id {
                portAssignments[portType] = SoundAsset.defaultAssignments[portType]
            }
        }

        soundPlayer.removeCustomSound(asset)
        saveCustomSounds()
        savePortAssignments()
    }

    // MARK: - Volume

    func setVolume(_ percentage: Int) {
        let volume = Float(percentage) / 100.0
        soundPlayer.setVolume(volume)
        UserDefaults.standard.set(percentage, forKey: Keys.volume)
    }

    var volumePercentage: Int {
        UserDefaults.standard.integer(forKey: Keys.volume)
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        // Load port assignments
        if let data = UserDefaults.standard.data(forKey: Keys.portAssignments),
           let assignments = try? JSONDecoder().decode([String: String].self, from: data) {
            for (key, value) in assignments {
                if let portType = PortType(rawValue: key) {
                    portAssignments[portType] = value
                }
            }
        } else {
            // Use defaults
            portAssignments = SoundAsset.defaultAssignments
        }

        // Load custom sounds
        if let data = UserDefaults.standard.data(forKey: Keys.customSounds),
           let sounds = try? JSONDecoder().decode([SoundAsset].self, from: data) {
            customSounds = sounds
            // Pre-load custom sounds
            for sound in sounds {
                soundPlayer.preload(sound: sound)
            }
        }

        // Load preferences
        playOnDisconnect = UserDefaults.standard.bool(forKey: Keys.playOnDisconnect)

        // Load volume
        let savedVolume = UserDefaults.standard.integer(forKey: Keys.volume)
        if savedVolume > 0 {
            soundPlayer.setVolume(Float(savedVolume) / 100.0)
        } else {
            // Default to 75%
            UserDefaults.standard.set(75, forKey: Keys.volume)
            soundPlayer.setVolume(0.75)
        }
    }

    private func savePortAssignments() {
        let dict = Dictionary(uniqueKeysWithValues: portAssignments.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: Keys.portAssignments)
        }
    }

    private func saveCustomSounds() {
        if let data = try? JSONEncoder().encode(customSounds) {
            UserDefaults.standard.set(data, forKey: Keys.customSounds)
        }
    }

    func savePlayOnDisconnect() {
        UserDefaults.standard.set(playOnDisconnect, forKey: Keys.playOnDisconnect)
    }
}
