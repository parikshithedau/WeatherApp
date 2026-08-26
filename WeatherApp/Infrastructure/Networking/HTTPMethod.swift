import Foundation

enum HTTPMethod: Sendable, Equatable {
    case get
    case post
    case put
    case delete

    var rawValue: String {
        switch self {
        case .get: StringConstant.HTTPMethod.get
        case .post: StringConstant.HTTPMethod.post
        case .put: StringConstant.HTTPMethod.put
        case .delete: StringConstant.HTTPMethod.delete
        }
    }
}
