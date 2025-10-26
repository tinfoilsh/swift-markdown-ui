import SwiftUI
import SwiftMath

struct MathView: UIViewRepresentable {
    let equation: String
    let fontSize: CGFloat

    func makeUIView(context: Context) -> MTMathUILabel {
        let label = MTMathUILabel()
        label.latex = equation
        label.fontSize = fontSize
        label.textAlignment = .left
        label.labelMode = .text
        return label
    }

    func updateUIView(_ uiView: MTMathUILabel, context: Context) {
        uiView.latex = equation
        uiView.fontSize = fontSize
    }
}
