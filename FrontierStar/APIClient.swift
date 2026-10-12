import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case server(status: Int, message: String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "服务暂时不可用"
        case let .server(_, message): return message
        case .decoding: return "数据格式异常"
        }
    }
}

struct RegistrationReceipt: Codable {
    let id: String
    let status: String
    let advisorStatus: String
}

protocol FrontierStarRepository {
    func fetchCourses() async throws -> [Course]
    func fetchProjects() async throws -> [FrontierProject]
    func enroll(courseID: String) async throws -> RegistrationReceipt
    func submit(need: ParentNeed) async throws -> ParentNeed
    func submit(project: FrontierProject) async throws -> FrontierProject
}

/// 正式环境的网络仓储。MVP 演示默认使用 `AppStore` 本地数据；接入服务端后可在组合根替换。
final class URLSessionFrontierStarRepository: FrontierStarRepository {
    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: () -> String?
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL, session: URLSession = .shared, tokenProvider: @escaping () -> String? = { nil }) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func fetchCourses() async throws -> [Course] {
        try await get(path: "v1/courses")
    }

    func fetchProjects() async throws -> [FrontierProject] {
        try await get(path: "v1/projects")
    }

    func enroll(courseID: String) async throws -> RegistrationReceipt {
        try await post(path: "v1/courses/\(courseID)/registrations", body: ["source": "ios"])
    }

    func submit(need: ParentNeed) async throws -> ParentNeed {
        try await post(path: "v1/needs", body: need)
    }

    func submit(project: FrontierProject) async throws -> FrontierProject {
        try await post(path: "v1/projects", body: project)
    }

    private func get<Response: Decodable>(path: String) async throws -> Response {
        try await perform(path: path, method: "GET", body: nil)
    }

    private func post<Response: Decodable, Body: Encodable>(path: String, body: Body) async throws -> Response {
        try await perform(path: path, method: "POST", body: try encoder.encode(body))
    }

    private func perform<Response: Decodable>(path: String, method: String, body: Data?) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ios", forHTTPHeaderField: "X-Client-Platform")
        if let token = tokenProvider() { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard 200..<300 ~= http.statusCode else {
            let message = (try? decoder.decode(ServerMessage.self, from: data).message) ?? "请求未完成，请稍后再试"
            throw APIError.server(status: http.statusCode, message: message)
        }
        do { return try decoder.decode(Response.self, from: data) }
        catch { throw APIError.decoding(error) }
    }
}

private struct ServerMessage: Decodable {
    let message: String
}
