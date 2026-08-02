import SwiftUI

// MARK: - Ports View
//
// Hero surface. Renders the port list inside a manga panel — each row
// carries a status onomatopoeia chip, a sound picker, preview button,
// and an enable toggle.

struct PortsView: View {
    @ObservedObject var portDetector: PortDetector
    @ObservedObject var soundManager: SoundManager

    private var armedCount: Int {
        portDetector.portStatuses.values.filter(\.isEnabled).count
    }
    private var connectedCount: Int {
        portDetector.portStatuses.values.filter { $0.isEnabled && $0.isConnected }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ports")
                        .font(NaniTheme.Typography.display)
                        .foregroundColor(NaniTheme.Colors.textPrimary)
                    Text("\(armedCount) armed · \(connectedCount) connected")
                        .font(NaniTheme.Typography.body)
                        .foregroundColor(NaniTheme.Colors.textSecondary)
                }

                Spacer()

                OnoChip(text: "ポート", style: .quiet)
            }
            .padding(.horizontal, NaniTheme.Layout.contentPadding)
            .padding(.top, NaniTheme.Layout.contentPadding)
            .padding(.bottom, NaniTheme.Spacing.lg)

            // Port list panel
            VStack(spacing: 0) {
                ForEach(Array(PortType.allCases.enumerated()), id: \.element) { index, portType in
                    if let status = portDetector.portStatuses[portType] {
                        PortRow(
                            status: status,
                            assignedSoundID: soundManager.portAssignments[portType] ?? "",
                            allSounds: soundManager.allSounds,
                            onSoundChanged: { soundID in
                                soundManager.assignSound(soundID, to: portType)
                                portDetector.assignSound(soundID, to: portType)
                            },
                            onPreview: {
                                if let soundID = soundManager.portAssignments[portType] {
                                    soundManager.soundPlayer.play(soundID: soundID)
                                }
                            },
                            onToggle: {
                                portDetector.togglePort(portType)
                            }
                        )

                        if index < PortType.allCases.count - 1 {
                            Rectangle()
                                .fill(NaniTheme.Colors.border)
                                .frame(height: 1)
                        }
                    }
                }
            }
            .naniPanel()
            .padding(.horizontal, NaniTheme.Layout.contentPadding)
            .padding(.bottom, NaniTheme.Spacing.md)

            HStack {
                Text("\(PortType.allCases.count) ports tracked · listening on system events")
                    .font(NaniTheme.Typography.micro)
                    .foregroundColor(NaniTheme.Colors.textTertiary)
                Spacer()
            }
            .padding(.horizontal, NaniTheme.Layout.contentPadding)
            .padding(.bottom, NaniTheme.Spacing.md)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Port Row

struct PortRow: View {
    let status: PortStatus
    let assignedSoundID: String
    let allSounds: [SoundAsset]
    let onSoundChanged: (String) -> Void
    let onPreview: () -> Void
    let onToggle: () -> Void

    @State private var isHovering = false

    private var statusChip: (text: String, style: OnoStyle) {
        guard status.isEnabled else { return ("オフ", .ghost) }
        return status.isConnected ? ("「カチッ」", .accent) : ("シーン", .quiet)
    }

    private var statusDot: DotMode {
        guard status.isEnabled else { return .off }
        return status.isConnected ? .on : .idle
    }

    var body: some View {
        HStack(spacing: NaniTheme.Spacing.md) {

            // Port icon tile
            ZStack {
                RoundedRectangle(cornerRadius: NaniTheme.Radius.button)
                    .fill(NaniTheme.Colors.surfaceMuted)
                    .overlay(
                        RoundedRectangle(cornerRadius: NaniTheme.Radius.button)
                            .stroke(NaniTheme.Colors.border, lineWidth: 1)
                    )
                Image(systemName: status.portType.iconName)
                    .font(.system(size: 14))
                    .foregroundColor(isHovering ? NaniTheme.Colors.accent : NaniTheme.Colors.textSecondary)
            }
            .frame(width: 30, height: 30)

            // Name + onomatopoeia + status text
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(status.portType.displayName)
                        .font(NaniTheme.Typography.bodyEmph)
                        .foregroundColor(NaniTheme.Colors.textPrimary)

                    OnoChip(text: statusChip.text, style: statusChip.style)
                }
                HStack(spacing: 6) {
                    StatusDot(state: statusDot)
                    Text(status.statusText.lowercased())
                        .font(NaniTheme.Typography.micro)
                        .foregroundColor(NaniTheme.Colors.textTertiary)
                        .tracking(0.4)
                }
            }
            .frame(minWidth: 180, alignment: .leading)

            Spacer(minLength: 8)

            // Sound picker chip
            SoundPickerChip(
                assignedSoundID: assignedSoundID,
                allSounds: allSounds,
                isEnabled: status.isEnabled,
                onSoundChanged: onSoundChanged
            )

            // Preview
            Button(action: onPreview) {
                Image(systemName: "play.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(status.isEnabled
                                     ? NaniTheme.Colors.accent
                                     : NaniTheme.Colors.textTertiary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: NaniTheme.Radius.button)
                            .fill(NaniTheme.Colors.accentSubtle.opacity(status.isEnabled ? 1 : 0))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: NaniTheme.Radius.button)
                            .stroke(NaniTheme.Colors.border, lineWidth: 1)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!status.isEnabled)
            .help("Preview sound")
            .accessibilityLabel("Preview sound for \(status.portType.displayName)")

            // Toggle
            Toggle("", isOn: Binding(
                get: { status.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .tint(NaniTheme.Colors.accent)
            .labelsHidden()
            .help("Enable sounds for \(status.portType.displayName)")
            .accessibilityLabel("Enable \(status.portType.displayName)")
        }
        .padding(.horizontal, NaniTheme.Spacing.lg)
        .frame(height: NaniTheme.Layout.portRowHeight)
        .background(
            Rectangle()
                .fill(isHovering ? NaniTheme.Colors.surfaceHover : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: NaniTheme.Motion.fast)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Sound Picker Chip

struct SoundPickerChip: View {
    let assignedSoundID: String
    let allSounds: [SoundAsset]
    let isEnabled: Bool
    let onSoundChanged: (String) -> Void

    @State private var isHovering = false

    private var currentSoundName: String {
        allSounds.first(where: { $0.id == assignedSoundID })?.name ?? "Select sound"
    }

    var body: some View {
        Menu {
            ForEach(allSounds) { sound in
                Button {
                    if sound.id != assignedSoundID {
                        onSoundChanged(sound.id)
                    }
                } label: {
                    if sound.id == assignedSoundID {
                        Label(sound.name, systemImage: "checkmark")
                    } else {
                        Text(sound.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(NaniTheme.Colors.textTertiary)

                Text(currentSoundName)
                    .font(NaniTheme.Typography.body)
                    .foregroundColor(NaniTheme.Colors.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(NaniTheme.Colors.textTertiary)
            }
            .padding(.horizontal, 10)
            .frame(width: 170, height: 28)
            .background(
                RoundedRectangle(cornerRadius: NaniTheme.Radius.input)
                    .fill(NaniTheme.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: NaniTheme.Radius.input)
                    .stroke(
                        isHovering ? NaniTheme.Colors.accent : NaniTheme.Colors.borderStrong,
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .opacity(isEnabled ? 1 : 0.45)
        .disabled(!isEnabled)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: NaniTheme.Motion.fast)) {
                isHovering = hovering
            }
        }
    }
}
