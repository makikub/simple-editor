import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject private var editor: EditorViewModel

    var body: some View {
        EditorShellView()
            .background(FileDropView { url in
                editor.open(url: url)
            })
    }
}

private struct EditorShellView: View {
    @EnvironmentObject private var editor: EditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            ErrorBanner(message: editor.alertMessage)
            RecoverySlot()
            Divider()
            EditorContentView()
            Divider()
            StatusBarView()
        }
    }
}

private struct HeaderView: View {
    @EnvironmentObject private var editor: EditorViewModel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(editor.title)
                        .font(.headline)
                    Text(buildDescription)
                        .font(.caption)
                        .foregroundStyle(buildLabelColor)
                }
                Spacer()
                Button("Open") { editor.openWithPanel() }
                Button("Save") { editor.save() }
                    .disabled(!editor.canSave)
                Button("Save As") { editor.saveAs() }
            }
            HStack(spacing: 12) {
                Picker("Mode", selection: Binding(get: { editor.mode }, set: editor.setMode)) {
                    ForEach(EditorMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 330)
                SearchBarView()
            }
        }
        .padding(12)
        .background(headerBackground)
    }

    private var buildDescription: String {
        BuildFlavor.name == "DEBUG" ? "Debug build: diagnostics are visible" : "Release build"
    }

    private var buildLabelColor: Color {
        BuildFlavor.name == "DEBUG" ? Color.orange : Color.secondary
    }

    private var headerBackground: Color {
        BuildFlavor.name == "DEBUG" ? Color.orange.opacity(0.08) : Color(nsColor: .windowBackgroundColor)
    }
}

private struct ErrorBanner: View {
    @EnvironmentObject private var editor: EditorViewModel
    var message: String?

    var body: some View {
        if let message {
            HStack {
                Text(message)
                    .foregroundStyle(Color.red)
                Spacer()
                Button("Dismiss") { editor.alertMessage = nil }
            }
            .padding(8)
            .background(Color.red.opacity(0.08))
        }
    }
}

private struct RecoverySlot: View {
    @EnvironmentObject private var editor: EditorViewModel

    var body: some View {
        if editor.recoveryText != nil {
            HStack {
                Text("A recovery draft is available.")
                    .font(.callout)
                Spacer()
                Button("Restore") { editor.restoreDraft() }
                Button("Discard") { editor.discardDraft() }
            }
            .padding(10)
            .background(Color.yellow.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(8)
        }
    }
}

private struct EditorContentView: View {
    @EnvironmentObject private var editor: EditorViewModel

    var body: some View {
        switch editor.mode {
        case .text:
            TextEditorView(text: Binding(get: { editor.file.text }, set: editor.updateText), wrapText: editor.settings.wrapText)
        case .csv:
            CSVGridView()
        case .fixedWidth:
            FixedWidthView()
        }
    }
}
