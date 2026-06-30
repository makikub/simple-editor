import SwiftUI

struct FixedWidthView: View {
    @EnvironmentObject private var editor: EditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            controls
            Divider()
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    ruler(label: "char", transform: { $0 })
                    ruler(label: "byte", transform: { $0 })
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        HStack(spacing: 0) {
                            Text(String(format: "%03d | ", index + 1))
                                .foregroundStyle(.secondary)
                            Text(line)
                                .foregroundStyle(lineWarning(line) ? .orange : .primary)
                            Spacer(minLength: 20)
                            Text(" chars \(line.count) / bytes \(EncodingService.byteCount(line, encoding: editor.file.encodingInfo.encoding))")
                                .foregroundStyle(.secondary)
                        }
                        .font(.system(size: 13, design: .monospaced))
                        .padding(.vertical, 2)
                    }
                }
                .padding(12)
            }
        }
    }

    private var lines: [String] {
        editor.file.text.components(separatedBy: "\n")
    }

    private var controls: some View {
        HStack {
            Text("Guides")
            TextField("8,20,32", text: Binding(
                get: { editor.settings.fixedWidthGuides },
                set: { editor.settings.fixedWidthGuides = $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(width: 220)
            Toggle("Block save if line lengths differ", isOn: Binding(
                get: { editor.settings.fixedWidthSaveCheck },
                set: { editor.settings.fixedWidthSaveCheck = $0; editor.updateText(editor.file.text) }
            ))
            Spacer()
            if editor.file.saveBlockReason != nil {
                Text(editor.file.saveBlockReason ?? "")
                    .foregroundStyle(.orange)
            }
        }
        .padding(8)
    }

    private func ruler(label: String, transform: (Int) -> Int) -> some View {
        let marks = (1...80).map { number in
            guidePositions.contains(number) ? "|" : String(transform(number) % 10)
        }.joined()
        return HStack(spacing: 0) {
            Text(label.padding(toLength: 6, withPad: " ", startingAt: 0))
                .foregroundStyle(.secondary)
            Text(marks)
        }
        .font(.system(size: 13, design: .monospaced))
    }

    private var guidePositions: Set<Int> {
        Set(editor.settings.fixedWidthGuides.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
    }

    private func lineWarning(_ line: String) -> Bool {
        guard let firstLength = lines.first(where: { !$0.isEmpty })?.count else { return false }
        return !line.isEmpty && line.count != firstLength
    }
}
