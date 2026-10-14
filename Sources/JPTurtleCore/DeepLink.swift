import Foundation

/// URL-Scheme `jpturtle://`, mit dem Widgets in die App springen.
public enum DeepLink: Equatable, Sendable {
    case home
    case review(wordID: String?)
    case kana
    case turtle

    public static let scheme = "jpturtle"

    public var url: URL {
        var c = URLComponents()
        c.scheme = DeepLink.scheme
        switch self {
        case .home:
            c.host = "home"
        case .review(let id):
            c.host = "review"
            if let id { c.queryItems = [URLQueryItem(name: "word", value: id)] }
        case .kana:
            c.host = "kana"
        case .turtle:
            c.host = "turtle"
        }
        return c.url!
    }

    public init?(url: URL) {
        guard url.scheme == DeepLink.scheme else { return nil }
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        switch url.host {
        case "home": self = .home
        case "review":
            let id = comps?.queryItems?.first { $0.name == "word" }?.value
            self = .review(wordID: id)
        case "kana": self = .kana
        case "turtle": self = .turtle
        default: return nil
        }
    }
}
