import Foundation

enum HTTPMethod: Sendable, Equatable {
    case get
    case post
    case put
    case delete

    var rawValue: String {
        switch self {
        case .get: "GET"
        case .post: "POST"
        case .put: "PUT"
        case .delete: "DELETE"
        }
    }
}
