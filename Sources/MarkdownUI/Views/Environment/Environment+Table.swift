import SwiftUI

extension View {
  /// Sets the table border style for the Markdown tables in a view hierarchy.
  ///
  /// Use this modifier to customize the table border style inside the body of
  /// the ``Theme/table`` block style.
  ///
  /// - Parameter tableBorderStyle: The border style to set.
  public func markdownTableBorderStyle(_ tableBorderStyle: TableBorderStyle) -> some View {
    self.environment(\.tableBorderStyle, tableBorderStyle)
  }

  /// Sets the table background style for the Markdown tables in a view hierarchy.
  ///
  /// Use this modifier to customize the table background style inside the body of
  /// the ``Theme/table`` block style.
  ///
  /// - Parameter tableBackgroundStyle: The background style to set.
  public func markdownTableBackgroundStyle(
    _ tableBackgroundStyle: TableBackgroundStyle
  ) -> some View {
    self.environment(\.tableBackgroundStyle, tableBackgroundStyle)
  }

  /// Sets the maximum width for table columns in Markdown tables.
  ///
  /// Use this modifier to control the maximum width of table columns. Tables will adapt
  /// to their content width up to this maximum and become horizontally scrollable if needed.
  ///
  /// - Parameter maxWidth: The maximum width for table columns, or nil for no limit.
  public func markdownTableMaxColumnWidth(_ maxWidth: CGFloat?) -> some View {
    self.environment(\.tableMaxColumnWidth, maxWidth)
  }
}

extension EnvironmentValues {
  var tableBorderStyle: TableBorderStyle {
    get { self[TableBorderStyleKey.self] }
    set { self[TableBorderStyleKey.self] = newValue }
  }

  var tableBackgroundStyle: TableBackgroundStyle {
    get { self[TableBackgroundStyleKey.self] }
    set { self[TableBackgroundStyleKey.self] = newValue }
  }

  var tableMaxColumnWidth: CGFloat? {
    get { self[TableMaxColumnWidthKey.self] }
    set { self[TableMaxColumnWidthKey.self] = newValue }
  }
}

private struct TableBorderStyleKey: EnvironmentKey {
  static let defaultValue = TableBorderStyle(color: .secondary)
}

private struct TableBackgroundStyleKey: EnvironmentKey {
  static let defaultValue = TableBackgroundStyle.clear
}

private struct TableMaxColumnWidthKey: EnvironmentKey {
  static let defaultValue: CGFloat? = nil
}
