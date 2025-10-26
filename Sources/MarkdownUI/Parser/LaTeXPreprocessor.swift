import Foundation

enum LaTeXPreprocessor {
  /// Protect LaTeX expressions from markdown processing by double-escaping backslashes
  static func protect(_ markdown: String) -> String {
    var result = markdown

    // Double escape LaTeX delimiters: \[ becomes \\[
    // Markdown will treat the first \ as escaping the second \
    // So \\[ survives as \[ after markdown processing
    let before = result
    result = result.replacingOccurrences(of: "\\[", with: "\\\\[")
    result = result.replacingOccurrences(of: "\\]", with: "\\\\]")
    result = result.replacingOccurrences(of: "\\(", with: "\\\\(")
    result = result.replacingOccurrences(of: "\\)", with: "\\\\)")

    if before != result {
      print("[LaTeX Debug] protect() found LaTeX delimiters")
      print("[LaTeX Debug] Before: \(before.prefix(200))")
      print("[LaTeX Debug] After: \(result.prefix(200))")
    }

    return result
  }

  /// Restore is a no-op since markdown processing handles the escaping
  static func restore(_ text: String) -> String {
    print("[LaTeX Debug] restore() called with: \(text.prefix(100))")
    return text
  }
}
