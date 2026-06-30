import SwiftUI

struct CSVGridView: View {
    @EnvironmentObject private var editor: EditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            controls
            Divider()
            if let document = editor.csvDocument {
                if !document.warnings.isEmpty {
                    warning(document.warnings.joined(separator: " "))
                }
                grid(document)
            } else {
                ContentUnavailableView("No CSV data", systemImage: "tablecells")
            }
        }
    }

    private var controls: some View {
        HStack {
            Toggle("Header", isOn: Binding(
                get: { editor.settings.csvHasHeaderDefault },
                set: { editor.settings.csvHasHeaderDefault = $0; editor.rebuildCSV() }
            ))
            Toggle("Auto delimiter", isOn: Binding(
                get: { editor.settings.csvAutoDetectDelimiter },
                set: { editor.settings.csvAutoDetectDelimiter = $0; editor.rebuildCSV() }
            ))
            Button("Add Row") { editor.addCSVRow() }
            Spacer()
            Text("Edits are written back on Save.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
    }

    private func warning(_ message: String) -> some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(.orange.opacity(0.08))
    }

    private func grid(_ document: CSVDocument) -> some View {
        ScrollView([.horizontal, .vertical]) {
            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    headerCell("#", width: 54)
                    ForEach(0..<max(document.columnCount, 1), id: \.self) { column in
                        headerCell(column < document.header.count ? document.header[column] : "Column \(column + 1)", width: 180)
                    }
                }
                ForEach(document.rows) { row in
                    GridRow {
                        Text("\(row.sourceIndex + 1)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 54, height: 28, alignment: .trailing)
                            .padding(.trailing, 6)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .border(Color(nsColor: .separatorColor))
                        ForEach(0..<max(document.columnCount, row.cells.count, 1), id: \.self) { column in
                            TextField("", text: Binding(
                                get: { column < row.cells.count ? row.cells[column] : "" },
                                set: { editor.updateCSVCell(rowID: row.id, column: column, value: $0) }
                            ))
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(width: 180, height: 28)
                            .padding(.horizontal, 6)
                            .border(Color(nsColor: .separatorColor))
                        }
                    }
                }
            }
            .padding(8)
        }
    }

    private func headerCell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .frame(width: width, height: 30, alignment: .leading)
            .padding(.horizontal, 6)
            .background(Color(nsColor: .selectedContentBackgroundColor).opacity(0.18))
            .border(Color(nsColor: .separatorColor))
    }
}
