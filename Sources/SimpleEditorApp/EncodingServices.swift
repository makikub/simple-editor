import AppKit
import CoreFoundation
import Foundation

enum EncodingError: Error, LocalizedError {
    case cannotDecode
    case cannotEncode(SupportedEncoding)

    var errorDescription: String? {
        switch self {
        case .cannotDecode:
            "The file could not be decoded as UTF-8, UTF-8 BOM, or CP932."
        case .cannotEncode(let encoding):
            "The text contains characters that cannot be represented as \(encoding.rawValue)."
        }
    }
}

struct DecodedFile {
    var text: String
    var normalizedText: String
    var encodingInfo: EncodingInfo
    var lineEndingInfo: LineEndingInfo
}

enum EncodingService {
    static let cp932Encoding: String.Encoding = {
        let cfEncoding = CFStringEncoding(CFStringEncodings.dosJapanese.rawValue)
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
    }()

    static func decode(_ data: Data) throws -> DecodedFile {
        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            let body = data.dropFirst(3)
            if let text = String(data: body, encoding: .utf8) {
                return decoded(text: text, encoding: .utf8BOM, hasBOM: true, confidence: 1.0, data: data)
            }
        }

        if let text = String(data: data, encoding: .utf8) {
            return decoded(text: text, encoding: .utf8, hasBOM: false, confidence: 0.95, data: data)
        }

        if let text = String(data: data, encoding: cp932Encoding) {
            return decoded(text: text, encoding: .cp932, hasBOM: false, confidence: 0.75, data: data)
        }

        throw EncodingError.cannotDecode
    }

    static func encode(_ text: String, encoding: SupportedEncoding, lineEnding: LineEnding) throws -> Data {
        let textWithOriginalEndings = text.replacingOccurrences(of: "\n", with: lineEnding.characters)
        let stringEncoding: String.Encoding = switch encoding {
        case .utf8, .utf8BOM: .utf8
        case .cp932: cp932Encoding
        }

        guard var data = textWithOriginalEndings.data(using: stringEncoding, allowLossyConversion: false) else {
            throw EncodingError.cannotEncode(encoding)
        }

        if encoding == .utf8BOM {
            data.insert(contentsOf: [0xEF, 0xBB, 0xBF], at: 0)
        }
        return data
    }

    static func byteCount(_ string: String, encoding: SupportedEncoding) -> Int {
        let stringEncoding: String.Encoding = encoding == .cp932 ? cp932Encoding : .utf8
        return string.data(using: stringEncoding, allowLossyConversion: false)?.count ?? string.utf8.count
    }

    private static func decoded(text: String, encoding: SupportedEncoding, hasBOM: Bool, confidence: Double, data: Data) -> DecodedFile {
        let lineInfo = LineEndingService.detect(in: text)
        return DecodedFile(
            text: text,
            normalizedText: LineEndingService.normalize(text),
            encodingInfo: EncodingInfo(encoding: encoding, hasBOM: hasBOM, confidence: confidence, decodeError: nil),
            lineEndingInfo: lineInfo
        )
    }
}

enum LineEndingService {
    static func detect(in text: String) -> LineEndingInfo {
        var lf = 0
        var crlf = 0
        var cr = 0
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]
            if character == "\r" {
                let next = text.index(after: index)
                if next < text.endIndex, text[next] == "\n" {
                    crlf += 1
                    index = text.index(after: next)
                } else {
                    cr += 1
                    index = next
                }
            } else if character == "\n" {
                lf += 1
                index = text.index(after: index)
            } else {
                index = text.index(after: index)
            }
        }

        let primary: LineEnding
        if crlf >= lf && crlf >= cr && crlf > 0 {
            primary = .crlf
        } else if cr >= lf && cr > 0 {
            primary = .cr
        } else {
            primary = .lf
        }

        return LineEndingInfo(primary: primary, lfCount: lf, crlfCount: crlf, crCount: cr)
    }

    static func normalize(_ text: String) -> String {
        text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }
}
