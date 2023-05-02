struct ChatGPTAPIError: Codable, Error {
    let error: APIError

    struct APIError: Codable {
        let message: String
        let type: String
        let param: String?
        let code: String?
    }
}
