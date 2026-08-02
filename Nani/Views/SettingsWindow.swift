import SwiftUI

// MARK: - Settings Window
//
// Sidebar-on-left + content layout. Sidebar carries the brand mark and
// nav. Content swaps based on the selected tab.

struct SettingsWindowView: View {
    @ObservedObject var portDetector: PortDetector
    @ObservedObject var soundManager: SoundManager
    @ObservedObject var dndManager: DNDManager
    @ObservedObject var loginItemManager: LoginItemManager
    @ObservedObject var updateManager: UpdateManager
    @ObservedObject var licenseManager: LicenseManager
    let onShowOnboarding: () -> Void

    @State private var selectedTab: SettingsTab = .ports

    enum SettingsTab: String, CaseIterable {
        case ports       = "Ports"
        case sounds      = "Sound Library"
        case preferences = "Preferences"
        case about       = "About"

        var iconName: String {
            switch self {
            case .ports:       return "cable.connector.horizontal"
            case .sounds:      return "music.note"
            case .preferences: return "gearshape"
            case .about:       return "info.circle"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Rectangle()
                .fill(NaniTheme.Colors.border)
                .frame(width: 1)
            content
        }
        .frame(
            minWidth:  NaniTheme.Layout.windowMinWidth,
            idealWidth: NaniTheme.Layout.windowWidth,
            maxWidth: .infinity,
            minHeight: NaniTheme.Layout.windowMinHeight,
            idealHeight: NaniTheme.Layout.windowHeight,
            maxHeight: .infinity
        )
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Brand block
            HStack(spacing: NaniTheme.Spacing.sm) {
                BrandMark(size: 26)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Nani")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(NaniTheme.Colors.textPrimary)
                    Text("Anime Sound Engine")
                        .font(NaniTheme.Typography.micro)
                        .foregroundColor(NaniTheme.Colors.textTertiary)
                        .tracking(0.4)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, NaniTheme.Spacing.lg)
            .padding(.bottom, NaniTheme.Spacing.md)

            // Section label
            Text("SETUP")
                .naniSectionLabel()
                .padding(.horizontal, 14)
                .padding(.top, NaniTheme.Spacing.xs)
                .padding(.bottom, NaniTheme.Spacing.xs)

            VStack(spacing: 2) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    sidebarItem(tab)
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            // Footer
            HStack(spacing: 6) {
                StatusDot(state: .on)
                Text("Monitoring")
                    .font(NaniTheme.Typography.micro)
                    .foregroundColor(NaniTheme.Colors.textTertiary)
                Spacer()
                Text("v\(appVersion)")
                    .font(NaniTheme.Typography.micro)
                    .foregroundColor(NaniTheme.Colors.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, NaniTheme.Spacing.md)
            .overlay(
                Rectangle()
                    .fill(NaniTheme.Colors.border)
                    .frame(height: 1)
                    .padding(.horizontal, 14),
                alignment: .top
            )
        }
        .frame(width: NaniTheme.Layout.sidebarWidth)
        .background(NaniTheme.Colors.sidebarBackground)
        .overlay(alignment: .top) {
            Screentone(density: .soft)
                .opacity(0.4)
                .mask(
                    LinearGradient(
                        colors: [.clear, .black, .black, .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .allowsHitTesting(false)
        }
    }

    private func sidebarItem(_ tab: SettingsTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.easeInOut(duration: NaniTheme.Motion.fast)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 9) {
                ZStack(alignment: .leading) {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(NaniTheme.Colors.accent)
                            .frame(width: 2.5, height: 14)
                            .padding(.leading, -8)
                    }
                    Image(systemName: tab.iconName)
                        .font(.system(size: 13))
                        .frame(width: 18)
                }
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                Spacer()
            }
            .padding(.horizontal, NaniTheme.Spacing.sm)
            .frame(height: NaniTheme.Layout.navItemHeight)
            .foregroundColor(isSelected
                             ? NaniTheme.Colors.textPrimary
                             : NaniTheme.Colors.textSecondary)
            .background(
                RoundedRectangle(cornerRadius: NaniTheme.Radius.button)
                    .fill(isSelected ? NaniTheme.Colors.surfaceHover : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        Group {
            switch selectedTab {
            case .ports:
                PortsView(portDetector: portDetector, soundManager: soundManager)
            case .sounds:
                SoundLibraryView(soundManager: soundManager)
            case .preferences:
                PreferencesView(
                    soundManager: soundManager,
                    dndManager: dndManager,
                    loginItemManager: loginItemManager
                )
            case .about:
                AboutView(
                    updateManager: updateManager,
                    licenseManager: licenseManager,
                    onShowOnboarding: onShowOnboarding
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NaniTheme.Colors.windowBackground)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

// MARK: - About View
//
// Brand hero + version + license + credits. The app icon, framed in a
// manga panel with action lines and a floating onomatopoeia chip,
// serves as the brand character.

struct AboutView: View {
    @ObservedObject var updateManager: UpdateManager
    @ObservedObject var licenseManager: LicenseManager
    let onShowOnboarding: () -> Void

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NaniTheme.Spacing.lg) {

                HStack(alignment: .lastTextBaseline) {
                    Text("About")
                        .font(NaniTheme.Typography.display)
                        .foregroundColor(NaniTheme.Colors.textPrimary)
                    Spacer()
                    OnoChip(text: "アバウト", style: .quiet)
                }
                .padding(.horizontal, NaniTheme.Layout.contentPadding)
                .padding(.top, NaniTheme.Layout.contentPadding)
                .padding(.bottom, NaniTheme.Spacing.xs)

                // Hero card
                HStack(alignment: .center, spacing: NaniTheme.Spacing.xl) {

                    // App icon framed in a manga panel
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(NaniTheme.Colors.accentSubtle)
                            .frame(width: 128, height: 128)
                            .naniScreentone(.mid, tint: NaniTheme.Colors.accent, opacity: 0.7)
                            .clipShape(RoundedRectangle(cornerRadius: 18))

                        if let nsImage = NSImage(named: "AppIcon") {
                            Image(nsImage: nsImage)
                                .resizable()
                                .interpolation(.high)
                                .frame(width: 96, height: 96)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(NaniTheme.Colors.panelInk, lineWidth: 1.25)
                                )
                        } else {
                            Image(systemName: "app.fill")
                                .resizable()
                                .interpolation(.high)
                                .frame(width: 96, height: 96)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(NaniTheme.Colors.panelInk, lineWidth: 1.25)
                                )
                        }


                        OnoChip(text: "「カチッ」", style: .accent)
                            .scaleEffect(0.95)
                            .offset(x: 58, y: -52)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Nani")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(NaniTheme.Colors.textPrimary)

                        HStack(spacing: 6) {
                            Text("Version \(appVersion)")
                                .font(NaniTheme.Typography.bodyEmph)
                                .foregroundColor(NaniTheme.Colors.textPrimary)
                            Text("·")
                                .foregroundColor(NaniTheme.Colors.textTertiary)
                            Text("build \(build)")
                                .font(NaniTheme.Typography.micro)
                                .foregroundColor(NaniTheme.Colors.textTertiary)
                        }

                        Text("Anime sounds for every port event.")
                            .font(NaniTheme.Typography.body)
                            .foregroundColor(NaniTheme.Colors.textSecondary)
                            .padding(.top, 2)

                        if UpdateManager.enabled {
                            Button(action: updateManager.checkForUpdates) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("Check for updates")
                                        .font(NaniTheme.Typography.bodyEmph)
                                }
                                .foregroundColor(NaniTheme.Colors.accent)
                                .padding(.horizontal, 12)
                                .frame(height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: NaniTheme.Radius.button)
                                        .fill(NaniTheme.Colors.accentSubtle)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: NaniTheme.Radius.button)
                                        .stroke(NaniTheme.Colors.accent.opacity(0.4), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                    }

                    Spacer()
                }
                .padding(NaniTheme.Spacing.lg)
                .naniPanel()
                .padding(.horizontal, NaniTheme.Layout.contentPadding)
                // About Nani Info
                Text("WHY NANI?")
                    .naniSectionLabel()
                    .padding(.horizontal, NaniTheme.Layout.contentPadding)

                VStack(alignment: .leading, spacing: NaniTheme.Spacing.md) {
                    HStack(alignment: .top, spacing: NaniTheme.Spacing.md) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundColor(NaniTheme.Colors.accent)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Anime-inspired interactions")
                                .font(NaniTheme.Typography.bodyEmph)
                                .foregroundColor(NaniTheme.Colors.textPrimary)
                            Text("Turn mundane plug-ins into an anime moment with custom SFX for MagSafe and USB.")
                                .font(NaniTheme.Typography.body)
                                .foregroundColor(NaniTheme.Colors.textSecondary)
                        }
                    }
                    
                    HStack(alignment: .top, spacing: NaniTheme.Spacing.md) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 16))
                            .foregroundColor(NaniTheme.Colors.accent)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Smart silence")
                                .font(NaniTheme.Typography.bodyEmph)
                                .foregroundColor(NaniTheme.Colors.textPrimary)
                            Text("Nani intelligently stays quiet when you're in Focus or Do Not Disturb mode.")
                                .font(NaniTheme.Typography.body)
                                .foregroundColor(NaniTheme.Colors.textSecondary)
                        }
                    }
                    
