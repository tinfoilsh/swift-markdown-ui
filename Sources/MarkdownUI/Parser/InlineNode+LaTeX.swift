import Foundation

private enum LaTeXRegex {
  static let display = try! NSRegularExpression(pattern: #"\\\[\s*(.*?)\s*\\\]"#, options: [.dotMatchesLineSeparators])
  static let inline = try! NSRegularExpression(pattern: #"\\\(\s*(.*?)\s*\\\)"#, options: [])
}

extension Sequence where Element == InlineNode {
  func extractingLaTeX() -> [InlineNode] {
    // First, merge consecutive text nodes (cmark splits \[...\] into separate text nodes)
    let merged = self.mergingConsecutiveTextNodes()
    print("[LaTeX Debug] Merged \(Array(self).count) nodes into \(merged.count) nodes")
    // Then extract LaTeX from the merged nodes
    return merged.flatMap { $0.extractingLaTeX() }
  }

  private func mergingConsecutiveTextNodes() -> [InlineNode] {
    var result: [InlineNode] = []
    var accumulatedText = ""

    for (i, node) in self.enumerated() {
      if case .text(let content) = node {
        print("[LaTeX Debug]   mergingConsecutiveTextNodes: Node \(i) is text: \"\(content.prefix(30))\"")
        accumulatedText += content
      } else if case .softBreak = node {
        print("[LaTeX Debug]   mergingConsecutiveTextNodes: Node \(i) is softBreak, treating as newline in text")
        accumulatedText += "\n"
      } else if case .lineBreak = node {
        print("[LaTeX Debug]   mergingConsecutiveTextNodes: Node \(i) is lineBreak, treating as newline in text")
        accumulatedText += "\n"
      } else {
        print("[LaTeX Debug]   mergingConsecutiveTextNodes: Node \(i) is NOT text: \(node)")
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
    case .code, .html:
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
    var result: [InlineNode] = []
    var lastIndex = text.startIndex

    let nsText = text as NSString
    let fullRange = NSRange(location: 0, length: nsText.length)

    var matches: [(range: NSRange, latex: String, isDisplay: Bool)] = []

    print("[LaTeX Debug] Extracting from text: \(text.prefix(100))")

    LaTeXRegex.display.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
      guard let match = match, match.numberOfRanges >= 2 else { return }
      let contentRange = match.range(at: 1)
      if let swiftRange = Range(contentRange, in: text) {
        let latex = String(text[swiftRange])
        print("[LaTeX Debug] Found display LaTeX: \(latex)")
        matches.append((range: match.range, latex: latex, isDisplay: true))
      }
    }

    LaTeXRegex.inline.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
      guard let match = match, match.numberOfRanges >= 2 else { return }
      let contentRange = match.range(at: 1)

      let overlaps = matches.contains { existing in
        NSIntersectionRange(existing.range, match.range).length > 0
      }

      if !overlaps, let swiftRange = Range(contentRange, in: text) {
        let latex = String(text[swiftRange])
        print("[LaTeX Debug] Found inline LaTeX: \(latex)")
        matches.append((range: match.range, latex: latex, isDisplay: false))
      }
    }

    matches.sort { $0.range.location < $1.range.location }

    for match in matches {
      guard let swiftRange = Range(match.range, in: text) else { continue }

      if lastIndex < swiftRange.lowerBound {
        let textContent = String(text[lastIndex..<swiftRange.lowerBound])
        if !textContent.isEmpty {
          result.append(.text(textContent))
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

    if matches.isEmpty {
      print("[LaTeX Debug] No LaTeX found in text")
    } else {
      print("[LaTeX Debug] Created \(matches.count) LaTeX nodes")
    }

    return result.isEmpty ? [.text(text)] : result
  }
}
