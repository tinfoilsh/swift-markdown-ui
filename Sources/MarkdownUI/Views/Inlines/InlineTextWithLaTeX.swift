import SwiftUI

struct InlineTextWithLaTeX: View {
  private let inlines: [InlineNode]

  init?(_ inlines: [InlineNode]) {
    guard inlines.contains(where: { if case .latex = $0 { return true } else { return false } }) else {
      return nil
    }
    self.inlines = inlines
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
        segment.view
      }
    }
  }

  private var segments: [ContentSegment] {
    var result: [ContentSegment] = []
    var textBuffer: [InlineNode] = []

    for inline in inlines {
      switch inline {
      case .latex(let latex, let isDisplay):
        if !textBuffer.isEmpty {
          result.append(.text(textBuffer))
          textBuffer = []
        }
        result.append(.latex(latex: latex, isDisplay: isDisplay))
      default:
        textBuffer.append(inline)
      }
    }

    if !textBuffer.isEmpty {
      result.append(.text(textBuffer))
    }

    return result
  }

  private enum ContentSegment {
    case text([InlineNode])
    case latex(latex: String, isDisplay: Bool)

    @ViewBuilder
    var view: some View {
      switch self {
      case .text(let nodes):
        InlineText(nodes)
      case .latex(let latex, let isDisplay):
        LaTeXView(latex: latex, isDisplay: isDisplay)
      }
    }
  }
}