                    HStack(alignment: .top, spacing: NaniTheme.Spacing.md) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 16))
                            .foregroundColor(NaniTheme.Colors.accent)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bring your own vibes")
                                .font(NaniTheme.Typography.bodyEmph)
                                .foregroundColor(NaniTheme.Colors.textPrimary)
                            Text("Easily import any of your favorite audio files up to 5MB to customize your setup.")
                                .font(NaniTheme.Typography.body)
                                .foregroundColor(NaniTheme.Colors.textSecondary)
                        }
                    }
                    
                    HStack(alignment: .top, spacing: NaniTheme.Spacing.md) {
                        Image(systemName: "macwindow")
                            .font(.system(size: 16))
                            .foregroundColor(NaniTheme.Colors.accent)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Native to macOS")
                                .font(NaniTheme.Typography.bodyEmph)
                                .foregroundColor(NaniTheme.Colors.textPrimary)
                            Text("Lightweight, beautifully designed, and completely out of your way in the menu bar.")
                                .font(NaniTheme.Typography.body)
                                .foregroundColor(NaniTheme.Colors.textSecondary)
                        }
                    }
                }
                .padding(NaniTheme.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .naniPanel()
                .padding(.horizontal, NaniTheme.Layout.contentPadding)

                // Help
                Text("HELP")
                    .naniSectionLabel()
                    .padding(.horizontal, NaniTheme.Layout.contentPadding)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Welcome tour")
                            .font(NaniTheme.Typography.bodyEmph)
                            .foregroundColor(NaniTheme.Colors.textPrimary)
                        Text("Re-run the first-launch walkthrough.")
                            .font(NaniTheme.Typography.micro)
                            .foregroundColor(NaniTheme.Colors.textSecondary)
                    }
                    Spacer()
                    Button(action: onShowOnboarding) {
                        Text("Show tour")
                            .font(NaniTheme.Typography.bodyEmph)
                            .foregroundColor(NaniTheme.Colors.textPrimary)
                            .padding(.horizontal, 12)
                            .frame(height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: NaniTheme.Radius.button)
                                    .fill(NaniTheme.Colors.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: NaniTheme.Radius.button)
                                    .stroke(NaniTheme.Colors.borderStrong, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, NaniTheme.Spacing.lg)
                .frame(height: 56)
                .naniPanel()
                .padding(.horizontal, NaniTheme.Layout.contentPadding)

                // Credits
                Text("CREDITS")
                    .naniSectionLabel()
                    .padding(.horizontal, NaniTheme.Layout.contentPadding)

                VStack(alignment: .leading, spacing: NaniTheme.Spacing.xs) {
                    HStack(spacing: 8) {
                        OnoChip(text: "「ピコ」", style: .pop)
                        Text("Made with care and a little \u{201C}Nani?!\u{201D}")
                            .font(NaniTheme.Typography.body)
                            .foregroundColor(NaniTheme.Colors.textPrimary)
                    }
                    
                    HStack(spacing: 12) {
                        Link("@iamvibecoding",
                             destination: URL(string: "https://github.com/iamvibecoding")!)
                            .font(NaniTheme.Typography.bodyEmph)
                            .foregroundColor(NaniTheme.Colors.accent)
                        
                        Link("Report Bugs / Request Features",
                             destination: URL(string: "mailto:siddheshkamath40@gmail.com")!)
                            .font(NaniTheme.Typography.bodyEmph)
                            .foregroundColor(NaniTheme.Colors.accent)
                    }
                    .padding(.top, 4)
                }
                .padding(NaniTheme.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .naniPanel()
                .padding(.horizontal, NaniTheme.Layout.contentPadding)
                .padding(.bottom, NaniTheme.Layout.contentPadding)
            }
        }
    }
}

