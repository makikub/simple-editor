import Foundation

enum CrashRecoveryService {
    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("SimpleEditor", isDirectory: true)
    }

    private static var draftURL: URL {
        directoryURL.appendingPathComponent("recovery.txt")
    }

    static func saveDraft(_ text: String) {
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try? text.write(to: draftURL, atomically: true, encoding: .utf8)
    }

    static func loadDraft() -> String? {
        guard FileManager.default.fileExists(atPath: draftURL.path) else { return nil }
        return try? String(contentsOf: draftURL, encoding: .utf8)
    }

    static func clearDraft() {
        try? FileManager.default.removeItem(at: draftURL)
    }
}
