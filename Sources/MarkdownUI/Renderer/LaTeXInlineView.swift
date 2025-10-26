import UIKit
import SwiftMath

struct LaTeXInlineView {
  let latex: String
  let isDisplay: Bool

  func snapshot() -> UIImage {
    let label = MTMathUILabel()
    label.latex = latex
    label.labelMode = isDisplay ? .display : .text
    label.fontSize = isDisplay ? 18 : 16
    label.textAlignment = isDisplay ? .center : .left

    label.sizeToFit()

    let renderer = UIGraphicsImageRenderer(size: label.bounds.size)
    return renderer.image { context in
      label.layer.render(in: context.cgContext)
    }
  }
}
