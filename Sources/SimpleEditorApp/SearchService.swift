import Foundation

enum SearchService {
    static func matches(in text: String, query: String, regex: Bool) -> [SearchMatch] {
        guard !query.isEmpty else { return [] }
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)

        if regex {
            guard let expression = try? NSRegularExpression(pattern: query) else { return [] }
            return expression.matches(in: text, range: fullRange).map { match in
                makeMatch(text: nsText, range: match.range)
            }
        }

        var results: [SearchMatch] = []
        var searchRange = fullRange
        while true {
            let found = nsText.range(of: query, options: [.caseInsensitive], range: searchRange)
            if found.location == NSNotFound { break }
            results.append(makeMatch(text: nsText, range: found))
            let nextLocation = found.location + max(found.length, 1)
            if nextLocation >= nsText.length { break }
            searchRange = NSRange(location: nextLocation, length: nsText.length - nextLocation)
        }
        return results
    }

    private static func makeMatch(text: NSString, range: NSRange) -> SearchMatch {
        let prefix = text.substring(to: range.location)
        let line = prefix.components(separatedBy: "\n").count
        let lineRange = text.lineRange(for: range)
        let preview = text.substring(with: lineRange).trimmingCharacters(in: .newlines)
        return SearchMatch(range: range, line: line, preview: preview)
    }
}
