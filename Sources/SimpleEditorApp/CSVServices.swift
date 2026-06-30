import Foundation

enum CSVParseService {
    static func detectDelimiter(text: String, url: URL?) -> CSVDelimiter {
        let ext = url?.pathExtension.lowercased()
        if ext == "csv" { return .comma }
        if ext == "tsv" { return .tab }

        let prefix = String(text.prefix(8192))
        let commaCount = prefix.filter { $0 == "," }.count
        let tabCount = prefix.filter { $0 == "\t" }.count
        return tabCount > commaCount ? .tab : .comma
    }

    static func parse(text: String, delimiter: CSVDelimiter, hasHeader: Bool) -> CSVDocument {
        var rows: [CSVRow] = []
        var warnings: [String] = []
        var cell = ""
        var cells: [String] = []
        var original = ""
        var inQuotes = false
        var rowIndex = 0
        let delimiterChar = Character(delimiter.rawValue)
        var iterator = Array(text).makeIterator()

        func finishRow() {
            cells.append(cell)
            rows.append(CSVRow(sourceIndex: rowIndex, cells: cells, originalText: original, isEdited: false))
            rowIndex += 1
            cell = ""
            cells = []
            original = ""
        }

        while let character = iterator.next() {
            original.append(character)
            if character == "\"" {
                if inQuotes {
                    if let next = iterator.next() {
                        if next == "\"" {
                            cell.append("\"")
                            original.append(next)
                        } else {
                            inQuotes = false
                            if next == delimiterChar {
                                cells.append(cell)
                                cell = ""
                                original.append(next)
                            } else if next == "\n" {
                                finishRow()
                            } else {
                                cell.append(next)
                                original.append(next)
                            }
                        }
                    } else {
                        inQuotes = false
                    }
                } else if cell.isEmpty {
                    inQuotes = true
                } else {
                    cell.append(character)
                }
            } else if character == delimiterChar && !inQuotes {
                cells.append(cell)
                cell = ""
            } else if character == "\n" && !inQuotes {
                finishRow()
            } else {
                cell.append(character)
            }
        }

        if inQuotes {
            warnings.append("A quoted cell is not closed.")
        }
        if !cell.isEmpty || !cells.isEmpty || !original.isEmpty {
            finishRow()
        }

        var header: [String] = []
        var dataRows = rows
        if hasHeader, let first = dataRows.first {
            header = first.cells
            dataRows.removeFirst()
        } else {
            let maxColumns = rows.map(\.cells.count).max() ?? 0
            header = (0..<maxColumns).map { excelColumnName($0) }
        }

        return CSVDocument(delimiter: delimiter, hasHeader: hasHeader, header: header, rows: dataRows, warnings: warnings)
    }

    private static func excelColumnName(_ index: Int) -> String {
        var value = index + 1
        var result = ""
        while value > 0 {
            let remainder = (value - 1) % 26
            result = String(UnicodeScalar(65 + remainder)!) + result
            value = (value - 1) / 26
        }
        return result
    }
}

enum CSVSerializeService {
    static func serialize(_ document: CSVDocument, lineEnding: LineEnding) -> String {
        var lines: [String] = []
        if document.hasHeader {
            lines.append(serializeRow(document.header, delimiter: document.delimiter))
        }
        lines += document.rows.map { row in
            row.isEdited ? serializeRow(row.cells, delimiter: document.delimiter) : row.originalText.trimmingCharacters(in: .newlines)
        }
        return lines.joined(separator: "\n")
    }

    static func serializeRow(_ cells: [String], delimiter: CSVDelimiter) -> String {
        cells.map { cell in
            let mustQuote = cell.contains(delimiter.rawValue) || cell.contains("\n") || cell.contains("\"")
            let escaped = cell.replacingOccurrences(of: "\"", with: "\"\"")
            return mustQuote ? "\"\(escaped)\"" : escaped
        }.joined(separator: delimiter.rawValue)
    }
}
