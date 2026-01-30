import Foundation
import SwiftUI

// Persistence Helper
class ChatHistoryManager {
    static let shared = ChatHistoryManager()
    private let fileName = "grey_chat_history.json"
    
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }
    
    func saveMessages(_ messages: [GreyChatViewModel.ChatMessage]) {
        do {
            let data = try JSONEncoder().encode(messages)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save chat history: \(error)")
        }
    }
    
    func loadMessages() -> [GreyChatViewModel.ChatMessage] {
        do {
            let data = try Data(contentsOf: fileURL)
            let messages = try JSONDecoder().decode([GreyChatViewModel.ChatMessage].self, from: data)
            return messages
        } catch {
            return []
        }
    }
}

@MainActor
class GreyChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputMessage = ""
    @Published var isLoading = false
    @Published var suggestions = ["Revisar IC", "Critérios de Duke", "Tríade de Beck", "Tromboembolismo"]
    
    init() {
        self.messages = ChatHistoryManager.shared.loadMessages()
    }
    
    struct ChatMessage: Identifiable, Codable {
        var id = UUID()
        let text: String
        let isUser: Bool
        let flashcard: FlashcardData?
    }
    
    struct FlashcardData: Codable {
        let front: String
        let back: String
    }
    
    func sendMessage(_ text: String? = nil) async {
        let msgToSend = text ?? inputMessage
        guard !msgToSend.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        // Add user message
        let userMsg = ChatMessage(text: msgToSend, isUser: true, flashcard: nil)
        messages.append(userMsg)
        ChatHistoryManager.shared.saveMessages(messages)
        
        if text == nil { inputMessage = "" }
        isLoading = true
        
        guard let token = AuthService.shared.getToken() else { return }
        
        do {
            let context = ["screen": "grey_chat", "topic": "geral"]
            let payload = ["message": msgToSend, "context": context] as [String : Any]
            let body = try JSONSerialization.data(withJSONObject: payload)
            
            // NOTE: Ideally use APIClient, essentially inline for this specific shape in MVP
            var request = URLRequest(url: URL(string: "http://localhost:8000/api/v1/grey/message")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = body
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let answer = json["answer_markdown"] as? String {
                
                var flashcardData: FlashcardData? = nil
                if let fc = json["flashcard"] as? [String: String], 
                   let front = fc["front"], let back = fc["back"] {
                    flashcardData = FlashcardData(front: front, back: back)
                }
                
                let responseParams = ChatMessage(text: answer, isUser: false, flashcard: flashcardData)
                messages.append(responseParams)
                ChatHistoryManager.shared.saveMessages(messages)
            }
        } catch {
            messages.append(ChatMessage(text: "Erro de conexão.", isUser: false, flashcard: nil))
        }
        
        isLoading = false
    }
}
