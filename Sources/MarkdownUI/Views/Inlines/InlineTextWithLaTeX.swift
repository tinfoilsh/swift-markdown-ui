import SwiftUI
import SwiftMath

struct InlineTextWithLaTeX: View {
  @Environment(\.inlineImageProvider) private var inlineImageProvider
  @Environment(\.baseURL) private var baseURL
  @Environment(\.imageBaseURL) private var imageBaseURL
  @Environment(\.softBreakMode) private var softBreakMode
  @Environment(\.theme) private var theme

  @State private var inlineImages: [String: Image] = [:]

  private let inlines: [InlineNode]

  init(_ inlines: [InlineNode]) {
    self.inlines = inlines
  }

  var body: some View {
    TextStyleAttributesReader { attributes in
      if self.hasDisplayLaTeX {
        VStack(alignment: .leading, spacing: 0) {
          ForEach(Array(self.segments.enumerated()), id: \.offset) { _, segment in
            self.renderSegment(segment, attributes: attributes)
          }
        }
      } else if self.hasInlineLaTeX {
        self.renderMixedContent(attributes: attributes)
      } else {
        self.renderInlineContent(self.inlines, attributes: attributes)
      }
    }
    .task(id: self.inlines) {
      self.inlineImages = (try? await self.loadInlineImages()) ?? [:]
    }
  }

  private var hasDisplayLaTeX: Bool {
    self.inlines.contains { node in
      if case .latex(_, let isDisplay) = node, isDisplay {
        return true
      }
      return false
    }
  }

  private var hasInlineLaTeX: Bool {
    self.inlines.contains { node in
      if case .latex(_, let isDisplay) = node, !isDisplay {
        return true
      }
      return false
    }
  }

  private var segments: [Segment] {
    var result: [Segment] = []
    var currentInlineNodes: [InlineNode] = []

    for inline in self.inlines {
      if case .latex(let latex, let isDisplay) = inline, isDisplay {
        if !currentInlineNodes.isEmpty {
          result.append(.inline(currentInlineNodes))
          currentInlineNodes = []
        }
        result.append(.display(latex))
      } else {
        currentInlineNodes.append(inline)
      }
    }

    if !currentInlineNodes.isEmpty {
      result.append(.inline(currentInlineNodes))
    }

    return result
  }

  private enum Segment {
    case inline([InlineNode])
    case display(String)
  }

  @ViewBuilder
  private func renderSegment(_ segment: Segment, attributes: AttributeContainer) -> some View {
    switch segment {
    case .display(let latex):
      MathView(equation: latex, fontSize: attributes.fontProperties?.size ?? 17, isDisplay: true)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 4)
    case .inline(let nodes):
      self.renderInlineContent(nodes, attributes: attributes)
    }
  }

  @ViewBuilder
  private func renderInlineContent(_ nodes: [InlineNode], attributes: AttributeContainer) -> some View {
    nodes.renderText(
      baseURL: self.baseURL,
      textStyles: InlineTextStyles(
        code: self.theme.code,
        emphasis: self.theme.emphasis,
        strong: self.theme.strong,
        strikethrough: self.theme.strikethrough,
        link: self.theme.link
      ),
      images: self.inlineImages,
      softBreakMode: self.softBreakMode,
      attributes: attributes
    )
  }

  private func loadInlineImages() async throws -> [String: Image] {
    let images = Set(self.inlines.compactMap(\.imageData))
    guard !images.isEmpty else { return [:] }

    return try await withThrowingTaskGroup(of: (String, Image).self) { taskGroup in
      for image in images {
        guard let url = URL(string: image.source, relativeTo: self.imageBaseURL) else {
          continue
        }

        taskGroup.addTask {
          (image.source, try await self.inlineImageProvider.image(with: url, label: image.alt))
        }
      }

      var inlineImages: [String: Image] = [:]

      for try await result in taskGroup {
        inlineImages[result.0] = result.1
      }

      return inlineImages
    }
  }
}
