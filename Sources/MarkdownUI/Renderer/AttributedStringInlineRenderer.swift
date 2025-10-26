import Foundation

extension InlineNode {
  func renderAttributedString(
    baseURL: URL?,
    textStyles: InlineTextStyles,
    softBreakMode: SoftBreak.Mode,
    attributes: AttributeContainer
  ) -> AttributedString {
    let nodesWithLaTeX = self.extractingLaTeX()
    var renderer = AttributedStringInlineRenderer(
      baseURL: baseURL,
      textStyles: textStyles,
      softBreakMode: softBreakMode,
      attributes: attributes
    )
    for node in nodesWithLaTeX {
      renderer.render(node)
    }
    return renderer.result.resolvingFonts()
  }
}

private struct AttributedStringInlineRenderer {
  var result = AttributedString()

  private let baseURL: URL?
  private let textStyles: InlineTextStyles
  private let softBreakMode: SoftBreak.Mode
  private var attributes: AttributeContainer
  private var shouldSkipNextWhitespace = false
  private var htmlAttributeStack: [(tag: String, savedAttributes: AttributeContainer, href: String?)] = []

  init(
    baseURL: URL?,
    textStyles: InlineTextStyles,
    softBreakMode: SoftBreak.Mode,
    attributes: AttributeContainer
  ) {
    self.baseURL = baseURL
    self.textStyles = textStyles
    self.softBreakMode = softBreakMode
    self.attributes = attributes
  }

  mutating func render(_ inline: InlineNode) {
    switch inline {
    case .text(let content):
      self.renderText(content)
    case .softBreak:
      self.renderSoftBreak()
    case .lineBreak:
      self.renderLineBreak()
    case .code(let content):
      self.renderCode(content)
    case .html(let content):
      self.renderHTML(content)
    case .latex(let latex, let isDisplay):
      self.renderLaTeX(latex, isDisplay: isDisplay)
    case .emphasis(let children):
      self.renderEmphasis(children: children)
    case .strong(let children):
      self.renderStrong(children: children)
    case .strikethrough(let children):
      self.renderStrikethrough(children: children)
    case .link(let destination, let children):
      self.renderLink(destination: destination, children: children)
    case .image(let source, let children):
      self.renderImage(source: source, children: children)
    }
  }

  private mutating func renderText(_ text: String) {
    var text = text

    if self.shouldSkipNextWhitespace {
      self.shouldSkipNextWhitespace = false
      text = text.replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression)
    }

    self.result += .init(text, attributes: self.attributes)
  }

  private mutating func renderSoftBreak() {
    switch softBreakMode {
    case .space where self.shouldSkipNextWhitespace:
      self.shouldSkipNextWhitespace = false
    case .space:
      self.result += .init(" ", attributes: self.attributes)
    case .lineBreak:
      self.renderLineBreak()
    }
  }

  private mutating func renderLineBreak() {
    self.result += .init("\n", attributes: self.attributes)
  }

  private mutating func renderCode(_ code: String) {
    self.result += .init(code, attributes: self.textStyles.code.mergingAttributes(self.attributes))
  }

  private mutating func renderHTML(_ html: String) {
    guard let tag = HTMLTag(html) else {
      self.renderText(html)
      return
    }

    let tagName = tag.name.lowercased()

    switch tagName {
    case "br":
      self.renderLineBreak()
      self.shouldSkipNextWhitespace = true
    case "b", "strong":
      if tag.isClosing {
        if let index = htmlAttributeStack.lastIndex(where: { $0.tag == "b" || $0.tag == "strong" }) {
          self.attributes = htmlAttributeStack[index].savedAttributes
          htmlAttributeStack.remove(at: index)
        }
      } else if !tag.isSelfClosing {
        htmlAttributeStack.append((tag: tagName, savedAttributes: self.attributes, href: nil))
        self.attributes = self.textStyles.strong.mergingAttributes(self.attributes)
      }
    case "i", "em":
      if tag.isClosing {
        if let index = htmlAttributeStack.lastIndex(where: { $0.tag == "i" || $0.tag == "em" }) {
          self.attributes = htmlAttributeStack[index].savedAttributes
          htmlAttributeStack.remove(at: index)
        }
      } else if !tag.isSelfClosing {
        htmlAttributeStack.append((tag: tagName, savedAttributes: self.attributes, href: nil))
        self.attributes = self.textStyles.emphasis.mergingAttributes(self.attributes)
      }
    case "a":
      if tag.isClosing {
        if let index = htmlAttributeStack.lastIndex(where: { $0.tag == "a" }) {
          self.attributes = htmlAttributeStack[index].savedAttributes
          htmlAttributeStack.remove(at: index)
        }
      } else if !tag.isSelfClosing {
        htmlAttributeStack.append((tag: tagName, savedAttributes: self.attributes, href: tag.href))
        self.attributes = self.textStyles.link.mergingAttributes(self.attributes)
        if let href = tag.href {
          self.attributes.link = URL(string: href, relativeTo: self.baseURL)
        }
      }
    default:
      self.renderText(html)
    }
  }

  private mutating func renderLaTeX(_ latex: String, isDisplay: Bool) {
    var latexAttributes = self.attributes
    latexAttributes.latexContent = latex
    latexAttributes.isDisplayLaTeX = isDisplay

    if isDisplay {
      self.result += .init("\n", attributes: self.attributes)
    }

    self.result += .init(latex, attributes: latexAttributes)

    if isDisplay {
      self.result += .init("\n", attributes: self.attributes)
    }
  }

  private mutating func renderEmphasis(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.emphasis.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderStrong(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.strong.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderStrikethrough(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.strikethrough.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderLink(destination: String, children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.link.mergingAttributes(self.attributes)
    self.attributes.link = URL(string: destination, relativeTo: self.baseURL)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderImage(source: String, children: [InlineNode]) {
    // AttributedString does not support images
  }
}

extension TextStyle {
  fileprivate func mergingAttributes(_ attributes: AttributeContainer) -> AttributeContainer {
    var newAttributes = attributes
    self._collectAttributes(in: &newAttributes)
    return newAttributes
  }
}
