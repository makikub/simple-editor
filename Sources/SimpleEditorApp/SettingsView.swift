import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var editor: EditorViewModel

    var body: some View {
        Form {
            Picker("Default encoding", selection: $editor.settings.defaultEncoding) {
                ForEach(SupportedEncoding.allCases) { encoding in
                    Text(encoding.rawValue).tag(encoding)
                }
            }
            Picker("New file line ending", selection: $editor.settings.newFileLineEnding) {
                ForEach(LineEnding.allCases, id: \.self) { lineEnding in
                    Text(lineEnding.rawValue).tag(lineEnding)
                }
            }
            Toggle("Create .bak on save", isOn: $editor.settings.createBackupOnSave)
            Toggle("Fixed-width save check", isOn: $editor.settings.fixedWidthSaveCheck)
            Toggle("Wrap text", isOn: $editor.settings.wrapText)
            Toggle("CSV header by default", isOn: $editor.settings.csvHasHeaderDefault)
            Toggle("Auto-detect CSV delimiter", isOn: $editor.settings.csvAutoDetectDelimiter)
            Toggle("Crash recovery draft", isOn: $editor.settings.crashRecovery)
        }
        .padding()
    }
}
