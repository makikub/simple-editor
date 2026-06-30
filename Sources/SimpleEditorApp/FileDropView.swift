import AppKit
import SwiftUI

struct FileDropView: NSViewRepresentable {
    var onDrop: (URL) -> Void

    func makeNSView(context: Context) -> DropCatcherView {
        let view = DropCatcherView()
        view.onDrop = onDrop
        return view
    }

    func updateNSView(_ nsView: DropCatcherView, context: Context) {
        nsView.onDrop = onDrop
    }
}

final class DropCatcherView: NSView {
    var onDrop: ((URL) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let string = sender.draggingPasteboard.string(forType: .fileURL),
              let url = URL(string: string) else { return false }
        onDrop?(url)
        return true
    }
}
