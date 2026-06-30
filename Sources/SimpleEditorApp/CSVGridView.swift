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
            Picker("Delimiter", selection: Binding(
                get: { editor.settings.csvDelimiter },
                set: { editor.settings.csvDelimiter = $0; editor.settings.csvAutoDetectDelimiter = false; editor.rebuildCSV() }
            )) {
                ForEach(CSVDelimiter.allCases) { delimiter in
                    Text(delimiter.title).tag(delimiter)
                }
            }
            .frame(width: 160)
            Button("Add Row") { editor.addCSVRow() }
            TextField("Filter", text: Binding(
                get: { editor.csvFilterQuery },
                set: { editor.csvFilterQuery = $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(width: 180)
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
        let rows = filteredRows(document.rows)
        return GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                    GridRow {
                        headerCell("#", width: 54)
                        ForEach(0..<max(document.columnCount, 1), id: \.self) { column in
                            headerCell(column < document.header.count ? document.header[column] : "Column \(column + 1)", width: 180)
                        }
                        headerCell("", width: 40)
                    }
                    ForEach(rows) { row in
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
                            Button {
                                editor.deleteCSVRow(rowID: row.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .frame(width: 40, height: 28)
                            .border(Color(nsColor: .separatorColor))
                            .help("Delete row")
                        }
                    }
                }
                .padding(8)
                .frame(
                    minWidth: geometry.size.width,
                    minHeight: geometry.size.height,
                    alignment: .topLeading
                )
            }
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

    private func filteredRows(_ rows: [CSVRow]) -> [CSVRow] {
        let query = editor.csvFilterQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return rows }
        return rows.filter { row in
            row.cells.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}
