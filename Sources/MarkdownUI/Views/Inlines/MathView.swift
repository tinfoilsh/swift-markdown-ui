import SwiftUI
import SwiftMath

struct MathView: UIViewRepresentable {
    let equation: String
    let fontSize: CGFloat
    let isDisplay: Bool

    init(equation: String, fontSize: CGFloat, isDisplay: Bool = false) {
        self.equation = equation
        self.fontSize = fontSize
        self.isDisplay = isDisplay
    }

    func makeUIView(context: Context) -> MTMathUILabel {
        let label = MTMathUILabel()
        label.latex = equation
        label.fontSize = fontSize
        label.textAlignment = isDisplay ? .center : .left
        label.labelMode = isDisplay ? .display : .text
        return label
    }

    func updateUIView(_ uiView: MTMathUILabel, context: Context) {
        uiView.latex = equation
        uiView.fontSize = fontSize
        uiView.textAlignment = isDisplay ? .center : .left
        uiView.labelMode = isDisplay ? .display : .text
    }
}
