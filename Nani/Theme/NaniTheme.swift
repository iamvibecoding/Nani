import SwiftUI
import AppKit

// MARK: - Nani Design System
// Notion-tight macOS layout × distinctive manga visual language ×
// deep royal purple. Mirrors the HTML reference in
// `opendesign/design-systems/nani-manga/`. All colors are adaptive
// (light/dark) via `Color.dynamic`.

enum NaniTheme {

    // MARK: - Colors

    enum Colors {
        // Surfaces
        static let background       = Color.dynamic(light: "#FAFAF8", dark: "#0E0D11")
        static let windowBackground = Color.dynamic(light: "#FFFFFF", dark: "#18171C")
        static let sidebarBackground = Color.dynamic(light: "#F4F3EF", dark: "#131218")
        static let surface          = Color.dynamic(light: "#FFFFFF", dark: "#1C1A21")
        static let surfaceMuted     = Color.dynamic(light: "#F7F6F2", dark: "#221F29")
        static let surfaceHover     = Color.dynamic(light: "#EFEEE9", dark: "#26232D")

        // Text
        static let textPrimary   = Color.dynamic(light: "#2A2823", dark: "#ECE9F2")
        static let textSecondary = Color.dynamic(light: "#6B6862", dark: "#9C97A6")
        static let textTertiary  = Color.dynamic(light: "#A6A39C", dark: "#5E5A68")

        // Borders
        static let border        = Color.dynamic(light: "#E5E3DC", dark: "#2A2731")
        static let borderStrong  = Color.dynamic(light: "#D4D1C8", dark: "#3A3645")
        static let panelInk      = Color.dynamic(light: "#1F1D1A", dark: "#F5F1F8")
        static let hairline      = Color.dynamic(light: "#1F1D1A", dark: "#F5F1F8").opacity(0.08)

        // Accent — deep royal purple primary
        static let accent        = Color.dynamic(light: "#5C3E9C", dark: "#8B6FE1")
        static let accentHover   = Color.dynamic(light: "#4A2D8A", dark: "#A18AE6")
        static let accentPress   = Color.dynamic(light: "#3A2480", dark: "#7560D4")
        static let accentSubtle  = Color.dynamic(light: "#F0EBF8", dark: "#2A1F4D")
        static let accentTint    = Color.dynamic(light: "#E4DAF2", dark: "#36285E")

        // Pop — electric violet, used sparingly for "now playing" / motion highlights
        static let pop           = Color.dynamic(light: "#8C56E8", dark: "#B594F4")
        static let popGlow       = Color.dynamic(light: "#8C56E8", dark: "#B594F4").opacity(0.32)

        // Semantic
        static let success       = Color.dynamic(light: "#4DAB6E", dark: "#5BBE7E")
        static let warning       = Color.dynamic(light: "#E8A33D", dark: "#F0B158")
        static let error         = Color.dynamic(light: "#E15A5A", dark: "#EB7373")
    }

    // MARK: - Typography
    //
    // - Display: SF Pro Rounded Black gives a premium, manga-friendly
    //   feel without bundling a font file.
    // - Body: SF Pro Text (system default).
    // - Mono: SF Mono via `.monospaced` design.
    // - Onomatopoeia (Japanese katakana) falls back to Hiragino Sans
    //   automatically when rendered by the system.

    enum Typography {
        static let display   = Font.system(size: 26, weight: .black,    design: .rounded)
        static let title     = Font.system(size: 20, weight: .heavy,    design: .rounded)
        static let subtitle  = Font.system(size: 16, weight: .semibold, design: .rounded)
        static let body      = Font.system(size: 13, weight: .regular)
        static let bodyEmph  = Font.system(size: 13, weight: .semibold)
        static let caption   = Font.system(size: 11, weight: .medium)
        static let captionUp = Font.system(size: 10, weight: .bold,     design: .monospaced)
        static let micro     = Font.system(size: 10, weight: .regular,  design: .monospaced)
        static let ono       = Font.system(size: 11, weight: .heavy,    design: .rounded)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs:   CGFloat = 4
        static let sm:   CGFloat = 8
        static let md:   CGFloat = 12
        static let lg:   CGFloat = 16
        static let xl:   CGFloat = 24
        static let xxl:  CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: - Radii

    enum Radius {
        static let card:   CGFloat = 8
        static let button: CGFloat = 6
        static let input:  CGFloat = 6
        static let tile:   CGFloat = 8
        static let pill:   CGFloat = 999
        // legacy alias used by existing call sites
        static let full:   CGFloat = 999
    }

    // MARK: - Layout

    enum Layout {
        static let windowWidth:     CGFloat = 760
        static let windowHeight:    CGFloat = 560
        static let windowMinWidth:  CGFloat = 680
        static let windowMinHeight: CGFloat = 500
        static let sidebarWidth:    CGFloat = 208
        static let contentPadding:  CGFloat = 28
        static let menuBarWidth:    CGFloat = 300
        static let portRowHeight:   CGFloat = 60
        static let navItemHeight:   CGFloat = 32
    }

