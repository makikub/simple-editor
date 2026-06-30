import SwiftUI

struct StatusBarView: View {
    @EnvironmentObject private var editor: EditorViewModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(editor.statusItems, id: \.self) { item in
                    Text(item)
                    if item != editor.statusItems.last {
                        Text("|").foregroundStyle(.tertiary)
                    }
                }
            }
            .font(.caption.monospaced())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
