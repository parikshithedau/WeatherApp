import Foundation

protocol APIClientProtocol: Sendable {
    func execute<R: APIRequest>(_ request: R) async throws -> R.Response
}
