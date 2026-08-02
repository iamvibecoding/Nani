import SwiftUI
import Combine
import AppKit

// MARK: - Nani App Entry Point

@main
struct NaniApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // The app is managed entirely via NSStatusItem (menu bar) and
        // programmatic window management in AppDelegate. An empty Settings
        // scene satisfies the App protocol without showing anything.
        Settings {
            EmptyView()
        }
    }
}

// MARK: - User Defaults Keys

private enum Defaults {
    static let hasCompletedOnboarding = "nani.hasCompletedOnboarding"
    static let appearance             = "nani.appearance"
    static let settingsFrameAutosave  = "nani.settingsWindow"
}

// MARK: - App Delegate

/// Owns the menu bar icon, popover, settings window, and onboarding window.
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    // MARK: - Core Services

    var portDetector:     PortDetector!
    var soundPlayer:      SoundPlayer!
    var soundManager:     SoundManager!
    var dndManager:       DNDManager!
    var loginItemManager: LoginItemManager!
    var updateManager:    UpdateManager!
    var licenseManager:   LicenseManager!

    // MARK: - UI Slots

    private var statusItem:       NSStatusItem?
    private var popover:          NSPopover?
    private var settingsWindow:   NSWindow?
    private var onboardingWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Behave as a menu bar (accessory) app — no Dock icon, no main menu.
        // Mirrors LSUIElement=true from Info.plist; required for `swift run`
        // dev builds where Info.plist is not honored.
        NSApp.setActivationPolicy(.accessory)

        // Apply persisted appearance before any window is built.
        applyPersistedAppearance()

        // Initialize core services
        portDetector     = PortDetector()
        soundPlayer      = SoundPlayer()
        soundManager     = SoundManager(soundPlayer: soundPlayer)
        dndManager       = DNDManager()
        loginItemManager = LoginItemManager()
        updateManager    = UpdateManager()
        licenseManager   = LicenseManager()

        // Setup menu bar
        setupStatusItem()

        // Listen for port events → play sounds
        portDetector.eventSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handlePortEvent(event)
            }
            .store(in: &cancellables)

        // First-launch onboarding
        if !UserDefaults.standard.bool(forKey: Defaults.hasCompletedOnboarding) {
            loginItemManager.setEnabled(true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showOnboarding()
            }
        }

        Log.app.info("App launched")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Reopen settings if the user clicks the (hidden) dock entry or opens via Spotlight.
        Task { @MainActor in self.openSettingsWindow() }
        return true
    }

    // MARK: - Port Event Handling

    @MainActor
    private func handlePortEvent(_ event: PortEvent) {
        guard !dndManager.shouldMute else {
            Log.dnd.debug("Sound muted (DND active)")
            return
        }
        let isEnabled = portDetector.portStatuses[event.portType]?.isEnabled ?? true
        soundManager.handlePortEvent(event, isPortEnabled: isEnabled)
    }

    // MARK: - Appearance

    @MainActor
    private func applyPersistedAppearance() {
        let raw  = UserDefaults.standard.string(forKey: Defaults.appearance) ?? AppearanceMode.system.rawValue
        let mode = AppearanceMode(rawValue: raw) ?? .system
        mode.apply()
    }

    // MARK: - Menu Bar

    @MainActor
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            if let customImage = NSImage(named: "AppIcon") {
                let size = NSSize(width: 18, height: 18)
                let resizedImage = NSImage(size: size)
                resizedImage.lockFocus()
                customImage.draw(in: NSRect(origin: .zero, size: size),
                                 from: NSRect(origin: .zero, size: customImage.size),
                                 operation: .sourceOver,
                                 fraction: 1.0)
                resizedImage.unlockFocus()
                resizedImage.isTemplate = false 
                button.image = resizedImage
            } else {
                let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
                let image = NSImage(systemSymbolName: "eyes", accessibilityDescription: "Nani")
                button.image = image?.withSymbolConfiguration(config)
            }
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: NaniTheme.Layout.menuBarWidth, height: 360)
        popover?.behavior = .transient
        popover?.animates = true

        let popoverView = MenuBarPopoverView(
            portDetector: portDetector,
            soundManager: soundManager,
            dndManager: dndManager,
            onOpenSettings: { [weak self] in
                self?.popover?.performClose(nil)
                self?.openSettingsWindow()
            },
            onQuit: {
                NSApplication.shared.terminate(nil)
            }
        )
        popover?.contentViewController = NSHostingController(rootView: popoverView)
    }

    @objc private func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Settings Window

    @MainActor
    func openSettingsWindow() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsWindowView(
            portDetector:     portDetector,
            soundManager:     soundManager,
            dndManager:       dndManager,
            loginItemManager: loginItemManager,
            updateManager:    updateManager,
            licenseManager:   licenseManager,
            onShowOnboarding: { [weak self] in self?.showOnboarding() }
        )

        let window = NSWindow(
            contentRect: NSRect(
                x: 0, y: 0,
                width:  NaniTheme.Layout.windowWidth,
                height: NaniTheme.Layout.windowHeight
            ),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "Nani"
        window.titlebarAppearsTransparent = true
        window.minSize = NSSize(
            width:  NaniTheme.Layout.windowMinWidth,
            height: NaniTheme.Layout.windowMinHeight
        )
        window.identifier = NSUserInterfaceItemIdentifier(Defaults.settingsFrameAutosave)
        window.setFrameAutosaveName(Defaults.settingsFrameAutosave)
        if window.frame.origin == .zero {
            window.center()
        }
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(rootView: settingsView)
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    // MARK: - Onboarding

    @MainActor
    func showOnboarding() {
        if let window = onboardingWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let onboardingView = OnboardingView(
            soundManager: soundManager,
            loginItemManager: loginItemManager,
            onComplete: { [weak self] in
                UserDefaults.standard.set(true, forKey: Defaults.hasCompletedOnboarding)
                self?.onboardingWindow?.close()
            }
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 520),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = ""
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(rootView: onboardingView)
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if window === onboardingWindow {
            // Any dismissal of the onboarding window — including the close
            // button — counts as completion. Without this the tour would
            // re-appear next launch.
            UserDefaults.standard.set(true, forKey: Defaults.hasCompletedOnboarding)
            onboardingWindow = nil
        } else if window === settingsWindow {
            settingsWindow = nil
        }
    }
}
