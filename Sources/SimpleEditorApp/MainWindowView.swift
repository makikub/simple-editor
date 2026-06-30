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
            EditorContentView()
            Divider()
            StatusBarView()
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}

private struct HeaderView: View {
    @EnvironmentObject private var editor: EditorViewModel
    @State private var isSearchExpanded = false

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(editor.title)
                        .font(.headline)
                        .lineLimit(1)
                    if isDebugBuild {
                        Text("Debug build")
                            .font(.caption2)
                            .foregroundStyle(Color.orange)
                    }
                }
                .frame(minWidth: 180, alignment: .leading)

                Spacer()

                Picker("Mode", selection: Binding(get: { editor.mode }, set: editor.setMode)) {
                    ForEach(EditorMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 280)

                Spacer()

                HStack(spacing: 6) {
                    HeaderIconButton(
                        title: isSearchExpanded ? "Hide Search" : "Search",
                        systemImage: "magnifyingglass",
                        isActive: isSearchExpanded
                    ) {
                        withAnimation(.snappy(duration: 0.18)) {
                            isSearchExpanded.toggle()
                        }
                    }

                    HeaderIconButton(title: "Open", systemImage: "folder") {
                        editor.openWithPanel()
                    }

                    HeaderIconButton(title: "Save", systemImage: "square.and.arrow.down") {
                        editor.save()
                    }
                    .disabled(!editor.canSave)

                    Menu {
                        Button("Save As...") { editor.saveAs() }
                    } label: {
                        Image(systemName: "ellipsis")
                            .frame(width: 28, height: 28)
                    }
                    .menuStyle(.borderlessButton)
                    .buttonStyle(.plain)
                    .help("More")
                    .glassControl(active: false)
                }
            }

            if isSearchExpanded {
                SearchBarView()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.28), lineWidth: 0.7)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
            if isDebugBuild {
                Color.orange.opacity(0.06)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 0.5)
        }
    }

    private var isDebugBuild: Bool {
        BuildFlavor.name == "DEBUG"
    }
}

private struct HeaderIconButton: View {
    var title: String
    var systemImage: String
    var isActive = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .help(title)
        .glassControl(active: isActive)
    }
}

private struct GlassControlModifier: ViewModifier {
    var active: Bool

    func body(content: Content) -> some View {
        content
            .foregroundStyle(active ? Color.accentColor : Color.primary)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(active ? 0.42 : 0.26), lineWidth: 0.7)
            )
            .shadow(color: Color.black.opacity(active ? 0.16 : 0.08), radius: active ? 8 : 4, x: 0, y: 2)
            .contentShape(Circle())
    }
}

private extension View {
    func glassControl(active: Bool) -> some View {
        modifier(GlassControlModifier(active: active))
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
