import SwiftUI

// MARK: - Brand
//
// The Dealt brand: a cream card on a night sky, with five dots rising and setting across it,
// one per life stage. Same geometry as the app icon (brand/make_icons.py) and BRAND.md.

enum Brand {
    /// Night sky, top and bottom of the icon background.
    static let nightTop = Color(red: 0x2D / 255, green: 0x26 / 255, blue: 0x67 / 255)
    static let nightBottom = Color(red: 0x14 / 255, green: 0x10 / 255, blue: 0x30 / 255)
    /// The card face.
    static let cream = Color(red: 0xFF / 255, green: 0xF8 / 255, blue: 0xEC / 255)
    /// Ink for lines and text on cream.
    static let ink = Color(red: 0x1C / 255, green: 0x18 / 255, blue: 0x38 / 255)

    /// The one place ProgrammX appears in the app.
    static var credit: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        return "Dealt " + version + " · Made by ProgrammX"
    }

    static var night: LinearGradient {
        LinearGradient(colors: [nightTop, nightBottom], startPoint: .top, endPoint: .bottom)
    }

    /// Dawn to dusk: one colour per life stage, in order.
    static var stageColors: [Color] { Stage.allCases.map { $0.palette.accent } }
}

/// The brand mark: a card with the five-stage arc, two cards fanned behind it.
/// `height` is the front card's height; the mark is drawn at a 480:660 card ratio like the icon.
struct BrandMark: View {
    var height: CGFloat = 40
    var fanned: Bool = true

    private var width: CGFloat { height * 480 / 660 }
    private var radius: CGFloat { height * 72 / 660 }

    var body: some View {
        ZStack {
            if fanned {
                backCard(angle: -11, color: Color(red: 0x4B / 255, green: 0x43 / 255, blue: 0x90 / 255))
                backCard(angle: 11, color: Color(red: 0x5E / 255, green: 0x55 / 255, blue: 0xA8 / 255))
            }
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Brand.cream)
                .frame(width: width, height: height)
                .shadow(color: Color.black.opacity(0.18), radius: height * 0.04, y: height * 0.02)
            LifeArc()
                .frame(width: width * 0.86, height: height * 0.5)
        }
        .frame(width: fanned ? width * 1.55 : width, height: height * 1.04)
        .accessibilityHidden(true)
    }

    private func backCard(angle: Double, color: Color) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(color)
            .frame(width: width, height: height * 0.89)
            .offset(y: height * 0.055)
            .rotationEffect(.degrees(angle), anchor: UnitPoint(x: 0.5, y: 1.3))
    }
}

/// Five stage dots on a half circle above a horizon line.
private struct LifeArc: View {
    var body: some View {
        Canvas { context, size in
            // Icon geometry: arc radius 156, dot 41, horizon 26 below the dots, 52 past the ends.
            let unit = size.width / (2 * (156 + 52))
            let r = 156 * unit
            let dot = 41 * unit
            let centerX = size.width / 2
            let horizonY = size.height / 2 + (r + dot * 1.2) / 2
            let baseY = horizonY - dot - 26 * unit

            var horizon = Path()
            horizon.move(to: CGPoint(x: centerX - r - 52 * unit, y: horizonY))
            horizon.addLine(to: CGPoint(x: centerX + r + 52 * unit, y: horizonY))
            context.stroke(horizon, with: .color(Brand.ink.opacity(0.15)),
                           style: StrokeStyle(lineWidth: 14 * unit, lineCap: .round))

            for (i, color) in Brand.stageColors.enumerated() {
                let angle = Double.pi - Double(i) * Double.pi / 4
                let x = centerX + r * CGFloat(cos(angle))
                let y = baseY - r * CGFloat(sin(angle))
                let d = dot * (i == 2 ? 1.18 : 1)
                context.fill(Path(ellipseIn: CGRect(x: x - d, y: y - d, width: 2 * d, height: 2 * d)),
                             with: .color(color))
            }
        }
    }
}

/// "Dealt" set in the brand type: SF Pro Rounded, black weight, sentence case.
struct Wordmark: View {
    var size: CGFloat = 46

    var body: some View {
        Text("Dealt")
            .font(.system(size: size, weight: .black, design: .rounded))
            .tracking(-size * 0.01)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    VStack(spacing: 24) {
        HStack {
            Wordmark()
            Spacer()
            BrandMark(height: 44)
        }
        BrandMark(height: 200)
    }
    .padding()
}
