import AppKit
import Foundation

enum FileServiceError: Error, LocalizedError {
    case noDestination
    case saveBlocked(String)

    var errorDescription: String? {
        switch self {
        case .noDestination:
            "No save destination was selected."
        case .saveBlocked(let reason):
            reason
        }
    }
}

enum FileOpenService {
    static func open(url: URL) throws -> OpenedFile {
        let data = try Data(contentsOf: url)
        let decoded = try EncodingService.decode(data)
        let resourceValues = try? url.resourceValues(forKeys: [.isWritableKey])
        return OpenedFile(
            url: url,
            originalData: data,
            text: decoded.normalizedText,
            encodingInfo: decoded.encodingInfo,
            lineEndingInfo: decoded.lineEndingInfo,
            isDirty: false,
            isReadOnly: resourceValues?.isWritable == false,
            fileSize: data.count,
            saveBlockReason: nil
        )
    }
}

enum FileSaveService {
    static func save(file: OpenedFile, to destination: URL? = nil, createBackup: Bool) throws -> OpenedFile {
        guard file.encodingInfo.canSave else {
            throw FileServiceError.saveBlocked(file.encodingInfo.decodeError ?? "Saving is blocked because the file has decode errors.")
        }
        guard let url = destination ?? file.url else {
            throw FileServiceError.noDestination
        }

        let data = try EncodingService.encode(file.text, encoding: file.encodingInfo.encoding, lineEnding: file.lineEndingInfo.primary)
        let fileManager = FileManager.default

        if createBackup, fileManager.fileExists(atPath: url.path) {
            let backupURL = URL(fileURLWithPath: url.path + ".bak")
            _ = try? fileManager.removeItem(at: backupURL)
            try fileManager.copyItem(at: url, to: backupURL)
        }

        if fileManager.fileExists(atPath: url.path) {
            let temporaryURL = url.deletingLastPathComponent()
                .appendingPathComponent(".\(url.lastPathComponent).tmp-\(UUID().uuidString)")
            try data.write(to: temporaryURL, options: .atomic)
            _ = try fileManager.replaceItemAt(url, withItemAt: temporaryURL, backupItemName: nil, options: [])
        } else {
            try data.write(to: url, options: .atomic)
        }

        var saved = file
        saved.url = url
        saved.originalData = data
        saved.fileSize = data.count
        saved.isDirty = false
        saved.saveBlockReason = nil
        return saved
    }
}

enum PanelService {
    @MainActor
    static func openFileURL() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.plainText, .commaSeparatedText, .tabSeparatedText, .json, .xml, .data]
        return panel.runModal() == .OK ? panel.url : nil
    }

    @MainActor
    static func saveFileURL(defaultName: String) -> URL? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultName
        return panel.runModal() == .OK ? panel.url : nil
    }
}
