//
//  GreyAIService.swift
//  Resumed
//
//  Grey AI Service — Multi-provider: MedGemma (Ollama) → Gemini API → Local fallback
//  Priority: Local MedGemma via Ollama first (free, medical-specialized),
//  then Gemini API as cloud fallback, then hardcoded responses.
//

import Foundation

// MARK: - AI Provider

enum AIProvider: String {
    case medgemma   // Local MedGemma via Ollama (preferred)
    case gemini     // Cloud Gemini API (fallback)
    case local      // Hardcoded responses (offline fallback)
}

@MainActor
class GreyAIService {
    static let shared = GreyAIService()

    // MARK: - Configuration

    /// Ollama endpoint (local). Change host if running on a different machine.
    private let ollamaBaseURL = "http://localhost:11434"
    private let ollamaModel = "medgemma:4b-it"

    /// Gemini cloud fallback
    private let geminiApiKey: String = {
        Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String ?? ""
    }()
    private let geminiModel = "gemini-2.0-flash"

    /// Current provider (auto-detected)
    @Published private(set) var activeProvider: AIProvider = .local

    /// Conversation history for multi-turn (Ollama format)
    private var ollamaHistory: [[String: String]] = []

    /// Conversation history for Gemini format
    private var geminiHistory: [[String: Any]] = []

    private let systemPrompt = """
    Você é GREY, tutora médica sênior do app Resumed.

    OBJETIVO: Preparar o usuário para aprovação em provas de residência médica (ENAMED, Revalida).

    REGRAS:
    1. Responda SOMENTE sobre medicina, fisiologia, clínica ou estratégia de prova.
    2. Se o usuário sair do tema, diga: "Meu foco é sua aprovação. Vamos voltar aos estudos?"
    3. Seja direta, clínica e sem floreios.
    4. Use português brasileiro.
    5. Formate com markdown (negrito, bullet points) para clareza.
    6. Quando relevante, inclua: conceito direto, por que cai na prova, pegadinha comum, dica de memória.
    7. Nunca invente dados clínicos. Se não souber, diga.
    """

    private init() {
        Task { await detectProvider() }
    }

    // MARK: - Provider Detection

    /// Checks if Ollama is running with MedGemma available
    func detectProvider() async {
        // 1. Try Ollama
        if await isOllamaAvailable() {
            activeProvider = .medgemma
            print("🧠 Grey AI: Using MedGemma (local via Ollama)")
            return
        }

        // 2. Try Gemini
        if !geminiApiKey.isEmpty {
            activeProvider = .gemini
            print("☁️ Grey AI: Using Gemini API (cloud)")
            return
        }

        // 3. Local fallback
        activeProvider = .local
        print("📱 Grey AI: Using local fallback responses")
    }

    private func isOllamaAvailable() async -> Bool {
        guard let url = URL(string: "\(ollamaBaseURL)/api/tags") else { return false }

        var request = URLRequest(url: url)
        request.timeoutInterval = 3 // Fast timeout for local check

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return false }

