import SwiftUI

// MARK: - Preferences View
//
// Sectioned settings page with manga-panel groups. Each section gets
// an uppercase mono label and a panel containing related rows.

struct PreferencesView: View {
    @ObservedObject var soundManager: SoundManager
    @ObservedObject var dndManager: DNDManager
    @ObservedObject var loginItemManager: LoginItemManager

    @AppStorage("nani.appearance") private var appearance: AppearanceMode = .system
    @State private var selectedVolume: Int = 75

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Header
                HStack(alignment: .lastTextBaseline) {
                    Text("Preferences")
                        .font(NaniTheme.Typography.display)
                        .foregroundColor(NaniTheme.Colors.textPrimary)
                    Spacer()
                    OnoChip(text: "セッティング", style: .quiet)
                }
                .padding(.horizontal, NaniTheme.Layout.contentPadding)
                .padding(.top, NaniTheme.Layout.contentPadding)
                .padding(.bottom, NaniTheme.Spacing.lg)

                // General
                sectionLabel("GENERAL")
                VStack(spacing: 0) {
                    toggleRow(
                        title: "Launch at login",
                        description: "Start Nani when you sign in.",
                        isOn: Binding(
                            get: { loginItemManager.isEnabled },
                            set: { _ in loginItemManager.toggle() }
                        )
                    )
                    divider
                    toggleRow(
                        title: "Play on disconnect",
                        description: "Also play a sound when devices unplug.",
                        isOn: $soundManager.playOnDisconnect
                    )
                    .onChange(of: soundManager.playOnDisconnect) { _ in
                        soundManager.savePlayOnDisconnect()
                    }
                }
                .naniPanel()
                .padding(.horizontal, NaniTheme.Layout.contentPadding)
                .padding(.bottom, NaniTheme.Spacing.lg)

                // Audio
                sectionLabel("AUDIO")
                VStack(spacing: 0) {
                    HStack {
                        rowLabel(
                            title: "Default volume",
                            description: "Used for ports without an override."
                        )
                        Spacer()
                        Picker("", selection: $selectedVolume) {
                            Text("25%").tag(25)
                            Text("50%").tag(50)
                            Text("75%").tag(75)
                            Text("100%").tag(100)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                        .labelsHidden()
                        .onChange(of: selectedVolume) { newValue in
                            soundManager.setVolume(newValue)
                        }
                    }
                    .padding(.horizontal, NaniTheme.Spacing.lg)
                    .frame(height: 56)
                }
                .naniPanel()
                .padding(.horizontal, NaniTheme.Layout.contentPadding)
                .padding(.bottom, NaniTheme.Spacing.lg)

                // Appearance
                sectionLabel("APPEARANCE")
                VStack(spacing: 0) {
                    HStack {
                        rowLabel(
                            title: "Theme",
                            description: "Follow macOS, or pin to light / dark."
                        )
                        Spacer()
                        Picker("", selection: $appearance) {
                            Text("Light").tag(AppearanceMode.light)
                            Text("Dark").tag(AppearanceMode.dark)
                            Text("Auto").tag(AppearanceMode.system)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                        .labelsHidden()
                        .onChange(of: appearance) { newValue in
                            newValue.apply()
                        }
                    }
                    .padding(.horizontal, NaniTheme.Spacing.lg)
                    .frame(height: 56)
                }
                .naniPanel()
                .padding(.horizontal, NaniTheme.Layout.contentPadding)
                .padding(.bottom, NaniTheme.Spacing.lg)

                // Do Not Disturb
                sectionLabel("DO NOT DISTURB")
                VStack(spacing: 0) {
                    toggleRow(
                        title: "Quiet hours",
                        description: "Mute Nani during a daily window.",
                        isOn: $dndManager.isScheduleEnabled
                    )
                    .onChange(of: dndManager.isScheduleEnabled) { _ in
                        dndManager.saveState()
                    }

                    if dndManager.isScheduleEnabled {
                        divider
                        HStack {
                            rowLabel(
                                title: "Schedule",
                                description: "Configure in System Settings → Focus."
                            )
                            Spacer()
                            Text(dndManager.scheduleDisplayString)
                                .font(NaniTheme.Typography.body)
                                .foregroundColor(NaniTheme.Colors.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(NaniTheme.Colors.surfaceMuted)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(NaniTheme.Colors.border, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, NaniTheme.Spacing.lg)
                        .frame(height: 56)
                    }
                }
                .naniPanel()
                .padding(.horizontal, NaniTheme.Layout.contentPadding)
                .padding(.bottom, NaniTheme.Layout.contentPadding)
            }
        }
        .onAppear {
            selectedVolume = max(25, soundManager.volumePercentage)
        }
    }

    // MARK: - Reusable

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .naniSectionLabel()
            .padding(.horizontal, NaniTheme.Layout.contentPadding)
            .padding(.bottom, NaniTheme.Spacing.xs)
    }

    private func toggleRow(title: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack {
            rowLabel(title: title, description: description)
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .tint(NaniTheme.Colors.accent)
                .labelsHidden()
        }
        .padding(.horizontal, NaniTheme.Spacing.lg)
        .frame(height: 56)
    }

    private func rowLabel(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(NaniTheme.Typography.bodyEmph)
                .foregroundColor(NaniTheme.Colors.textPrimary)
            Text(description)
                .font(NaniTheme.Typography.micro)
                .foregroundColor(NaniTheme.Colors.textSecondary)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(NaniTheme.Colors.border)
            .frame(height: 1)
            .padding(.horizontal, NaniTheme.Spacing.lg)
    }
}
