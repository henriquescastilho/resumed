
import { GoogleGenAI, Chat, GenerateContentResponse } from "@google/genai";

let chatSession: Chat | null = null;

const SYSTEM_INSTRUCTION = `
You are Grey, a highly specialized, objective, and technical medical AI assistant for the Resumed app. 
Your goal is to help medical students prepare for ENAMED and Revalida.
Rules:
1. Be concise, direct, and professional.
2. Only answer questions related to medicine, medical residency, biological sciences, or study planning.
3. If a user asks about anything else (politics, sports, entertainment), politely refuse and state that you are restricted to medical topics.
4. Use Portuguese (Brazil).
5. Format answers with clarity (bullet points where applicable).
`;

// Initialize chat session using the correct model and standard parameters
export const initChat = () => {
  if (!process.env.API_KEY) {
    console.warn("API_KEY not found. Chat functionality will be simulated.");
    return;
  }

  try {
    // Always use { apiKey: ... } named parameter for initialization
    const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });
    chatSession = ai.chats.create({
      model: 'gemini-2.0-flash',
      config: {
        systemInstruction: SYSTEM_INSTRUCTION,
      },
    });
  } catch (error) {
    console.error("Failed to initialize Gemini:", error);
  }
};

export const resetChat = () => {
  chatSession = null;
};

export const sendMessageToGrey = async (message: string): Promise<string> => {
  if (!chatSession) {
    // Fallback simulation if no API key
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve("Olá. Eu sou a Grey. Como não detectei uma chave de API válida, estou operando em modo de demonstração. Em produção, eu responderia sua dúvida médica com precisão baseada no Gemini 3 Flash.");
      }, 1000);
    });
  }

  try {
    // Correctly accessing .text property on the GenerateContentResponse object
    const response: GenerateContentResponse = await chatSession.sendMessage({ message });
    return response.text || "Não consegui processar sua resposta.";
  } catch (error) {
    console.error("Error sending message to Grey:", error);
    return "Ocorreu um erro ao comunicar com a IA. Tente novamente.";
  }
};
