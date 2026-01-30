import google.generativeai as genai
from app.core.config import get_settings
import json
import re

settings = get_settings()

class GreyService:
    _model = None

    @classmethod
    def _get_model(cls):
        if not cls._model:
            if settings.GEMINI_API_KEY:
                genai.configure(api_key=settings.GEMINI_API_KEY)
                # SYSTEM PROMPT (STRICT)
                system_instruction = """
                Você é GREY, uma tutora médica sênior do aplicativo Resumed.

                OBJETIVO:
                Preparar o usuário para aprovação em provas de residência médica.

                REGRAS RÍGIDAS:
                1. Responda SOMENTE sobre medicina, fisiologia, clínica médica ou estratégia de prova.
                2. Se o usuário sair do tema (ex: política, futebol, piadas), responda APENAS:
                   "Meu foco é sua aprovação. Vamos voltar aos estudos?"
                3. Seja direta, clínica e sem floreios.
                4. Nunca invente dados.
                5. Nunca dê aconselhamento médico real ao paciente.

                FORMATO DE RESPOSTA OBRIGATÓRIO (JSON):
                {
                    "answer_markdown": "🎯 **Conceito Direto**: ...\\n💡 **Por que cai na prova**: ...\\n⚠️ **Pegadinha comum**: ...\\n🧠 **Dica de memória**: ...",
                    "flashcard": {
                        "front": "Pergunta objetiva para o card...",
                        "back": "Resposta direta..."
                    },
                    "tags": ["tag1", "tag2"]
                }
                """
                cls._model = genai.GenerativeModel('gemini-1.5-flash', system_instruction=system_instruction)
        return cls._model

    @classmethod
    async def chat(cls, message: str, context: dict) -> dict:
        # 1. Guardrails (Simple Regex/Keyword Filter)
        forbidden_patterns = [r"sertanejo", r"futebol", r"piada", r"receita de bolo"]
        for pattern in forbidden_patterns:
            if re.search(pattern, message, re.IGNORECASE):
                return cls._fallback_response("Meu foco é sua aprovação. Vamos voltar aos estudos?")

        model = cls._get_model()
        if not model:
            return cls._fallback_response("⚠️ Erro: Chave API não configurada.")

        # 2. Context Injection
        screen_context = context.get('screen', 'home')
        topic_context = context.get('topic', 'Medicina Geral')
        
        # In a real scenario, we would fetch User Profile here (target exam, weak areas)
        # For MVP, we mock the profile context injection
        profile_context = """
        PERFIL DO USUÁRIO:
        - Prova alvo: ENAMED / Revalida
        - Especialidade: Clínica Médica
        - Pontos fracos recentes: Cardiologia, Nefrologia
        """

        full_prompt = f"""
        {profile_context}
        - Tela atual: {screen_context}
        - Tópico atual: {topic_context}
        
        PERGUNTA DO USUÁRIO:
        {message}
        """
        
        try:
            # 3. Call LLM
            response = model.generate_content(full_prompt)
            
            # 4. Clean & Validate
            text = response.text
            # Remove markdown code blocks if present
            if "```json" in text:
                text = text.split("```json")[1].split("```")[0]
            elif "```" in text:
                text = text.split("```")[1].split("```")[0]
            
            return json.loads(text.strip())
            
        except Exception as e:
            print(f"LLM Error: {e}")
            return cls._fallback_response("Não tenho informação suficiente para responder com segurança. Vamos revisar esse tema?")

    @staticmethod
    def _fallback_response(msg: str) -> dict:
        return {
            "answer_markdown": msg,
            "flashcard": None,
            "tags": []
        }
