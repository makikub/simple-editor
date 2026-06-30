import AppKit
import Foundation
import SwiftUI

@MainActor
final class EditorViewModel: ObservableObject {
    @Published var file: OpenedFile
    @Published var mode: EditorMode = .text
    @Published var settings = AppSettings()
    @Published var csvDocument: CSVDocument?
    @Published var searchQuery = ""
    @Published var replaceText = ""
    @Published var regexSearch = false
    @Published var selectedCSVColumn = "All"
    @Published var searchMatches: [SearchMatch] = []
    @Published var selectedMatchIndex = 0
    @Published var alertMessage: String?
    @Published var recoveryText: String?

    init() {
        let lineEndingInfo = LineEndingInfo(primary: .lf, lfCount: 0, crlfCount: 0, crCount: 0)
        self.file = OpenedFile(
            url: nil,
            originalData: Data(),
            text: "",
            encodingInfo: EncodingInfo(encoding: .utf8, hasBOM: false, confidence: 1, decodeError: nil),
            lineEndingInfo: lineEndingInfo,
            isDirty: false,
            isReadOnly: false,
            fileSize: 0,
            saveBlockReason: nil
        )
        self.recoveryText = CrashRecoveryService.loadDraft()
    }

    var title: String {
        "\(file.fileName)\(file.isDirty ? " *" : "")"
    }

    var canSave: Bool {
        !file.isReadOnly && file.encodingInfo.canSave && file.saveBlockReason == nil
    }

    var statusItems: [String] {
        var items = [
            file.encodingInfo.encoding.rawValue,
            file.lineEndingInfo.displayName,
            ByteCountFormatter.string(fromByteCount: Int64(file.fileSize), countStyle: .file),
            "Lines \(lineCount)",
            "Build \(BuildFlavor.name)"
        ]
        if mode == .csv, let csvDocument {
            items.append("CSV \(csvDocument.columnCount) cols")
            items.append("\(csvDocument.rows.count) rows")
        }
        if file.isDirty { items.append("Unsaved") }
        if file.isReadOnly { items.append("Read only") }
        if let reason = file.saveBlockReason { items.append("Save blocked: \(reason)") }
        return items
    }

    var lineCount: Int {
        max(file.text.components(separatedBy: "\n").count, 1)
    }

    func newDocument() {
        file = OpenedFile(
            url: nil,
            originalData: Data(),
            text: "",
            encodingInfo: EncodingInfo(encoding: settings.defaultEncoding, hasBOM: settings.defaultEncoding == .utf8BOM, confidence: 1, decodeError: nil),
            lineEndingInfo: LineEndingInfo(primary: settings.newFileLineEnding, lfCount: 0, crlfCount: 0, crCount: 0),
            isDirty: false,
            isReadOnly: false,
            fileSize: 0,
            saveBlockReason: nil
        )
        csvDocument = nil
        searchMatches = []
        CrashRecoveryService.clearDraft()
    }

    func openWithPanel() {
        guard let url = PanelService.openFileURL() else { return }
        open(url: url)
    }