            // Check if medgemma model is available
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let models = json?["models"] as? [[String: Any]] ?? []
            return models.contains { model in
                let name = model["name"] as? String ?? ""
                return name.contains("medgemma")
            }
        } catch {
            return false
        }
    }

    // MARK: - Send Message (Auto-routes to best provider)

    func sendMessage(_ userMessage: String) async -> String {
        switch activeProvider {
        case .medgemma:
            let result = await sendToOllama(userMessage)
            if result != nil { return result! }
            // Ollama failed, try fallback
            await detectProvider()
            if activeProvider == .gemini {
                return await sendToGemini(userMessage) ?? localFallback(userMessage)
            }
            return localFallback(userMessage)

        case .gemini:
            return await sendToGemini(userMessage) ?? localFallback(userMessage)

        case .local:
            return localFallback(userMessage)
        }
    }

    // MARK: - Ollama (MedGemma)

    private func sendToOllama(_ message: String) async -> String? {
        guard let url = URL(string: "\(ollamaBaseURL)/api/chat") else { return nil }

        // Build messages array with system prompt + history + new message
        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        messages.append(contentsOf: ollamaHistory)
        messages.append(["role": "user", "content": message])

        let requestBody: [String: Any] = [
            "model": ollamaModel,
            "messages": messages,
            "stream": false,
            "options": [
                "temperature": 0.7,
                "num_predict": 1024
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60 // MedGemma can be slower on CPU

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                print("Ollama error: status \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return nil
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let responseMessage = json?["message"] as? [String: Any]
            let content = responseMessage?["content"] as? String

            guard let text = content, !text.isEmpty else { return nil }

            // Update history
            ollamaHistory.append(["role": "user", "content": message])
            ollamaHistory.append(["role": "assistant", "content": text])

            // Keep history manageable
            if ollamaHistory.count > 20 {
                ollamaHistory = Array(ollamaHistory.suffix(20))
            }

            return text

        } catch {
            print("Ollama request failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Gemini API (Cloud fallback)

    private func sendToGemini(_ message: String) async -> String? {
        guard !geminiApiKey.isEmpty else { return nil }

        geminiHistory.append([
            "role": "user",
            "parts": [["text": message]]
        ])

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(geminiModel):generateContent?key=\(geminiApiKey)") else { return nil }

        let requestBody: [String: Any] = [
            "system_instruction": ["parts": [["text": systemPrompt]]],
            "contents": geminiHistory,
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 1024,
                "topP": 0.95
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let candidates = json?["candidates"] as? [[String: Any]]
            let content = candidates?.first?["content"] as? [String: Any]
            let parts = content?["parts"] as? [[String: Any]]
            let text = parts?.first?["text"] as? String

            guard let responseText = text else { return nil }

            geminiHistory.append([
                "role": "model",
                "parts": [["text": responseText]]
            ])

            if geminiHistory.count > 20 {
                geminiHistory = Array(geminiHistory.suffix(20))
            }

            return responseText

        } catch {
            print("Gemini request failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Local Fallback

    private func localFallback(_ message: String) -> String {
        let lower = message.lowercased()

        if lower.contains("fibrilação") || lower.contains("fibrilacao") {
            return """
            **Fibrilação Atrial (FA)**

            **Conceito:** Arritmia supraventricular mais comum. Ritmo irregularmente irregular, ausência de onda P.

            **Por que cai na prova:**
            - Anticoagulação (CHA₂DS₂-VASc)
            - Controle de frequência vs. ritmo
            - FA valvar vs. não-valvar

            **Pegadinha:** FA com RVR + instabilidade = cardioversão elétrica imediata

            **Dica:** CHA₂DS₂-VASc ≥ 2 (homem) ou ≥ 3 (mulher) → anticoagular
            """
        }

        if lower.contains("hiponatremia") || lower.contains("siadh") {
            return """
            **SIADH — Síndrome da Secreção Inapropriada de ADH**

            **Diagnóstico:**
            - Na⁺ sérico < 135 mEq/L
            - Osmolalidade sérica baixa (< 275)
            - Osmolalidade urinária inapropriadamente alta (> 100)
            - Na⁺ urinário > 40 mEq/L
            - Euvolemia clínica

            **Causas mais cobradas:** Pneumonia, SNC (TCE, AVC), medicamentos (carbamazepina, ISRS)

            **Pegadinha:** Corrigir Na⁺ > 10-12 mEq/L/dia → risco de mielinólise pontina

            **Conduta:** Restrição hídrica. Se grave: NaCl 3% com controle rigoroso
            """
        }

        if lower.contains("sifilis") || lower.contains("sífilis") {
            return """
            **Sífilis**

            **Tratamento padrão-ouro:** Penicilina G Benzatina
            - Primária/Secundária/Latente recente: 2.4mi UI IM dose única
            - Latente tardia/Terciária: 2.4mi UI IM semanal × 3 semanas
            - Neurossífilis: Penicilina cristalina IV 14 dias

            **Pegadinha:** Alergia a penicilina em gestante → dessensibilizar (não trocar por doxiciclina)

            **Controle de cura:** VDRL trimestral por 1 ano
            """
        }

        return """
        Boa pergunta! No momento estou operando em modo offline.

        **Para ativar a IA completa:**
        1. Inicie o Ollama com MedGemma (`ollama run medgemma:4b-it`)
        2. Ou configure a chave Gemini no app

        **Enquanto isso, posso ajudar com temas básicos:**
        • Fibrilação atrial
        • SIADH / Hiponatremia
        • Sífilis

        Me pergunte sobre um desses!
        """
    }

    // MARK: - Session Management

    func resetConversation() {
        ollamaHistory = []
        geminiHistory = []
    }

    /// Force re-detect provider (e.g., after starting Ollama)
    func refreshProvider() async {
        await detectProvider()
    }
}
