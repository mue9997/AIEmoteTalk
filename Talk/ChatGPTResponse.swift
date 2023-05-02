import Foundation

struct Content: Codable {
    var emotion: Emotion
    var message: String
}

/// Chat GPTから送られるメッセージもjsonのため、ネスト解除用
struct RawChatGPTMessage: Codable {
    var role: ChatGPTMessage.Role
    var content: String
}

struct ChatGPTMessage {
    var role: Role
    var content: Content

    enum Role: String, Codable {
        case user
        case assistant
        case system
    }
}

struct ChatGPTResponse: Codable {
    var id: String
    var object: String
    var created: Int
    var model: String
    var choices: [Choice]
    var usage: Usage

    struct Choice: Codable {
        var index: Int
        var finishReason: String
        var message: RawChatGPTMessage
    }
}

struct Emotion: Codable {
    var joy: Int = 0
    var fun: Int = 0
    var anger: Int = 0
    var sad: Int = 0
}

struct Usage: Codable {
    var promptTokens: Int
    var completionTokens: Int
    var totalTokens: Int
}
