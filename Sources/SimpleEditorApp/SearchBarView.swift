import SwiftUI

struct SearchBarView: View {
    @EnvironmentObject private var editor: EditorViewModel

    var body: some View {
        HStack(spacing: 8) {
            TextField("Search", text: $editor.searchQuery)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 180)
                .onChange(of: editor.searchQuery) { _, _ in editor.refreshSearch() }
            Toggle("Regex", isOn: $editor.regexSearch)
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
            Text("\(editor.searchMatches.count)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
            TextField("Replace", text: $editor.replaceText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 130)
                .disabled(editor.mode != .text)
            Button("Replace") { editor.replaceCurrent() }
                .disabled(editor.mode != .text || editor.searchMatches.isEmpty)
        }
    }
}