// MARK: - License Section

private struct LicenseSection: View {
    @ObservedObject var licenseManager: LicenseManager

    var body: some View {
        VStack(alignment: .leading, spacing: NaniTheme.Spacing.md) {
            if licenseManager.isValid {
                HStack(spacing: NaniTheme.Spacing.sm) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(NaniTheme.Colors.success)
                        .font(.system(size: 16))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Activated")
                            .font(NaniTheme.Typography.bodyEmph)
                            .foregroundColor(NaniTheme.Colors.textPrimary)
                        Text("Thanks for supporting Nani.")
                            .font(NaniTheme.Typography.micro)
                            .foregroundColor(NaniTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Button("Deactivate") {
                        licenseManager.deactivateLicense()
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Text("Enter your license key to unlock Nani.")
                    .font(NaniTheme.Typography.body)
                    .foregroundColor(NaniTheme.Colors.textSecondary)

                HStack(spacing: NaniTheme.Spacing.sm) {
                    TextField("License key", text: $licenseManager.licenseKey)
                        .textFieldStyle(.plain)
                        .font(NaniTheme.Typography.body)
                        .foregroundColor(NaniTheme.Colors.textPrimary)
                        .padding(.horizontal, NaniTheme.Spacing.md)
                        .frame(height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: NaniTheme.Radius.input)
                                .fill(NaniTheme.Colors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: NaniTheme.Radius.input)
                                .stroke(NaniTheme.Colors.borderStrong, lineWidth: 1)
                        )

                    Button {
                        Task { await licenseManager.validateLicense() }
                    } label: {
                        if licenseManager.isChecking {
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 80)
                        } else {
                            Text("Activate")
                                .frame(width: 80)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(NaniTheme.Colors.accent)
                    .disabled(licenseManager.licenseKey.isEmpty || licenseManager.isChecking)
                }

                if let errorMessage = licenseManager.errorMessage {
                    Text(errorMessage)
                        .font(NaniTheme.Typography.micro)
                        .foregroundColor(NaniTheme.Colors.error)
                }

                Link("Buy a license →",
                     destination: URL(string: "https://nani.app/buy")!)
                    .font(NaniTheme.Typography.bodyEmph)
                    .foregroundColor(NaniTheme.Colors.accent)
            }
        }
        .padding(NaniTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .naniPanel()
    }
}
