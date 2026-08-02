import SwiftUI

// MARK: - Onboarding View
//
// Three-step first-launch flow. The hero step pairs the rounded app
// icon with an onomatopoeia chip and screentone — the icon itself
// serves as the brand "character".

struct OnboardingView: View {
    @ObservedObject var soundManager: SoundManager
    @ObservedObject var loginItemManager: LoginItemManager
    let onComplete: () -> Void

    @State private var currentStep: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch currentStep {
                case 0: WelcomeStep()
                case 1: SoundPickerStep(soundManager: soundManager)
                case 2: StartupStep(loginItemManager: loginItemManager)
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .trailing)),
                removal:   .opacity.combined(with: .move(edge: .leading))
            ))

            // Footer
            VStack(spacing: NaniTheme.Spacing.md) {
                stepIndicator

                HStack(spacing: NaniTheme.Spacing.sm) {
                    if currentStep > 0 {
                        Button(action: previousStep) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.left")
                                Text("Back")
                            }
                            .font(NaniTheme.Typography.bodyEmph)
                            .foregroundColor(NaniTheme.Colors.textSecondary)
                            .frame(width: 96, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: NaniTheme.Radius.button)
                                    .stroke(NaniTheme.Colors.borderStrong, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: nextStep) {
                        HStack(spacing: 6) {
                            Text(buttonTitle)
                            Image(systemName: currentStep == 2 ? "checkmark" : "arrow.right")
                        }
                        .font(NaniTheme.Typography.bodyEmph)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: NaniTheme.Radius.button)
                                .fill(NaniTheme.Colors.accent)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: NaniTheme.Radius.button)
                                .stroke(NaniTheme.Colors.panelInk, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(.horizontal, NaniTheme.Layout.contentPadding)
            .padding(.bottom, NaniTheme.Layout.contentPadding)
        }
        .frame(width: 560, height: 520)
        .background(NaniTheme.Colors.windowBackground)
    }

    // MARK: - Footer pieces

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { step in
                Capsule()
                    .fill(step == currentStep ? NaniTheme.Colors.accent : NaniTheme.Colors.border)
                    .frame(width: step == currentStep ? 22 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: currentStep)
            }
            Text("STEP \(currentStep + 1) OF 3")
                .font(NaniTheme.Typography.micro)
                .tracking(1.0)
                .foregroundColor(NaniTheme.Colors.textTertiary)
                .padding(.leading, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var buttonTitle: String {
        switch currentStep {
        case 0: return "Get started"
        case 1: return "Continue"
        case 2: return "Open Nani"
        default: return "Done"
        }
    }

    private func nextStep() {
        if currentStep < 2 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            onComplete()
        }
    }

    private func previousStep() {
        guard currentStep > 0 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep -= 1
        }
    }
}

// MARK: - Step 1: Welcome

private struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: NaniTheme.Spacing.xl) {
            Spacer(minLength: NaniTheme.Spacing.lg)

            // Hero: rounded app icon with floating onomatopoeia + screentone halo
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(NaniTheme.Colors.accentSubtle)
                    .frame(width: 200, height: 200)
                    .naniScreentone(.line, tint: NaniTheme.Colors.accent, opacity: 0.7)
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                if let nsImage = NSImage(named: "AppIcon") {
                    Image(nsImage: nsImage)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 132, height: 132)
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(NaniTheme.Colors.panelInk, lineWidth: 1.5)
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(NaniTheme.Colors.panelInk)
                                .offset(x: 5, y: 5)
                        )
                } else {
                    Image(systemName: "app.fill")
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 132, height: 132)
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(NaniTheme.Colors.panelInk, lineWidth: 1.5)
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(NaniTheme.Colors.panelInk)
                                .offset(x: 5, y: 5)
                        )
                }

                // Floating onomatopoeia
                OnoChip(text: "「カチッ」", style: .accent)
                    .scaleEffect(1.05)
                    .offset(x: 84, y: -68)
            }
            .padding(.top, NaniTheme.Spacing.md)

            VStack(spacing: NaniTheme.Spacing.sm) {
                Text("Meet Nani")
                    .font(NaniTheme.Typography.display)
                    .foregroundColor(NaniTheme.Colors.textPrimary)

                Text("Plug in a cable. Hear something fun.\nNani plays a sound the moment something\nconnects or unplugs.")
                    .font(NaniTheme.Typography.body)
                    .foregroundColor(NaniTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            // Tiny feature row
            HStack(spacing: NaniTheme.Spacing.lg) {
                featurePill(icon: "cable.connector.horizontal", label: "5 ports")
                featurePill(icon: "waveform", label: "Built-in SFX")
                featurePill(icon: "menubar.rectangle", label: "Menu bar")
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, NaniTheme.Layout.contentPadding)
        .padding(.top, NaniTheme.Spacing.lg)
    }

    private func featurePill(icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(NaniTheme.Colors.accent)
            Text(label)
                .font(NaniTheme.Typography.captionUp)
                .tracking(0.8)
                .foregroundColor(NaniTheme.Colors.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(NaniTheme.Colors.accentSubtle)
        )
    }
}

