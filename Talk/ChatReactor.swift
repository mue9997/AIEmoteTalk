import Foundation
import ReactorKit
import RxSwift

final class ChatReactor: Reactor {
    enum Action {
        case askChatGPT(String)
        case showAlert(String)
        case hideAlert
    }

    enum Mutation {
        case setMessages([ChatGPTMessage])
        case setIsAsking(Bool)
        case addMessage(ChatGPTMessage)
        case setAlert(String?)
    }

    struct State {
        var messages: [ChatGPTMessage] = []
        var isAsking: Bool = false
        var alert: String?
    }

    var initialState: State = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .askChatGPT(let text):
            guard !text.isEmpty else { return .empty() }

            let openAITokenKey = "chatGPTTokenKey"
            guard let openAIToken = UserDefaults.standard.string(forKey: openAITokenKey), !openAIToken.isEmpty else {
                return .just(.setAlert("OpenAIのトークンを設定画面から入力してください"))
            }

            let characterSettingKey = "characterSettingKey"
            let characterPrompt = ChatGPTRequest().characterPrompt

            guard let characterSetting = UserDefaults.standard.string(forKey: characterSettingKey), !characterSetting.isEmpty, !characterPrompt.isEmpty else {
                return .just(.setAlert("キャラクターの設定を入力してください"))
            }

            initialState.isAsking = true
            let messageContent = Content(emotion: Emotion(), message: text)
            let message = ChatGPTMessage(role: .user, content: messageContent)
            return .concat([
                .just(.addMessage(message)),
                getMessage(text: text, token: openAIToken, characterSetting: characterPrompt),
                .just(.setIsAsking(false))
            ])

        case .showAlert(let message):
            return .just(.setAlert(message))

        case .hideAlert:
            return .just(.setAlert(nil))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case .setMessages(let messages):
            state.messages = messages

        case .setIsAsking(let isAsking):
            state.isAsking = isAsking

        case .addMessage(let message):
            state.messages.append(message)

        case .setAlert(let alert):
            state.alert = alert
        }
        return state
    }

    private func getMessage(text: String, token: String, characterSetting: String) -> Observable<Mutation> {
        return Observable.create { observer in
            let headers: [String: String] = [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(token)"
            ]

            let messages = self.convertToMessages(text: text, characterSetting: characterSetting)
            let parameters: [String: Any] = [
                "model": "gpt-3.5-turbo",
                "messages": messages
            ]

            guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
                observer.onNext(.setAlert("無効なURLです"))
                observer.onCompleted()
                return Disposables.create()
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
            } catch {
                observer.onNext(.setAlert("JSONエンコーディングに失敗しました"))
                observer.onCompleted()
                return Disposables.create()
            }

            // Unityキャラを考え中状態に変更
            self.sendCharactorStateToUnity("thinking")

            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error {
                    observer.onNext(.setAlert("APIリクエストエラー: \(error.localizedDescription)"))
                    observer.onCompleted()
                    return
                }

                guard let data = data else {
                    observer.onNext(.setAlert("APIからデータを受信できませんでした"))
                    observer.onCompleted()
                    return
                }

                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase

                if let apiError = try? decoder.decode(ChatGPTAPIError.self, from: data) {
                    observer.onNext(.setAlert("APIエラー: \(apiError.error.message)"))
                    observer.onCompleted()
                } else if let res = try? decoder.decode(ChatGPTResponse.self, from: data),
                          let choice = res.choices.first {
                    let contentString = choice.message.content
                    // Unityにmessageを連携
                    self.sendCharactorJsonStringToUnity(contentString)
                    self.sendCharactorStateToUnity("neutral")


                    guard let data = contentString.data(using: .utf8),
                          let decodedContent = try? JSONDecoder().decode(Content.self, from: data) else {
                        observer.onNext(.setAlert("Nested content decoding error"))
                        observer.onCompleted()
                        return
                    }

                    let role: ChatGPTMessage.Role = .assistant
                    let messageToAppend = ChatGPTMessage(role: role, content: decodedContent)

                    observer.onNext(.addMessage(messageToAppend))
                    observer.onCompleted()
                } else {
                    observer.onNext(.setAlert("APIレスポンスをデコードできませんでした"))
                    observer.onCompleted()
                }
            }
            task.resume()
            return Disposables.create { task.cancel() }
        }
    }

    private func convertToMessages(text: String, characterSetting: String) -> [[String: String]] {
        var convertedMessages = currentState.messages.map { ["content": $0.content.message, "role": $0.role.rawValue] }

        convertedMessages.insert(["content": characterSetting, "role": ChatGPTMessage.Role.system.rawValue], at: 0)
        convertedMessages.append(["content": text, "role": ChatGPTMessage.Role.user.rawValue])
        return convertedMessages
    }

    private func sendCharactorStateToUnity(_ state: String) {
        Unity.shared
            .sendMessageToUnity(objectName: "AICharactor", functionName: "UpdateState", argument: state)
    }

    private func sendCharactorJsonStringToUnity(_ jsonString: String) {
        Unity.shared
            .sendMessageToUnity(objectName: "AICharactor", functionName: "Talk", argument: jsonString)
    }
}
