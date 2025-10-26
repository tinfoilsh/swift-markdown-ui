import SwiftUI
import SwiftMath

struct MathView: UIViewRepresentable {
  let latex: String
  let isDisplay: Bool
  let fontSize: CGFloat
  let textColor: UIColor

  init(latex: String, isDisplay: Bool, fontSize: CGFloat = 16, textColor: UIColor = .label) {
    self.latex = latex
    self.isDisplay = isDisplay
    self.fontSize = fontSize
    self.textColor = textColor
  }

  func makeUIView(context: Context) -> MTMathUILabel {
    let label = MTMathUILabel()
    label.latex = latex
    label.labelMode = isDisplay ? .display : .text
    label.fontSize = isDisplay ? fontSize * 1.125 : fontSize
    label.textAlignment = isDisplay ? .center : .left
    label.textColor = textColor
    label.backgroundColor = .clear
    label.isUserInteractionEnabled = true
    label.contentInsets = UIEdgeInsets(
      top: isDisplay ? 8 : 2,
      left: 2,
      bottom: isDisplay ? 8 : 2,
      right: 2
    )
    label.setContentCompressionResistancePriority(.required, for: .vertical)
    label.setContentHuggingPriority(.required, for: .vertical)
    label.sizeToFit()
    return label
  }

  func updateUIView(_ uiView: MTMathUILabel, context: Context) {
    uiView.latex = latex
    uiView.labelMode = isDisplay ? .display : .text
    uiView.fontSize = isDisplay ? fontSize * 1.125 : fontSize
    uiView.textAlignment = isDisplay ? .center : .left
    uiView.textColor = textColor
    uiView.contentInsets = UIEdgeInsets(
      top: isDisplay ? 8 : 2,
      left: 2,
      bottom: isDisplay ? 8 : 2,
      right: 2
    )
    uiView.setContentCompressionResistancePriority(.required, for: .vertical)
    uiView.setContentHuggingPriority(.required, for: .vertical)
    uiView.sizeToFit()
  }
}

struct LaTeXView: View {
  let latex: String
  let isDisplay: Bool
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    if isDisplay {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 0) {
          Spacer(minLength: 0)
          MathView(
            latex: latex,
            isDisplay: true,
            textColor: colorScheme == .dark ? .white : UIColor.black.withAlphaComponent(0.8)
          )
          .fixedSize()
          Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
      }
      .frame(maxWidth: .infinity)
    } else {
      MathView(
        latex: latex,
        isDisplay: false,
        textColor: colorScheme == .dark ? .white : UIColor.black.withAlphaComponent(0.8)
      )
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
