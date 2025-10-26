import Foundation

enum LaTeXPreprocessor {
  /// Protect LaTeX expressions from markdown processing by double-escaping backslashes
  static func protect(_ markdown: String) -> String {
    var result = markdown

    // Double escape LaTeX delimiters: \[ becomes \\[
    // Markdown will treat the first \ as escaping the second \
    // So \\[ survives as \[ after markdown processing
    result = result.replacingOccurrences(of: "\\[", with: "\\\\[")
    result = result.replacingOccurrences(of: "\\]", with: "\\\\]")
    result = result.replacingOccurrences(of: "\\(", with: "\\\\(")
    result = result.replacingOccurrences(of: "\\)", with: "\\\\)")

    return result
  }

  /// Restore is a no-op since markdown processing handles the escaping
  static func restore(_ text: String) -> String {
    return text
  }
}
