import SwiftUI
import UniformTypeIdentifiers

// MARK: - Sound Library View
//
// Manga-panel grid of built-in and custom sounds with search + import.

struct SoundLibraryView: View {
    @ObservedObject var soundManager: SoundManager
    @State private var searchText: String = ""
    @State private var isImporting: Bool = false

    private var filteredBuiltIn: [SoundAsset] {
        filter(soundManager.builtInSounds)
    }
    private var filteredCustom: [SoundAsset] {
        filter(soundManager.customSounds)
    }
    private func filter(_ sounds: [SoundAsset]) -> [SoundAsset] {
        guard !searchText.isEmpty else { return sounds }
        return sounds.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private let gridColumns = [
        GridItem(.adaptive(minimum: 158, maximum: 220), spacing: NaniTheme.Spacing.md)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NaniTheme.Spacing.md) {

                // Header
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sound Library")
                            .font(NaniTheme.Typography.display)
                            .foregroundColor(NaniTheme.Colors.textPrimary)
                        Text("\(soundManager.allSounds.count) sounds — \(soundManager.builtInSounds.count) built-in, \(soundManager.customSounds.count) custom")
                            .font(NaniTheme.Typography.body)
                            .foregroundColor(NaniTheme.Colors.textSecondary)
                    }
                    Spacer()
                    searchField
                }
                .padding(.horizontal, NaniTheme.Layout.contentPadding)
                .padding(.top, NaniTheme.Layout.contentPadding)
                .padding(.bottom, NaniTheme.Spacing.xs)

                // Built-in section
                if !filteredBuiltIn.isEmpty {
                    Text("BUILT-IN")
                        .naniSectionLabel()
                        .padding(.horizontal, NaniTheme.Layout.contentPadding)

                    LazyVGrid(columns: gridColumns, spacing: NaniTheme.Spacing.md) {
                        ForEach(filteredBuiltIn) { sound in
                            SoundCard(
                                sound: sound,
                                isPlaying: soundManager.soundPlayer.currentlyPlayingSoundID == sound.id,
                                onPlay: { soundManager.soundPlayer.play(soundID: sound.id) },
                                onDelete: nil
                            )
                        }
                    }
                    .padding(.horizontal, NaniTheme.Layout.contentPadding)
                }

                // Custom section + import card
                Text("CUSTOM")
                    .naniSectionLabel()
                    .padding(.horizontal, NaniTheme.Layout.contentPadding)
                    .padding(.top, NaniTheme.Spacing.sm)

                LazyVGrid(columns: gridColumns, spacing: NaniTheme.Spacing.md) {
                    ForEach(filteredCustom) { sound in
                        SoundCard(
                            sound: sound,
                            isPlaying: soundManager.soundPlayer.currentlyPlayingSoundID == sound.id,
                            onPlay: { soundManager.soundPlayer.play(soundID: sound.id) },
                            onDelete: { soundManager.removeCustomSound(sound) }
                        )
                    }

                    if searchText.isEmpty {
                        SoundImportCard(action: { isImporting = true })
                    }
                }
                .padding(.horizontal, NaniTheme.Layout.contentPadding)
                .padding(.bottom, NaniTheme.Layout.contentPadding)

