// UI/Components/NuraSafeGradientSlider.swift
// Slider with magenta → violet fill aligned with the app accent gradient.

import SwiftUI

#if os(iOS)

struct NuraSafeGradientSlider: View {

    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    private let trackHeight: CGFloat = 5
    private let thumbSize: CGFloat = 20

    private var fraction: CGFloat {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return CGFloat((value - range.lowerBound) / span)
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let fillWidth = max(0, width * fraction)
            let thumbCenterX = width * fraction

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: trackHeight)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                NuraSafePalette.magenta,
                                NuraSafePalette.violet,
                                NuraSafePalette.deepViolet
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth, height: trackHeight)

                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 1)
                    .shadow(color: NuraSafePalette.magenta.opacity(0.25), radius: 4, x: 0, y: 0)
                    .offset(x: thumbCenterX - thumbSize / 2, y: 0)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        setValue(atX: gesture.location.x, width: width)
                    }
            )
        }
        .frame(height: 28)
        .accessibilityElement(children: .ignore)
        .accessibilityValue("\(value)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                let next = min(value + step, range.upperBound)
                value = snap(next)
            case .decrement:
                let prev = max(value - step, range.lowerBound)
                value = snap(prev)
            @unknown default:
                break
            }
        }
    }

    private func setValue(atX x: CGFloat, width: CGFloat) {
        guard width > 0 else { return }
        let p = min(max(Double(x / width), 0), 1)
        let raw = range.lowerBound + p * (range.upperBound - range.lowerBound)
        value = snap(raw)
    }

    private func snap(_ raw: Double) -> Double {
        let stepped = (raw / step).rounded() * step
        return min(max(stepped, range.lowerBound), range.upperBound)
    }
}

#endif
