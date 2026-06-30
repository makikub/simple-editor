import SwiftUI

struct TextEditorView: View {
    @Binding var text: String
    var wrapText: Bool

    var body: some View {
        HStack(spacing: 0) {
            lineNumberGutter
            Divider()
            editor
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var editor: some View {
        TextEditor(text: $text)
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(Color(nsColor: .textColor))
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .textBackgroundColor))
            .padding(.leading, 4)
            .disableAutocorrection(true)
    }

    private var lineNumberGutter: some View {
        ScrollView(.vertical) {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(1...lineCount, id: \.self) { line in
                    Text("\(line)")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 44, height: 18, alignment: .trailing)
                }
            }
            .padding(.top, 8)
            .padding(.trailing, 6)
        }
        .frame(width: 54)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var lineCount: Int {
        max(text.split(separator: "\n", omittingEmptySubsequences: false).count, 1)
    }
}