    func open(url: URL) {
        do {
            file = try FileOpenService.open(url: url)
            mode = initialMode(for: url)
            rebuildCSV()
            refreshSearch()
            CrashRecoveryService.clearDraft()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func save() {
        if file.url == nil {
            saveAs()
            return
        }
        save(to: file.url)
    }

    func saveAs() {
        guard let url = PanelService.saveFileURL(defaultName: file.fileName) else { return }
        save(to: url)
    }

    func save(to url: URL?) {
        do {
            var nextFile = file
            if mode == .csv, let csvDocument {
                nextFile.text = CSVSerializeService.serialize(csvDocument, lineEnding: file.lineEndingInfo.primary)
            }
            nextFile.saveBlockReason = fixedWidthSaveBlockReason(for: nextFile.text)
            file = try FileSaveService.save(file: nextFile, to: url, createBackup: settings.createBackupOnSave)
            rebuildCSV()
            CrashRecoveryService.clearDraft()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func updateText(_ text: String) {
        guard file.text != text else { return }
        file.text = text
        file.isDirty = true
        file.fileSize = EncodingService.byteCount(text, encoding: file.encodingInfo.encoding)
        file.saveBlockReason = fixedWidthSaveBlockReason(for: text)
        if settings.crashRecovery {
            CrashRecoveryService.saveDraft(text)
        }
        if mode == .csv {
            rebuildCSV()
        }
        refreshSearch()
    }

    func restoreDraft() {
        guard let recoveryText else { return }
        updateText(recoveryText)
        self.recoveryText = nil
    }

    func discardDraft() {
        recoveryText = nil
        CrashRecoveryService.clearDraft()
    }

    func setMode(_ mode: EditorMode) {
        self.mode = mode
        if mode == .csv {
            rebuildCSV()
        }
    }

    func rebuildCSV() {
        let delimiter = settings.csvAutoDetectDelimiter
            ? CSVParseService.detectDelimiter(text: file.text, url: file.url)
            : (csvDocument?.delimiter ?? .comma)
        csvDocument = CSVParseService.parse(text: file.text, delimiter: delimiter, hasHeader: settings.csvHasHeaderDefault)
    }

    func updateCSVCell(rowID: CSVRow.ID, column: Int, value: String) {
        guard var document = csvDocument,
              let rowIndex = document.rows.firstIndex(where: { $0.id == rowID }) else { return }
        while document.rows[rowIndex].cells.count <= column {
            document.rows[rowIndex].cells.append("")
        }
        document.rows[rowIndex].cells[column] = value
        document.rows[rowIndex].isEdited = true
        csvDocument = document
        file.isDirty = true
        if settings.crashRecovery {
            CrashRecoveryService.saveDraft(CSVSerializeService.serialize(document, lineEnding: file.lineEndingInfo.primary))
        }
        refreshSearch()
    }

    func addCSVRow() {
        guard var document = csvDocument else { return }
        document.rows.append(CSVRow(sourceIndex: document.rows.count, cells: Array(repeating: "", count: max(document.columnCount, 1)), originalText: "", isEdited: true))
        csvDocument = document
        file.isDirty = true
    }

    func deleteCSVRows(at offsets: IndexSet) {
        guard var document = csvDocument else { return }
        document.rows.remove(atOffsets: offsets)
        csvDocument = document
        file.isDirty = true
    }

    func refreshSearch() {
        if mode == .csv, let csvDocument {
            let columnIndex = csvColumnIndex()
            var synthetic = ""
            for row in csvDocument.rows {
                let cells = columnIndex.map { [$0 < row.cells.count ? row.cells[$0] : ""] } ?? row.cells
                synthetic += cells.joined(separator: "\t") + "\n"
            }
            searchMatches = SearchService.matches(in: synthetic, query: searchQuery, regex: regexSearch)
        } else {
            searchMatches = SearchService.matches(in: file.text, query: searchQuery, regex: regexSearch)
        }
        selectedMatchIndex = searchMatches.isEmpty ? 0 : min(selectedMatchIndex, searchMatches.count - 1)
    }

    func findNext() {
        refreshSearch()
        guard !searchMatches.isEmpty else { return }
        selectedMatchIndex = (selectedMatchIndex + 1) % searchMatches.count
    }

    func replaceCurrent() {
        guard mode == .text, !searchMatches.isEmpty, selectedMatchIndex < searchMatches.count else { return }
        let match = searchMatches[selectedMatchIndex]
        guard let range = Range(match.range, in: file.text) else { return }
        var next = file.text
        next.replaceSubrange(range, with: replaceText)
        updateText(next)
    }

    func chooseEncoding(_ encoding: SupportedEncoding) {
        file.encodingInfo.encoding = encoding
        file.encodingInfo.hasBOM = encoding == .utf8BOM
        file.saveBlockReason = nil
    }

    private func csvColumnIndex() -> Int? {
        guard selectedCSVColumn != "All", let document = csvDocument else { return nil }
        return document.header.firstIndex(of: selectedCSVColumn)
    }

    private func initialMode(for url: URL) -> EditorMode {
        let ext = url.pathExtension.lowercased()
        if ext == "csv" || ext == "tsv" { return .csv }
        return .text
    }

    private func fixedWidthSaveBlockReason(for text: String) -> String? {
        guard settings.fixedWidthSaveCheck, mode == .fixedWidth else { return nil }
        let lengths = Set(text.components(separatedBy: "\n").filter { !$0.isEmpty }.map(\.count))
        return lengths.count > 1 ? "Fixed-width line lengths are not uniform." : nil
    }
}
