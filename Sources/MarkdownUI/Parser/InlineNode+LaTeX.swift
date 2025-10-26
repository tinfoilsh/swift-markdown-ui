import Foundation

extension Sequence where Element == InlineNode {
  func extractingLaTeX() -> [InlineNode] {
    let merged = self.mergingConsecutiveTextNodes()
    return merged.flatMap { $0.extractingLaTeX() }
  }

  private func mergingConsecutiveTextNodes() -> [InlineNode] {
    var result: [InlineNode] = []
    var accumulatedText = ""

    for node in self {
      switch node {
      case .text(let content):
        accumulatedText += content
      default:
        if !accumulatedText.isEmpty {
          result.append(.text(accumulatedText))
          accumulatedText = ""
        }
        result.append(node)
      }
    }

    if !accumulatedText.isEmpty {
      result.append(.text(accumulatedText))
    }

    return result
  }
}

extension InlineNode {
  func extractingLaTeX() -> [InlineNode] {
    switch self {
    case .text(let content):
      return extractLaTeXFromText(content)
    case .code, .html, .softBreak, .lineBreak:
      return [self]
    case .emphasis(let children):
      return [.emphasis(children: children.extractingLaTeX())]
    case .strong(let children):
      return [.strong(children: children.extractingLaTeX())]
    case .strikethrough(let children):
      return [.strikethrough(children: children.extractingLaTeX())]
    case .link(let destination, let children):
      return [.link(destination: destination, children: children.extractingLaTeX())]
    default:
      return [self]
    }
  }

  private func extractLaTeXFromText(_ text: String) -> [InlineNode] {
    guard let displayRegex = try? NSRegularExpression(
      pattern: #"\\[(.+?)\\]"#,
      options: [.dotMatchesLineSeparators]
    ), let inlineRegex = try? NSRegularExpression(
      pattern: #"\\((.+?)\\)"#,
      options: []
    ) else {
      return [.text(text)]
    }

    var result: [InlineNode] = []
    var lastIndex = text.startIndex

    let nsText = text as NSString
    let fullRange = NSRange(location: 0, length: nsText.length)

    var matches: [(range: NSRange, latex: String, isDisplay: Bool)] = []

    displayRegex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
      guard let match = match, match.numberOfRanges >= 2 else { return }
      let contentRange = match.range(at: 1)
      if let swiftRange = Range(contentRange, in: text) {
        let latex = String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        matches.append((range: match.range, latex: latex, isDisplay: true))
      }
    }

    inlineRegex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
      guard let match = match, match.numberOfRanges >= 2 else { return }
      let contentRange = match.range(at: 1)

      let overlaps = matches.contains { existing in
        NSIntersectionRange(existing.range, match.range).length > 0
      }

      if !overlaps, let swiftRange = Range(contentRange, in: text) {
        let latex = String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        matches.append((range: match.range, latex: latex, isDisplay: false))
      }
    }

    matches.sort { $0.range.location < $1.range.location }

    for match in matches {
      guard let swiftRange = Range(match.range, in: text) else { continue }

      if lastIndex < swiftRange.lowerBound {
        let textSegment = String(text[lastIndex..<swiftRange.lowerBound])
        if !textSegment.isEmpty {
          result.append(.text(textSegment))
        }
      }

      result.append(.latex(match.latex, isDisplay: match.isDisplay))
      lastIndex = swiftRange.upperBound
    }

    if lastIndex < text.endIndex {
      let remainingText = String(text[lastIndex...])
      if !remainingText.isEmpty {
        result.append(.text(remainingText))
      }
    }

    if result.isEmpty && !text.isEmpty {
      result.append(.text(text))
    }

    return result
  }
}
