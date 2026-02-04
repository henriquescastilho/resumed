# 🔥 Firebase Setup - RESUMED iOS

**Guia completo para configurar Firebase no projeto**

---

## 📋 Pré-requisitos

- ✅ Conta Google (gmail)
- ✅ Xcode 15+ instalado
- ✅ Projeto RESUMED criado

---

## 🚀 PASSO 1: Criar Projeto no Firebase Console

### 1.1. Acessar Firebase Console

1. Acesse: [console.firebase.google.com](https://console.firebase.google.com)
2. Faça login com sua conta Google
3. Clique em **"Adicionar projeto"** (ou "Create a project")

### 1.2. Configurar Projeto

**Nome do projeto:**
```
RESUMED
```

**Google Analytics:**
```
✅ Ativar Google Analytics (recomendado)
Conta: Default Account for Firebase
```

**Clique em:** `Criar projeto` → Aguarde 1-2 minutos

---

## 📱 PASSO 2: Adicionar App iOS ao Projeto Firebase

### 2.1. Registrar App

1. **No Firebase Console**, clique em **iOS** (ícone da Apple)

2. **Preencha os campos:**

```
iOS bundle ID: DMETECHNOLOGY.Resumed
  ⚠️ IMPORTANTE: Copie exatamente do Xcode!
  (Xcode → Target "Resumed" → General → Bundle Identifier)

App nickname (opcional): RESUMED iOS
App Store ID (opcional): Deixe vazio (por enquanto)
```

3. **Clique em:** `Registrar app`

---

### 2.2. Baixar GoogleService-Info.plist

1. **Baixe o arquivo** `GoogleService-Info.plist`

2. **Salve na pasta:**
```
~/Downloads/GoogleService-Info.plist
```

3. **NO XCODE:**
   - Arraste o arquivo `GoogleService-Info.plist` para dentro do projeto
   - **Coloque na raiz do projeto** (junto com ResumedApp.swift)
   - **IMPORTANTE:** Marque ✅ "Copy items if needed"
   - **IMPORTANTE:** Marque ✅ "Add to targets: Resumed"

---

## 📦 PASSO 3: Adicionar Firebase SDK via Swift Package Manager

### 3.1. No Xcode

1. **File → Add Package Dependencies...**

2. **Cole a URL:**
```
https://github.com/firebase/firebase-ios-sdk
```

3. **Dependency Rule:**
```
Version: Up to Next Major Version
From: 10.20.0
```

4. **Clique em:** `Add Package`

5. **Aguarde download** (pode demorar 2-3 minutos)

### 3.2. Selecionar Produtos

Quando aparecer a lista, **MARQUE APENAS:**

```
✅ FirebaseAnalytics
✅ FirebaseAuth
✅ FirebaseCrashlytics
✅ FirebaseFirestore (opcional - se for usar DB próprio)
```

**NÃO marque:**
- ❌ FirebaseDatabase (não usamos Realtime Database)
- ❌ FirebaseStorage (não precisamos agora)
- ❌ FirebaseMessaging (push notifications vem depois)

6. **Clique em:** `Add Package`

---

## 🔧 PASSO 4: Configurar Firebase no Código

### 4.1. Descomentar Imports no FirebaseManager.swift

**Abra:** `Core/Services/Firebase/FirebaseManager.swift`

**Descomente as linhas 8-10:**

```swift
// ANTES:
// import Firebase
// import FirebaseAuth
// import FirebaseAnalytics
// import FirebaseCrashlytics

// DEPOIS:
import Firebase
import FirebaseAuth
import FirebaseAnalytics
import FirebaseCrashlytics
```

### 4.2. Inicializar Firebase no ResumedApp.swift

**Abra:** `ResumedApp.swift`

**Adicione no init():**

```swift
@main
struct ResumedApp: App {
    init() {
        // 🔥 ADICIONE ESTA LINHA:
        FirebaseManager.shared.configure()

        configureAppearance()
    }

    // ... resto do código
}
```

---

## 🔐 PASSO 5: Configurar Google Sign-In

### 5.1. Ativar Authentication no Firebase Console

1. **No Firebase Console**, vá em **Authentication** (menu lateral)
2. **Clique em:** `Get started`
3. **Sign-in method** → **Google** → ✅ Enable
4. **Project support email:** Seu email
5. **Clique em:** `Save`

### 5.2. Obter Client ID

1. **Ainda em Authentication → Google**
2. **Copie o "Web client ID"** (algo como: `123456789-abc.apps.googleusercontent.com`)
3. **Guarde esse ID!**

### 5.3. Configurar URL Schemes no Xcode

1. **No Xcode:**
   - Target **"Resumed"**
   - Aba **"Info"**
   - Expanda **"URL Types"**
   - Clique no **"+"** para adicionar

2. **Preencha:**
```
Identifier: com.googleusercontent.apps.REVERSED_CLIENT_ID
URL Schemes: com.googleusercontent.apps.123456789-abc
  ⚠️ Substitua pelo REVERSED Client ID do seu projeto!
```

**Como obter REVERSED Client ID:**
- Abra o `GoogleService-Info.plist` que você baixou
- Procure por `REVERSED_CLIENT_ID`
- Copie o valor (ex: `com.googleusercontent.apps.123456789-abc`)

---

## ✅ PASSO 6: Testar a Configuração

### 6.1. Build o Projeto

```
⌘ + B (Command + B)
```

**Possíveis erros:**
- ❌ "No such module 'Firebase'" → Firebase SDK não foi adicionado corretamente. Refaça Passo 3.
- ❌ "'GoogleService-Info.plist' not found" → Arquivo não foi adicionado ao target. Refaça Passo 2.2.

### 6.2. Run no Simulator

```
⌘ + R (Command + R)
```

**O que deve acontecer:**
1. ✅ App abre sem crashes
2. ✅ Splash screen aparece
3. ✅ Firebase está inicializado (sem erros no console)
4. ✅ Analytics começou a trackear

### 6.3. Verificar no Firebase Console

1. **Volte ao Firebase Console**
2. **Analytics → Events** (pode demorar 1-2 horas para aparecer)
3. **Crashlytics** → Se aparecer "Waiting for data", tudo certo!

---

## 🎯 PASSO 7: Testar Google Sign-In

### 7.1. No Simulator

1. **Abra o app**
2. **Passe pelo onboarding**
3. **Na tela de login**, clique em **"Continuar com Google"**
4. **Escolha uma conta Google**
5. **Autorize o app**

**O que deve acontecer:**
- ✅ Google Sign-In web view abre
- ✅ Você faz login
- ✅ App recebe o token
- ✅ AuthManager chama o backend (ou mock)
- ✅ Usuário é autenticado
- ✅ HomeView aparece

---

## 🐛 TROUBLESHOOTING

### Erro: "No such module 'Firebase'"

**Solução:**
1. Clean Build Folder: `⌘ + Shift + K`
2. Quit Xcode
3. Delete DerivedData:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```
4. Reabrir Xcode
5. Build novamente

---

### Erro: "GoogleService-Info.plist not found"

**Solução:**
1. No Xcode Navigator, verifique se o arquivo está lá
2. Clique no arquivo → File Inspector (painel direito)
3. Em "Target Membership", marque ✅ "Resumed"

---

### Google Sign-In não abre

**Solução:**
1. Verifique se adicionou o URL Scheme correto (Passo 5.3)
2. Verifique se o REVERSED_CLIENT_ID está correto
3. No Info.plist, adicione:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.SEU_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

---

### Analytics não aparece no Firebase Console

**Normal!** Analytics pode demorar:
- **24 horas** para aparecer no console
- **1-2 horas** para eventos em tempo real

**Verifique:**
- Xcode Console: Deve ter logs `[Firebase/Analytics]`
- Se tiver, está funcionando!

---

## 📊 Eventos Rastreados Automaticamente

Com Firebase configurado, o app já está rastreando:

**User Events:**
```
- user_signup (método: Google)
- user_login
- screen_view (todas as telas)
- session_start
```

**Study Events:**
```
- question_answered (subject, correct, time_spent)
- flashcard_reviewed (quality, subject)
- study_session_started
- study_session_completed
- level_up (new_level, xp_earned)
- badge_unlocked (badge_id)
```

**Engagement Events:**
```
- daily_goal_completed
- streak_milestone (days)
- exam_started (exam_id, institution)
- exam_completed (score, time_spent)
```

---

## 🎉 Pronto!

Firebase está configurado e funcionando!

**Próximos passos:**
1. [ ] Testar login com Google
2. [ ] Ver eventos no Firebase Console
3. [ ] Configurar push notifications (opcional)
4. [ ] Adicionar Remote Config (A/B testing)

---

**RESUMED iOS + Firebase** 🔥
Versão 1.0 | Janeiro 2026
