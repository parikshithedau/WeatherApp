import Foundation

protocol APIRequest: Sendable {
    associatedtype Response: Decodable

    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var headers: [String: String]? { get }
}

extension APIRequest {
    var method: HTTPMethod { .get }
    var queryItems: [URLQueryItem]? { nil }
    var headers: [String: String]? { nil }

    func makeURL() throws -> URL {
        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        components.queryItems = queryItems
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        return url
    }
}