                if filteredBuiltIn.isEmpty && filteredCustom.isEmpty {
                    emptyState
                        .padding(.horizontal, NaniTheme.Layout.contentPadding)
                        .padding(.bottom, NaniTheme.Spacing.xl)
                }
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    _ = soundManager.importCustomSound(from: url)
                }
            case .failure(let error):
                Log.sounds.error("Import failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(NaniTheme.Colors.textTertiary)
            TextField("Search sounds…", text: $searchText)
                .textFieldStyle(.plain)
                .font(NaniTheme.Typography.body)
        }
        .padding(.horizontal, 10)
        .frame(width: 220, height: 28)
        .background(
            RoundedRectangle(cornerRadius: NaniTheme.Radius.input)
                .fill(NaniTheme.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: NaniTheme.Radius.input)
                .stroke(NaniTheme.Colors.borderStrong, lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(spacing: NaniTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
                .foregroundColor(NaniTheme.Colors.textTertiary)
            Text("No sounds match \u{201C}\(searchText)\u{201D}")
                .font(NaniTheme.Typography.body)
                .foregroundColor(NaniTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NaniTheme.Spacing.xxl)
    }
}

// MARK: - Sound Card

struct SoundCard: View {
    let sound: SoundAsset
    let isPlaying: Bool
    let onPlay: () -> Void
    var onDelete: (() -> Void)?

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Visual — screentone block with waveform glyph
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: NaniTheme.Radius.input)
                    .fill(NaniTheme.Colors.surfaceMuted)
                    .frame(height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: NaniTheme.Radius.input)
                            .stroke(NaniTheme.Colors.border, lineWidth: 1)
                    )
                    .naniScreentone(.soft, tint: isPlaying ? NaniTheme.Colors.pop : NaniTheme.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: NaniTheme.Radius.input))

                HStack(spacing: 0) {
                    Spacer()
                    ZStack {
                        Image(systemName: "waveform")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isPlaying ? NaniTheme.Colors.pop : NaniTheme.Colors.accent)
                    }
                    Spacer()
                }
                .frame(height: 48)

                if isPlaying {
                    Text("NOW")
                        .font(NaniTheme.Typography.micro)
                        .tracking(0.6)
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(NaniTheme.Colors.pop)
                        )
                        .padding(4)
                }
            }

            // Name
            Text(sound.name)
                .font(NaniTheme.Typography.bodyEmph)
                .foregroundColor(NaniTheme.Colors.textPrimary)
                .lineLimit(1)

            // Meta
            HStack(spacing: 6) {
                Text(sound.durationText.uppercased())
                    .font(NaniTheme.Typography.micro)
                    .foregroundColor(NaniTheme.Colors.textTertiary)
                    .tracking(0.5)

                Spacer()

                Button(action: onPlay) {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isPlaying ? NaniTheme.Colors.pop : NaniTheme.Colors.accent)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(NaniTheme.Colors.accentSubtle)
                        )
                }
                .buttonStyle(.plain)
                .help(isPlaying ? "Stop" : "Preview \(sound.name)")

                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(NaniTheme.Colors.textTertiary)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovering ? 1 : 0)
                    .help("Delete \(sound.name)")
                }
            }
        }
        .padding(10)
        .background(NaniTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: NaniTheme.Radius.tile))
        .background(
            RoundedRectangle(cornerRadius: NaniTheme.Radius.tile)
                .fill(NaniTheme.Colors.panelInk)
                .offset(x: isHovering ? 4 : 2.5, y: isHovering ? 4 : 2.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: NaniTheme.Radius.tile)
                .stroke(NaniTheme.Colors.panelInk, lineWidth: 1.25)
        )
        .offset(x: isHovering ? -1 : 0, y: isHovering ? -1 : 0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: NaniTheme.Motion.fast)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Import Card

struct SoundImportCard: View {
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                Text("Import sound")
                    .font(NaniTheme.Typography.bodyEmph)
                Text("WAV / MP3 · max 2s")
                    .font(NaniTheme.Typography.micro)
                    .foregroundColor(NaniTheme.Colors.textTertiary)
            }
            .foregroundColor(isHovering ? NaniTheme.Colors.accent : NaniTheme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(
                RoundedRectangle(cornerRadius: NaniTheme.Radius.tile)
                    .fill(isHovering ? NaniTheme.Colors.accentSubtle : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: NaniTheme.Radius.tile)
                    .strokeBorder(
                        isHovering ? NaniTheme.Colors.accent : NaniTheme.Colors.borderStrong,
                        style: StrokeStyle(lineWidth: 1.25, dash: [4, 3])
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: NaniTheme.Motion.fast)) {
                isHovering = hovering
            }
        }
        .help("Import a custom sound")
    }
}
