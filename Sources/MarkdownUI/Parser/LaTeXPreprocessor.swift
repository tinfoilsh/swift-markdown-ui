import Foundation

enum LaTeXPreprocessor {
  private static let displayPattern = #"\\\[(.*?)\\\]"#
  private static let inlinePattern = #"\\\((.*?)\\\)"#

  private static let displayRegex = try! NSRegularExpression(
    pattern: displayPattern,
    options: [.dotMatchesLineSeparators]
  )
  private static let inlineRegex = try! NSRegularExpression(
    pattern: inlinePattern,
    options: []
  )

  /// Protect LaTeX expressions from markdown processing by replacing backslashes
  static func protect(_ markdown: String) -> String {
    var result = markdown

    // Replace \[ with ￼LATEX_DISPLAY_START￼ and \] with ￼LATEX_DISPLAY_END￼
    result = result.replacingOccurrences(of: "\\[", with: "￼LATEX_DISPLAY_START￼")
    result = result.replacingOccurrences(of: "\\]", with: "￼LATEX_DISPLAY_END￼")

    // Replace \( with ￼LATEX_INLINE_START￼ and \) with ￼LATEX_INLINE_END￼
    result = result.replacingOccurrences(of: "\\(", with: "￼LATEX_INLINE_START￼")
    result = result.replacingOccurrences(of: "\\)", with: "￼LATEX_INLINE_END￼")

    return result
  }

  /// Restore protected LaTeX expressions after markdown processing
  static func restore(_ text: String) -> String {
    var result = text

    // Restore display LaTeX delimiters
    result = result.replacingOccurrences(of: "￼LATEX_DISPLAY_START￼", with: "\\[")
    result = result.replacingOccurrences(of: "￼LATEX_DISPLAY_END￼", with: "\\]")

    // Restore inline LaTeX delimiters
    result = result.replacingOccurrences(of: "￼LATEX_INLINE_START￼", with: "\\(")
    result = result.replacingOccurrences(of: "￼LATEX_INLINE_END￼", with: "\\)")

    return result
  }
}
