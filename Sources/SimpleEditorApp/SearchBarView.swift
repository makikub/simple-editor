import SwiftUI

struct SearchBarView: View {
    @EnvironmentObject private var editor: EditorViewModel

    var body: some View {
        HStack(spacing: 8) {
            TextField("Search", text: $editor.searchQuery)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 220)
                .onChange(of: editor.searchQuery) { _, _ in editor.refreshSearch() }
            Toggle("Regex", isOn: $editor.regexSearch)
                .toggleStyle(.checkbox)
                .onChange(of: editor.regexSearch) { _, _ in editor.refreshSearch() }
            if editor.mode == .csv, let document = editor.csvDocument {
                Picker("Column", selection: $editor.selectedCSVColumn) {
                    Text("All").tag("All")
                    ForEach(document.header, id: \.self) { column in
                        Text(column).tag(column)
                    }
                }
                .frame(width: 140)
                .onChange(of: editor.selectedCSVColumn) { _, _ in editor.refreshSearch() }
            }
            Text("\(editor.searchMatches.count) matches")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 82, alignment: .trailing)
            TextField("Replace", text: $editor.replaceText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 150)
                .disabled(editor.mode != .text)
            Button {
                editor.replaceCurrent()
            } label: {
                Label("Replace", systemImage: "arrow.triangle.2.circlepath")
            }
                .disabled(editor.mode != .text || editor.searchMatches.isEmpty)
        }
        .controlSize(.small)
    }
}