    // MARK: - Motion

    enum Motion {
        static let fast:   Double = 0.12
        static let base:   Double = 0.18
        static let slow:   Double = 0.26
        static let spring: Animation = .interactiveSpring(response: 0.32, dampingFraction: 0.72)
    }
}

// MARK: - Color helpers

extension Color {
    /// Hex initializer (#RRGGBB or #AARRGGBB).
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Build a dynamic color that resolves to `light` or `dark` depending
    /// on the current appearance (system + per-window).
    static func dynamic(light: String, dark: String) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [
                .darkAqua,
                .vibrantDark,
                .accessibilityHighContrastDarkAqua,
                .accessibilityHighContrastVibrantDark
            ]) != nil
            return NSColor(Color(hex: isDark ? dark : light))
        })
    }
}

// MARK: - Screentone
//
// Low-opacity dot pattern, evocative of manga screentone. Drawn with
// SwiftUI's Canvas so it scales without bundling assets. Use sparingly:
// sidebar background, hero panels, card visuals — not full screens.

enum ScreentoneDensity {
    case soft, mid, line

    fileprivate var pitch: CGFloat {
        switch self {
        case .soft: return 10
        case .mid:  return 7
        case .line: return 6
        }
    }

    fileprivate var dotRadius: CGFloat {
        switch self {
        case .soft: return 1.0
        case .mid:  return 1.2
        case .line: return 0.0   // line variant uses strokes
        }
    }

    fileprivate var opacity: Double {
        switch self {
        case .soft: return 0.10
        case .mid:  return 0.16
        case .line: return 0.18
        }
    }
}

struct Screentone: View {
    let density: ScreentoneDensity
    var tint: Color = NaniTheme.Colors.accent

    var body: some View {
        Canvas { context, size in
            let resolved = context.resolve(Text(""))
            _ = resolved // silence unused warning on older toolchains
            let pitch = density.pitch
            let radius = density.dotRadius
            let color = tint.opacity(density.opacity)

            if density == .line {
                // 45° hairlines
                var x: CGFloat = -size.height
                while x < size.width + size.height {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                    context.stroke(path, with: .color(color), lineWidth: 0.6)
                    x += pitch
                }
            } else {
                var y: CGFloat = pitch / 2
                while y < size.height {
                    var x: CGFloat = pitch / 2
                    while x < size.width {
                        let rect = CGRect(
                            x: x - radius, y: y - radius,
                            width: radius * 2, height: radius * 2
                        )
                        context.fill(Path(ellipseIn: rect), with: .color(color))
                        x += pitch
                    }
                    y += pitch
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - View Modifiers

/// Notion-style soft card (no manga ink). Kept for compatibility with
/// existing call sites; new surfaces should prefer `naniPanel` where the
/// design calls for the manga panel border.
struct NaniCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(NaniTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: NaniTheme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: NaniTheme.Radius.card)
                    .stroke(NaniTheme.Colors.border, lineWidth: 1)
            )
    }
}

/// Manga panel — 1.5px ink border with an offset drop shadow. Used on
/// the port list, sound cards, preference groups, onboarding hero.
struct NaniPanelModifier: ViewModifier {
    var radius: CGFloat = NaniTheme.Radius.card
    var inkWidth: CGFloat = 1.5
    var offset: CGFloat = 3

    func body(content: Content) -> some View {
        content
            .background(NaniTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .background(
                // Offset ink slab visible just below+right of the panel.
                RoundedRectangle(cornerRadius: radius)
                    .fill(NaniTheme.Colors.panelInk)
                    .offset(x: offset, y: offset)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(NaniTheme.Colors.panelInk, lineWidth: inkWidth)
            )
    }
}

/// Section label modifier (uppercase, tracked, muted) — monospaced for
/// the manga / technical-doc feel.
struct NaniSectionLabelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(NaniTheme.Typography.captionUp)
            .foregroundColor(NaniTheme.Colors.textTertiary)
            .textCase(.uppercase)
            .tracking(1.2)
    }
}

extension View {
    func naniCard() -> some View {
        modifier(NaniCardModifier())
    }

    func naniPanel(radius: CGFloat = NaniTheme.Radius.card,
                   inkWidth: CGFloat = 1.5,
                   offset: CGFloat = 3) -> some View {
        modifier(NaniPanelModifier(radius: radius, inkWidth: inkWidth, offset: offset))
    }

    func naniSectionLabel() -> some View {
        modifier(NaniSectionLabelModifier())
    }

