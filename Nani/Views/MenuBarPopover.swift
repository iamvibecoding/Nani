import SwiftUI

// MARK: - Menu Bar Popover View
//
// Compact 300px popover anchored to the menu bar icon. Shows brand,
// onomatopoeia status, the port list, DND toggle, and footer actions.

struct MenuBarPopoverView: View {
    @ObservedObject var portDetector: PortDetector
    @ObservedObject var soundManager: SoundManager
    @ObservedObject var dndManager: DNDManager

    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    private var connectedCount: Int {
        portDetector.portStatuses.values.filter { $0.isEnabled && $0.isConnected }.count
    }
    private var armedCount: Int {
        portDetector.portStatuses.values.filter(\.isEnabled).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack(alignment: .center, spacing: 8) {
                BrandMark(size: 22)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text("Nani")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(NaniTheme.Colors.textPrimary)
                        OnoChip(
                            text: connectedCount > 0 ? "「カチッ」" : "シーン",
                            style: connectedCount > 0 ? .accent : .quiet
                        )
                    }
                    Text("\(connectedCount) CONNECTED · \(armedCount) ARMED")
                        .font(NaniTheme.Typography.micro)
                        .foregroundColor(NaniTheme.Colors.textTertiary)
                        .tracking(0.6)
                }

                Spacer()

                Button(action: { dndManager.togglePause() }) {
                    Image(systemName: dndManager.isPausedManually ? "play.fill" : "pause.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(dndManager.isPausedManually
                                         ? NaniTheme.Colors.accent
                                         : NaniTheme.Colors.textSecondary)
                        .frame(width: 26, height: 26)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(NaniTheme.Colors.surfaceHover)
                        )
                }
                .buttonStyle(.plain)
                .help(dndManager.isPausedManually ? "Resume" : "Pause all sounds")
            }
            .padding(.horizontal, NaniTheme.Spacing.lg)
            .padding(.top, NaniTheme.Spacing.md)
            .padding(.bottom, NaniTheme.Spacing.sm)

            divider

            // Port rows
            VStack(spacing: 0) {
                ForEach(PortType.allCases) { portType in
                    if let status = portDetector.portStatuses[portType] {
                        popoverPortRow(
                            status: status,
                            soundName: soundManager.assignedSound(for: portType)?.name ?? "—"
                        )
                    }
                }
            }
            .padding(.vertical, 4)

            divider

            // DND row
            HStack {
                Image(systemName: "moon.fill")
                    .font(.system(size: 11))
                    .foregroundColor(NaniTheme.Colors.textSecondary)
                    .frame(width: 16)
                Text("Pause all sounds")
                    .font(NaniTheme.Typography.body)
                    .foregroundColor(NaniTheme.Colors.textPrimary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { dndManager.isPausedManually },
                    set: { _ in dndManager.togglePause() }
                ))
                .toggleStyle(.switch)
                .tint(NaniTheme.Colors.accent)
                .labelsHidden()
                .controlSize(.small)
            }
            .padding(.horizontal, NaniTheme.Spacing.lg)
            .padding(.vertical, NaniTheme.Spacing.sm)

            divider

            // Footer
            HStack(spacing: NaniTheme.Spacing.sm) {
                footerButton(title: "Open Nani", icon: "gearshape", action: onOpenSettings, prominent: true)
                footerButton(title: "Quit", icon: "power", action: onQuit, prominent: false)
            }
            .padding(.horizontal, NaniTheme.Spacing.lg)
            .padding(.vertical, NaniTheme.Spacing.md)
        }
        .frame(width: NaniTheme.Layout.menuBarWidth)
        .background(NaniTheme.Colors.windowBackground)
    }

    // MARK: - Components

    private var divider: some View {
        Rectangle()
            .fill(NaniTheme.Colors.hairline)
            .frame(height: 1)
    }

    private func popoverPortRow(status: PortStatus, soundName: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: status.portType.iconName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(status.isConnected
                                 ? NaniTheme.Colors.accent
                                 : NaniTheme.Colors.textTertiary)
                .frame(width: 18)

            Text(status.portType.displayName)
                .font(NaniTheme.Typography.body)
                .foregroundColor(NaniTheme.Colors.textPrimary)

            Spacer()

            Text(soundName)
                .font(NaniTheme.Typography.micro)
                .foregroundColor(NaniTheme.Colors.textTertiary)
                .lineLimit(1)
                .truncationMode(.tail)

            StatusDot(state: status.isEnabled
                      ? (status.isConnected ? .on : .idle)
                      : .off)
        }
        .padding(.horizontal, NaniTheme.Spacing.lg)
        .frame(height: 28)
    }

    private func footerButton(title: String, icon: String, action: @escaping () -> Void, prominent: Bool) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(NaniTheme.Typography.bodyEmph)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .foregroundColor(prominent ? .white : NaniTheme.Colors.textSecondary)
            .background(
                RoundedRectangle(cornerRadius: NaniTheme.Radius.button)
                    .fill(prominent ? NaniTheme.Colors.accent : NaniTheme.Colors.surfaceHover)
            )
        }
        .buttonStyle(.plain)
    }
}
