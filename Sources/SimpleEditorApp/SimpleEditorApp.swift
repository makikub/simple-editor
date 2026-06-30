import SwiftUI

@main
struct SimpleEditorApp: App {
    @StateObject private var editor = EditorViewModel()

    var body: some Scene {
        WindowGroup(BuildFlavor.windowTitle) {
            MainWindowView()
                .environmentObject(editor)
                .frame(minWidth: 980, minHeight: 660)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New") { editor.newDocument() }
                    .keyboardShortcut("n", modifiers: .command)
                Button("Open...") { editor.openWithPanel() }
                    .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(after: .saveItem) {
                Button("Save") { editor.save() }
                    .keyboardShortcut("s", modifiers: .command)
                    .disabled(!editor.canSave)
                Button("Save As...") { editor.saveAs() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            CommandMenu("Find") {
                Button("Find Next") { editor.findNext() }
                    .keyboardShortcut("g", modifiers: .command)
                Button("Replace Current") { editor.replaceCurrent() }
                    .keyboardShortcut("r", modifiers: [.command, .option])
            }
        }
        Settings {
            SettingsView()
                .environmentObject(editor)
                .frame(width: 430)
        }
    }
}

enum BuildFlavor {
    static var name: String {
        #if DEBUG
        "DEBUG"
        #elseif RELEASE
        "RELEASE"
        #else
        "UNKNOWN"
        #endif
    }

    static var windowTitle: String {
        "Simple Editor \(name)"
    }
}
