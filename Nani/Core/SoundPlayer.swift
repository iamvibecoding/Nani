import Foundation
import AVFoundation
import AppKit

// MARK: - Sound Player

/// Low-latency audio playback engine using AVAudioPlayer.
/// Pre-loads sounds for instant playback on port events.
/// Plays through the system default output — whatever the user has selected.
@MainActor
final class SoundPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {

    @Published var isPlaying: Bool = false
    @Published var currentlyPlayingSoundID: String?

    private var players: [String: AVAudioPlayer] = [:]
    private var volume: Float = 0.75

    // MARK: - Preloading

    /// Pre-load a sound into memory for instant playback.
    func preload(sound: SoundAsset) {
        guard let url = sound.fileURL else {
            Log.sounds.warning("Missing file for sound: \(sound.name, privacy: .public) (\(sound.fileName, privacy: .public).\(sound.fileExtension, privacy: .public))")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.delegate = self
            player.prepareToPlay()
            players[sound.id] = player
        } catch {
            Log.sounds.error("Failed to preload '\(sound.name, privacy: .public)': \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Pre-load all built-in sounds.
    func preloadBuiltInSounds() {
        for sound in SoundAsset.builtInSounds {
            preload(sound: sound)
        }
        Log.sounds.info("Pre-loaded \(self.players.count) of \(SoundAsset.builtInSounds.count) built-in sounds")
    }

    // MARK: - Playback

    /// Play a sound by its asset ID.
    func play(soundID: String) {
        guard let player = players[soundID] else {
            Log.sounds.warning("No player for soundID: \(soundID, privacy: .public)")
            return
        }

        // Stop any currently playing sound
        stopAll()

        player.volume = volume
        player.currentTime = 0
        if player.play() {
            isPlaying = true
            currentlyPlayingSoundID = soundID
        } else {
            Log.sounds.error("Playback failed for: \(soundID, privacy: .public)")
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentlyPlayingSoundID = nil
        }
    }

    /// Play the sound assigned to a specific port event.
    func playForEvent(_ event: PortEvent, soundID: String?) {
        guard let soundID = soundID else { return }
        play(soundID: soundID)
    }

    /// Stop all currently playing sounds.
    func stopAll() {
        for (_, player) in players where player.isPlaying {
            player.stop()
            player.currentTime = 0
        }
        isPlaying = false
        currentlyPlayingSoundID = nil
    }

    // MARK: - Volume

    /// Set the global volume (0.0 to 1.0).
    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        for (_, player) in players {
            player.volume = volume
        }
    }

    /// Get the current volume as a percentage string.
    var volumePercentage: String {
        "\(Int(volume * 100))%"
    }

    // MARK: - Custom Sound Management

    /// Load a custom sound from a file URL.
    func loadCustomSound(from url: URL) -> SoundAsset? {
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }
        
        do {
            // Check file size (< 5MB)
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resourceValues.fileSize, fileSize > 5_000_000 {
                Log.sounds.warning("Import rejected: file too large (\(fileSize) bytes)")
                return nil
            }

            // Copy to Application Support
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let soundsDir = appSupport.appendingPathComponent("Nani/Sounds", isDirectory: true)
            try FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)

            let destURL = soundsDir.appendingPathComponent(url.lastPathComponent)
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: url, to: destURL)

            let player = try AVAudioPlayer(contentsOf: destURL)
            player.volume = volume
            player.delegate = self
            player.prepareToPlay()

            let fileName = url.deletingPathExtension().lastPathComponent
            let fileExtension = url.pathExtension

            let asset = SoundAsset(
                id: "custom_\(UUID().uuidString)",
                name: fileName,
                fileName: fileName,
                fileExtension: fileExtension,
                duration: player.duration,
                isBuiltIn: false,
                category: .custom
            )

            players[asset.id] = player
            return asset
        } catch {
            Log.sounds.error("Failed to import sound: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Remove a custom sound.
    func removeCustomSound(_ asset: SoundAsset) {
        players.removeValue(forKey: asset.id)
        if let url = asset.customURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
