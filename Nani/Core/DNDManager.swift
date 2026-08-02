import Foundation
import Combine

// MARK: - Do Not Disturb Manager

/// Manages scheduled and manual muting of sound playback.
@MainActor
final class DNDManager: ObservableObject {

    @Published var isActive: Bool = false
    @Published var isScheduleEnabled: Bool = false
    @Published var scheduleStartHour: Int = 22   // 10 PM
    @Published var scheduleStartMinute: Int = 0
    @Published var scheduleEndHour: Int = 8       // 8 AM
    @Published var scheduleEndMinute: Int = 0
    @Published var isPausedManually: Bool = false

    private var scheduleTimer: Timer?

    // MARK: - Persistence Keys

    private enum Keys {
        static let isScheduleEnabled = "nani.dnd.scheduleEnabled"
        static let scheduleStartHour = "nani.dnd.startHour"
        static let scheduleStartMinute = "nani.dnd.startMinute"
        static let scheduleEndHour = "nani.dnd.endHour"
        static let scheduleEndMinute = "nani.dnd.endMinute"
        static let isPaused = "nani.dnd.isPaused"
    }

    init() {
        loadState()
        startScheduleCheck()
    }

    // MARK: - Manual Pause

    func togglePause() {
        isPausedManually.toggle()
        updateActiveState()
        UserDefaults.standard.set(isPausedManually, forKey: Keys.isPaused)
    }

    // MARK: - Schedule

    var scheduleDisplayString: String {
        let startFormatted = String(format: "%d:%02d %@",
                                    scheduleStartHour > 12 ? scheduleStartHour - 12 : scheduleStartHour,
                                    scheduleStartMinute,
                                    scheduleStartHour >= 12 ? "PM" : "AM")
        let endFormatted = String(format: "%d:%02d %@",
                                  scheduleEndHour > 12 ? scheduleEndHour - 12 : scheduleEndHour,
                                  scheduleEndMinute,
                                  scheduleEndHour >= 12 ? "PM" : "AM")
        return "\(startFormatted) — \(endFormatted)"
    }

    /// Check if the current time falls within the DND schedule.
    func isWithinSchedule() -> Bool {
        guard isScheduleEnabled else { return false }

        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute
        let startMinutes = scheduleStartHour * 60 + scheduleStartMinute
        let endMinutes = scheduleEndHour * 60 + scheduleEndMinute

        if startMinutes <= endMinutes {
            // Same day range (e.g., 9:00 AM - 5:00 PM)
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        } else {
            // Overnight range (e.g., 10:00 PM - 8:00 AM)
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        }
    }

    /// Whether sounds should be muted right now.
    var shouldMute: Bool {
        isPausedManually || isWithinSchedule()
    }

    // MARK: - Private

    private func updateActiveState() {
        isActive = shouldMute
    }

    private func startScheduleCheck() {
        // Check every 60 seconds
        scheduleTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateActiveState()
            }
        }
        updateActiveState()
    }

    // MARK: - Persistence

    func saveState() {
        UserDefaults.standard.set(isScheduleEnabled, forKey: Keys.isScheduleEnabled)
        UserDefaults.standard.set(scheduleStartHour, forKey: Keys.scheduleStartHour)
        UserDefaults.standard.set(scheduleStartMinute, forKey: Keys.scheduleStartMinute)
        UserDefaults.standard.set(scheduleEndHour, forKey: Keys.scheduleEndHour)
        UserDefaults.standard.set(scheduleEndMinute, forKey: Keys.scheduleEndMinute)
    }

    private func loadState() {
        let defaults = UserDefaults.standard

        if defaults.object(forKey: Keys.isScheduleEnabled) != nil {
            isScheduleEnabled = defaults.bool(forKey: Keys.isScheduleEnabled)
            scheduleStartHour = defaults.integer(forKey: Keys.scheduleStartHour)
            scheduleStartMinute = defaults.integer(forKey: Keys.scheduleStartMinute)
            scheduleEndHour = defaults.integer(forKey: Keys.scheduleEndHour)
            scheduleEndMinute = defaults.integer(forKey: Keys.scheduleEndMinute)
        }

        isPausedManually = defaults.bool(forKey: Keys.isPaused)
    }
}