// MARK: - Step 2: Sound Picker

private struct SoundPickerStep: View {
    @ObservedObject var soundManager: SoundManager

    var body: some View {
        VStack(alignment: .leading, spacing: NaniTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pick a sound for each port")
                    .font(NaniTheme.Typography.title)
                    .foregroundColor(NaniTheme.Colors.textPrimary)
                Text("Swap any time from the Sound Library.")
                    .font(NaniTheme.Typography.body)
                    .foregroundColor(NaniTheme.Colors.textSecondary)
            }
            .padding(.top, NaniTheme.Spacing.xxl)

            VStack(spacing: NaniTheme.Spacing.sm) {
                ForEach(PortType.allCases) { portType in
                    onboardingPortRow(portType)
                }
            }

            HStack(spacing: 6) {
                OnoChip(text: "ピコ", style: .quiet)
                Text("Tap any row to preview.")
                    .font(NaniTheme.Typography.micro)
                    .foregroundColor(NaniTheme.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, NaniTheme.Layout.contentPadding)
    }

    private func onboardingPortRow(_ portType: PortType) -> some View {
        HStack(spacing: NaniTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: NaniTheme.Radius.button)
                    .fill(NaniTheme.Colors.surfaceMuted)
                Image(systemName: portType.iconName)
                    .font(.system(size: 12))
                    .foregroundColor(NaniTheme.Colors.textSecondary)
            }
            .frame(width: 28, height: 28)
            .overlay(
                RoundedRectangle(cornerRadius: NaniTheme.Radius.button)
                    .stroke(NaniTheme.Colors.border, lineWidth: 1)
            )

            Text(portType.displayName)
                .font(NaniTheme.Typography.bodyEmph)
                .foregroundColor(NaniTheme.Colors.textPrimary)
                .frame(width: 130, alignment: .leading)

            Spacer()

            SoundPickerChip(
                assignedSoundID: soundManager.portAssignments[portType] ?? "",
                allSounds: soundManager.builtInSounds,
                isEnabled: true,
                onSoundChanged: { soundManager.assignSound($0, to: portType) }
            )
        }
        .padding(.horizontal, NaniTheme.Spacing.md)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: NaniTheme.Radius.button)
                .fill(NaniTheme.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: NaniTheme.Radius.button)
                .stroke(NaniTheme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Step 3: Startup

private struct StartupStep: View {
    @ObservedObject var loginItemManager: LoginItemManager

    var body: some View {
        VStack(alignment: .leading, spacing: NaniTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Set it and forget it")
                    .font(NaniTheme.Typography.title)
                    .foregroundColor(NaniTheme.Colors.textPrimary)
                Text("Nani lives quietly in your menu bar.")
                    .font(NaniTheme.Typography.body)
                    .foregroundColor(NaniTheme.Colors.textSecondary)
            }
            .padding(.top, NaniTheme.Spacing.xxl)

            VStack(spacing: 0) {
                startupRow(
                    title: "Launch at login",
                    description: "Start Nani when you sign in — recommended.",
                    isOn: Binding(
                        get: { loginItemManager.isEnabled },
                        set: { _ in loginItemManager.toggle() }
                    )
                )
            }
            .naniPanel()

            // Tip card
            HStack(spacing: 10) {
                OnoChip(text: "「カチッ」", style: .accent)
                Text("Try it: plug something in and Nani will react.")
                    .font(NaniTheme.Typography.bodyEmph)
                    .foregroundColor(NaniTheme.Colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: NaniTheme.Radius.card)
                    .fill(NaniTheme.Colors.accentSubtle)
            )

            Spacer(minLength: 0)
        }
        .padding(.horizontal, NaniTheme.Layout.contentPadding)
    }

    private func startupRow(title: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(NaniTheme.Typography.bodyEmph)
                    .foregroundColor(NaniTheme.Colors.textPrimary)
                Text(description)
                    .font(NaniTheme.Typography.micro)
                    .foregroundColor(NaniTheme.Colors.textSecondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .tint(NaniTheme.Colors.accent)
                .labelsHidden()
        }
        .padding(.horizontal, NaniTheme.Spacing.lg)
        .frame(height: 56)
    }
}
