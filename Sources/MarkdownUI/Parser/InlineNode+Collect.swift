import Foundation

extension Sequence where Element == InlineNode {
  func collect<Result>(_ c: (InlineNode) throws -> [Result]) rethrows -> [Result] {
    try self.flatMap { try $0.collect(c) }
  }

  func containsLaTeX() -> Bool {
    self.contains { $0.containsLaTeX() }
  }
}

extension InlineNode {
  func collect<Result>(_ c: (InlineNode) throws -> [Result]) rethrows -> [Result] {
    try self.children.collect(c) + c(self)
  }

  func containsLaTeX() -> Bool {
    if case .latex = self {
      return true
    }
    return self.children.containsLaTeX()
  }
}
