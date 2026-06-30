import Foundation

enum EditorMode: String, CaseIterable, Identifiable {
    case text = "Text"
    case csv = "CSV"
    case fixedWidth = "Fixed Width"

    var id: String { rawValue }
}

enum SupportedEncoding: String, CaseIterable, Identifiable {
    case utf8 = "UTF-8"
    case utf8BOM = "UTF-8 BOM"
    case cp932 = "CP932 / Shift_JIS"

    var id: String { rawValue }
}

struct EncodingInfo {
    var encoding: SupportedEncoding
    var hasBOM: Bool
    var confidence: Double
    var decodeError: String?

    var canSave: Bool { decodeError == nil }
}

enum LineEnding: String, CaseIterable {
    case lf = "LF"
    case crlf = "CRLF"
    case cr = "CR"

    var characters: String {
        switch self {
        case .lf: "\n"
        case .crlf: "\r\n"
        case .cr: "\r"
        }
    }
}

struct LineEndingInfo {
    var primary: LineEnding
    var lfCount: Int
    var crlfCount: Int
    var crCount: Int

    var isMixed: Bool {
        [lfCount, crlfCount, crCount].filter { $0 > 0 }.count > 1
    }

    var displayName: String {
        if isMixed {
            "\(primary.rawValue) primary / mixed"
        } else {
            primary.rawValue
        }
    }
}

struct OpenedFile {
    var url: URL?
    var originalData: Data
    var text: String
    var encodingInfo: EncodingInfo
    var lineEndingInfo: LineEndingInfo
    var isDirty: Bool
    var isReadOnly: Bool
    var fileSize: Int
    var saveBlockReason: String?

    var fileName: String {
        url?.lastPathComponent ?? "Untitled"
    }
}

enum CSVDelimiter: String, CaseIterable, Identifiable {
    case comma = ","
    case tab = "\t"

    var id: String { rawValue }
    var title: String { self == .comma ? "Comma" : "Tab" }
}

struct CSVRow: Identifiable {
    let id = UUID()
    var sourceIndex: Int
    var cells: [String]
    var originalText: String
    var isEdited: Bool
}

struct CSVDocument {
    var delimiter: CSVDelimiter
    var hasHeader: Bool
    var header: [String]
    var rows: [CSVRow]
    var warnings: [String]

    var columnCount: Int {
        max(header.count, rows.map(\.cells.count).max() ?? 0)
    }
}

struct SearchMatch: Identifiable, Equatable {
    let id = UUID()
    var range: NSRange
    var line: Int
    var preview: String
}

struct AppSettings {
    var defaultEncoding: SupportedEncoding = .utf8
    var newFileLineEnding: LineEnding = .lf
    var createBackupOnSave: Bool = true
    var fixedWidthSaveCheck: Bool = true
    var wrapText: Bool = true
    var csvHasHeaderDefault: Bool = true
    var csvAutoDetectDelimiter: Bool = true
    var csvDelimiter: CSVDelimiter = .comma
    var crashRecovery: Bool = true
    var fixedWidthGuides: String = "10,20,30,40,50,60,70,80"
}