    /// Overlay a screentone pattern. Use a `.mask` underneath for falloff.
    func naniScreentone(_ density: ScreentoneDensity = .soft,
                        tint: Color = NaniTheme.Colors.accent,
                        opacity: Double = 1.0) -> some View {
        overlay(
            Screentone(density: density, tint: tint)
                .opacity(opacity)
        )
    }
}

// MARK: - Onomatopoeia Chip

enum OnoStyle {
    case plain      // surface, ink border, slight rotation
    case accent     // purple fill
    case pop        // electric violet + glow
    case quiet      // dashed, low contrast
    case ghost      // muted, no rotation
}

struct OnoChip: View {
    let text: String
    var style: OnoStyle = .plain

    var body: some View {
        Text(text)
            .font(NaniTheme.Typography.ono)
            .tracking(0.5)
            .foregroundColor(foreground)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(borderColor, style: borderStyle)
            )
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(shadowColor)
                    .offset(x: shadowOffset, y: shadowOffset)
            )
            .rotationEffect(.degrees(rotation))
            .shadow(color: glow, radius: glowRadius)
            .fixedSize()
    }

    private var foreground: Color {
        switch style {
        case .plain, .quiet, .ghost: return NaniTheme.Colors.textPrimary
        case .accent, .pop:          return .white
        }
    }
    private var fill: Color {
        switch style {
        case .plain:  return NaniTheme.Colors.surface
        case .accent: return NaniTheme.Colors.accent
        case .pop:    return NaniTheme.Colors.pop
        case .quiet:  return .clear
        case .ghost:  return NaniTheme.Colors.surfaceMuted
        }
    }
    private var borderColor: Color {
        switch style {
        case .quiet, .ghost: return NaniTheme.Colors.borderStrong
        default:             return NaniTheme.Colors.panelInk
        }
    }
    private var borderStyle: StrokeStyle {
        switch style {
        case .quiet: return StrokeStyle(lineWidth: 1, dash: [2, 2])
        default:     return StrokeStyle(lineWidth: 1.25)
        }
    }
    private var shadowColor: Color {
        switch style {
        case .quiet:        return .clear
        case .ghost:        return NaniTheme.Colors.borderStrong
        default:            return NaniTheme.Colors.panelInk
        }
    }
    private var shadowOffset: CGFloat {
        switch style {
        case .quiet: return 0
        case .ghost: return 1
        default:     return 2
        }
    }
    private var rotation: Double {
        switch style {
        case .quiet, .ghost: return 0
        default:             return -2
        }
    }
    private var glow: Color {
        style == .pop ? NaniTheme.Colors.popGlow : .clear
    }
    private var glowRadius: CGFloat {
        style == .pop ? 8 : 0
    }
}

// MARK: - Status Dot

enum DotMode { case on, idle, paused, off }

struct StatusDot: View {
    let state: DotMode
    @State private var pulse: Bool = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .overlay(
                Circle()
                    .stroke(color.opacity(pulse ? 0 : 0.32), lineWidth: pulse ? 6 : 0)
                    .scaleEffect(pulse ? 2.4 : 1.0)
                    .opacity(state == .on ? 1 : 0)
            )
            .onAppear {
                guard state == .on else { return }
                withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
                    pulse = true
                }
            }
    }

    private var color: Color {
        switch state {
        case .on:     return NaniTheme.Colors.success
        case .paused: return NaniTheme.Colors.warning
        case .idle:   return NaniTheme.Colors.textTertiary
        case .off:    return NaniTheme.Colors.textTertiary.opacity(0.5)
        }
    }
}

// MARK: - Brand Mark
//
// The Nani "!" sigil rendered as a SwiftUI element. Used in sidebar
// headers, menu bar popover, and onboarding. App icon (PNG) is shown
// at larger sizes in About / Onboarding hero.

struct BrandMark: View {
    var size: CGFloat = 26
    var includesShadow: Bool = true

    var body: some View {
        Group {
            if let nsImage = NSImage(named: "AppIcon") {
                Image(nsImage: nsImage)
                    .resizable()
                    .interpolation(.high)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.27))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.27)
                        .fill(NaniTheme.Colors.accent)
        
                    Text("N")
                        .font(.system(size: size * 0.58, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .offset(y: -1)
                }
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.27)
                .stroke(NaniTheme.Colors.panelInk, lineWidth: 1)
        )
        .shadow(
            color: includesShadow ? NaniTheme.Colors.accentPress.opacity(0.5) : .clear,
            radius: 0, x: 0, y: 1.5
        )
    }
}

// MARK: - Appearance Mode

/// User-selectable appearance preference. Persisted under `nani.appearance`.
enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light  = "Light"
    case dark   = "Dark"

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light:  return NSAppearance(named: .aqua)
        case .dark:   return NSAppearance(named: .darkAqua)
        }
    }

    @MainActor
    func apply() {
        NSApp.appearance = nsAppearance
        for window in NSApp.windows {
            window.appearance = nsAppearance
        }
    }
}
