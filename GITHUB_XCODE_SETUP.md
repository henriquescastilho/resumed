# 📱 Como Sincronizar GitHub com Xcode - RESUMED

**Guia completo para configurar Git/GitHub no projeto iOS**

---

## 🎯 Duas Abordagens

### Opção A: Criar Repo no GitHub primeiro (RECOMENDADO) ✅
### Opção B: Inicializar Git localmente e depois subir

Vou explicar as duas, mas **recomendo a Opção A** por ser mais simples.

---

## 🚀 OPÇÃO A: GitHub → Xcode (RECOMENDADO)

### Passo 1: Criar Repositório no GitHub

1. **Acesse** [github.com](https://github.com)
2. **Clique** no botão **"New"** (ou **"+"** → **"New repository"**)
3. **Configure o repositório:**

```
Repository name: resumed-ios
Description: 🏥 RESUMED - Plataforma revolucionária de estudos para residência médica (iOS)
Visibility: ⚫ Private (ou Public se quiser abrir)

✅ Add a README file
✅ Add .gitignore → escolha "Swift"
❌ Choose a license (adicionar depois se necessário)
```

4. **Clique em** `Create repository`

5. **Copie a URL do repositório** (vai aparecer na tela):
```
https://github.com/SEU_USERNAME/resumed-ios.git
```

---

### Passo 2: Criar Projeto no Xcode

1. **Abra o Xcode**
2. **File → New → Project**
3. **Escolha:** `iOS → App`
4. **Configure:**

```
Product Name: Resumed
Team: Seu Apple Developer Account (ou None por enquanto)
Organization Identifier: com.resumed (ou seu domínio)
Bundle Identifier: com.resumed.Resumed (gerado automaticamente)
Interface: SwiftUI
Language: Swift
Storage: Core Data ✅
Include Tests: ✅ (marcar)
```

5. **Clique em** `Next`

6. **IMPORTANTE:** Na tela "Save As":
   - **DESMARQUE** "Create Git repository on my Mac"
   - Escolha onde salvar (ex: `~/Documents/Resumed`)
   - Clique em **Create**

---

### Passo 3: Conectar Xcode ao GitHub

Agora vamos conectar o projeto Xcode ao repositório GitHub.

#### 3.1. Adicionar Conta do GitHub no Xcode

1. **Xcode → Settings (ou Preferences)** `⌘,`
2. **Aba "Accounts"**
3. **Clique no "+"** (canto inferior esquerdo)
4. **Escolha:** `GitHub`
5. **Faça login** com sua conta GitHub
6. **Autorize** o Xcode quando o navegador abrir
7. **Feche** a janela de Settings

#### 3.2. Inicializar Git no Projeto

**Opção 1: Via Terminal**

```bash
# 1. Navegue até a pasta do projeto
cd ~/Documents/Resumed

# 2. Inicialize o Git
git init

# 3. Adicione o remote do GitHub
git remote add origin https://github.com/SEU_USERNAME/resumed-ios.git

# 4. Baixe o .gitignore que você criou no GitHub
git pull origin main --allow-unrelated-histories

# 5. Adicione todos os arquivos
git add .

# 6. Faça o primeiro commit
git commit -m "🎉 Initial commit - RESUMED iOS App

- Setup projeto SwiftUI + Core Data
- Estrutura MVVM inicial
- Design System (Gold + Black theme)
- Preparado para desenvolvimento MVP"

# 7. Renomeie a branch para main (se necessário)
git branch -M main

# 8. Faça o push
git push -u origin main
```

**Opção 2: Via Xcode (mais visual)**

1. No Xcode, vá em **Source Control → New Git Repositories...**
2. **Selecione** seu projeto na lista
3. **Clique** em `Create`
4. Agora adicione o remote:
   - **Source Control → Manage Remotes...**
   - **Clique em "+"**
   - **Name:** `origin`
   - **Address:** `https://github.com/SEU_USERNAME/resumed-ios.git`
   - **Clique** em `Add`

5. **Fazer commit inicial:**
   - **Source Control → Commit...**
   - **Escreva** a mensagem: "🎉 Initial commit - RESUMED iOS App"
   - **Marque** todos os arquivos
   - **Clique** em `Commit`

6. **Fazer push:**
   - **Source Control → Push...**
   - **Selecione** a branch `main`
   - **Clique** em `Push`

---

### Passo 4: Verificar no GitHub

1. Acesse `https://github.com/SEU_USERNAME/resumed-ios`
2. Você deve ver todos os arquivos do projeto! ✅

---

## 🔧 OPÇÃO B: Git Local → GitHub (Alternativa)

Se você já criou o projeto no Xcode COM o Git habilitado, siga estes passos:

### Passo 1: Criar Repo Vazio no GitHub

1. GitHub.com → **New repository**
2. **Nome:** `resumed-ios`
3. **⚠️ NÃO MARQUE** nenhuma opção (README, .gitignore, License)
4. **Clique** em `Create repository`

### Passo 2: Conectar ao Remote

```bash
cd ~/Documents/Resumed

# Adicionar remote
git remote add origin https://github.com/SEU_USERNAME/resumed-ios.git

# Renomear branch para main (se necessário)
git branch -M main

# Push
git push -u origin main
```

---

## 📝 .gitignore para iOS (IMPORTANTE)

O Xcode gera MUITOS arquivos que não devem ir para o Git. Use este `.gitignore`:

```gitignore
# Xcode
#
# gitignore contributors: remember to update Global/Xcode.gitignore, Objective-C.gitignore & Swift.gitignore

## User settings
xcuserdata/

## Compatibility with Xcode 8 and earlier (ignoring not required starting Xcode 9)
*.xcscmblueprint
*.xccheckout

## Compatibility with Xcode 3 and earlier (ignoring not required starting Xcode 4)
build/
DerivedData/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

## Obj-C/Swift specific
*.hmap

## App packaging
*.ipa
*.dSYM.zip
*.dSYM

## Playgrounds
timeline.xctimeline
playground.xcworkspace

# Swift Package Manager
#
# Add this line if you want to avoid checking in source code from Swift Package Manager dependencies.
# Packages/
# Package.pins
# Package.resolved
# *.xcodeproj
#
# Xcode automatically generates this directory with a .xcworkspacedata file and xcuserdata
# hence it is not needed unless you have added a package configuration file to your project
# .swiftpm

.build/

# CocoaPods
#
# We recommend against adding the Pods directory to your .gitignore. However
# you should judge for yourself, the pros and cons are mentioned at:
# https://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control
#
# Pods/
#
# Add this line if you want to avoid checking in source code from the Xcode workspace
# *.xcworkspace

# Carthage
#
# Add this line if you want to avoid checking in source code from Carthage dependencies.
# Carthage/Checkouts

Carthage/Build/

# Accio dependency management
Dependencies/
.accio/

# fastlane
#
# It is recommended to not store the screenshots in the git repo.
# Instead, use fastlane to re-generate the screenshots whenever they are needed.
# For more information about the recommended setup visit:
# https://docs.fastlane.tools/best-practices/source-control/#source-control

fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# Code Injection
#
# After new code Injection tools there's a generated folder /iOSInjectionProject
# https://github.com/johnno1962/injectionforxcode

iOSInjectionProject/

# macOS
.DS_Store

# Secrets & API Keys
Config/Secrets.plist
Config/GoogleService-Info.plist
*.xcconfig

# SPM (Swift Package Manager)
.swiftpm/
xcuserdata/
```

**Como adicionar:**

```bash
# Criar .gitignore na raiz do projeto
cd ~/Documents/Resumed
nano .gitignore

# Cole o conteúdo acima
# Salve: Ctrl+O, Enter, Ctrl+X

# Adicione ao Git
git add .gitignore
git commit -m "📝 Add comprehensive .gitignore for iOS"
git push
```

---

## 🌿 Workflow de Branches (Boas Práticas)

### Estrutura Recomendada

```
main (produção, sempre estável)
  └── develop (desenvolvimento, features integradas)
       ├── feature/onboarding
       ├── feature/home-view
       ├── feature/study-plan
       ├── feature/grey-ai
       └── feature/flashcards
```

### Criar Branch para Nova Feature

```bash
# 1. Certifique-se de estar na develop
git checkout develop

# 2. Atualize
git pull origin develop

# 3. Crie nova branch
git checkout -b feature/onboarding

# 4. Trabalhe normalmente...
# ... código ...

# 5. Commit
git add .
git commit -m "✨ Implement onboarding flow

- Add 7 onboarding steps
- Implement swipe navigation
- Add progress indicator
- Connect to AuthManager"

# 6. Push para GitHub
git push -u origin feature/onboarding
```

### Fazer Merge via Pull Request

1. **No GitHub:** Vá até seu repositório
2. **Clique** em `Pull requests` → `New pull request`
3. **Base:** `develop` ← **Compare:** `feature/onboarding`
4. **Escreva** descrição detalhada
5. **Create pull request**
6. **Revise** (ou peça review)
7. **Merge** quando aprovado
8. **Delete** a branch (GitHub oferece essa opção)

### Atualizar Branch Local Após Merge

```bash
# Voltar para develop
git checkout develop

# Atualizar
git pull origin develop

# Deletar branch local
git branch -d feature/onboarding
```

---

## 💻 Comandos Git Mais Usados no Dia a Dia

### Commit Rápido

```bash
# Ver status
git status

# Adicionar arquivos específicos
git add Resumed/Features/Home/Views/HomeView.swift

# Ou adicionar tudo
git add .

# Commit
git commit -m "🐛 Fix XP calculation bug"

# Push
git push
```

### Commit Types (Emojis Opcionais)

```bash
git commit -m "✨ Add new feature"           # Nova feature
git commit -m "🐛 Fix bug in API client"     # Bug fix
git commit -m "♻️ Refactor HomeViewModel"    # Refactor
git commit -m "💄 Update UI colors"          # UI/Style
git commit -m "📝 Update documentation"      # Docs
git commit -m "🚀 Improve performance"       # Performance
git commit -m "✅ Add unit tests"            # Tests
git commit -m "🔧 Update config"             # Configuration
git commit -m "🎨 Improve code structure"    # Structure
```

### Ver Histórico

```bash
# Ver commits recentes
git log --oneline -10

# Ver mudanças de um arquivo
git log -p Resumed/Core/Models/User.swift

# Ver quem mudou o quê
git blame Resumed/Core/Services/APIClient.swift
```

### Desfazer Mudanças

```bash
# Desfazer mudanças não commitadas (CUIDADO!)
git checkout -- arquivo.swift

# Desfazer último commit (mantém arquivos)
git reset --soft HEAD~1

# Voltar para um commit específico
git reset --hard <commit-hash>

# Reverter um commit (cria novo commit)
git revert <commit-hash>
```

### Stash (Guardar mudanças temporariamente)

```bash
# Guardar mudanças
git stash

# Ver stashes
git stash list

# Recuperar último stash
git stash pop

# Recuperar stash específico
git stash apply stash@{0}
```

---

## 🔗 Integração Xcode com Git (Interface Visual)

### Ver Mudanças (Diff)

1. **Clique** em qualquer arquivo modificado
2. **Editor → Show Authors** `⌘⇧A` (mostra quem mudou cada linha)
3. **Editor → Show Change** (mostra diff)

### Commit via Xcode

1. **Source Control → Commit...** `⌥⌘C`
2. **Selecione** os arquivos
3. **Escreva** mensagem
4. **Clique** em `Commit X files`

### Ver Histórico

1. **Source Control → History...**
2. Selecione arquivo/pasta
3. Veja todos os commits

### Resolver Conflitos

1. Quando houver conflito, Xcode mostra ícone de alerta
2. **Clique** no arquivo conflitante
3. **Editor → Show Change**
4. **Choose Left** (sua versão) ou **Choose Right** (versão remota)
5. Ou edite manualmente
6. **Marque como resolvido**
7. **Commit**

---

## 🚨 Arquivos Sensíveis (NUNCA COMMITAR)

⚠️ **NUNCA adicione ao Git:**

```
❌ Config/Secrets.plist
❌ Config/GoogleService-Info.plist
❌ .env files
❌ API keys hardcoded
❌ Senhas
❌ Certificados (.p12, .cer)
❌ Provisioning Profiles
```

**Como proteger:**

1. **Use** `.gitignore` (já incluído acima)
2. **Crie** arquivo separado para secrets:

```swift
// Config/Secrets.swift (adicionar ao .gitignore)
enum Secrets {
    static let apiKey = "sk-abc123..."
    static let firebaseAPIKey = "AIza..."
}
```

3. **Ou use** arquivos de configuração:

```swift
// Config/Environment.swift
enum Environment {
    static let apiBaseURL: String = {
        #if DEBUG
        return "http://localhost:3000/v1"
        #else
        return "https://api.resumed.app/v1"
        #endif
    }()
}
```

---

## 📊 GitHub Features Úteis

### 1. Issues (Tarefas)

Crie issues para organizar o trabalho:

```
Título: Implementar onboarding flow
Labels: feature, ios, high-priority

Descrição:
- [ ] Criar OnboardingView
- [ ] Implementar navegação entre steps
- [ ] Conectar com AuthManager
- [ ] Adicionar animações
```

### 2. Projects (Kanban)

1. **Crie** um projeto no GitHub
2. **Adicione** colunas: `To Do`, `In Progress`, `Done`
3. **Arraste** issues entre colunas

### 3. Actions (CI/CD)

Automatize testes e build:

```yaml
# .github/workflows/ios.yml
name: iOS CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v3

    - name: Build
      run: xcodebuild -scheme Resumed -destination 'platform=iOS Simulator,name=iPhone 15' build

    - name: Test
      run: xcodebuild -scheme Resumed -destination 'platform=iOS Simulator,name=iPhone 15' test
```

---

## 🎯 Workflow Completo (Exemplo)

### Segunda-feira: Iniciar Feature

```bash
git checkout develop
git pull origin develop
git checkout -b feature/grey-ai-chat

# ... codificar ...

git add .
git commit -m "✨ Add Grey AI chat interface

- Implement GreyView with SwiftUI
- Add MessageBubble component
- Connect to APIClient
- Add typing indicator"

git push -u origin feature/grey-ai-chat
```

### Durante a Semana: Commits Incrementais

```bash
# ... mais código ...
git add Resumed/Features/Grey/
git commit -m "♻️ Refactor GreyViewModel state management"
git push

# ... mais código ...
git add .
git commit -m "✅ Add unit tests for chat logic"
git push
```

### Sexta-feira: Merge na Develop

1. **GitHub:** Create Pull Request
2. **Revise** o código
3. **Merge** pull request
4. **Delete** branch remota

```bash
# Localmente
git checkout develop
git pull origin develop
git branch -d feature/grey-ai-chat
```

---

## 🆘 Problemas Comuns

### "The project is not under version control"

```bash
cd ~/Documents/Resumed
git init
git add .
git commit -m "Initial commit"
```

### "Remote origin already exists"

```bash
git remote remove origin
git remote add origin https://github.com/SEU_USERNAME/resumed-ios.git
```

### "Your branch is behind origin/main"

```bash
git pull origin main
# Ou, se houver conflitos:
git pull origin main --rebase
```

### "Merge conflict in file.swift"

```bash
# 1. Abra o arquivo no Xcode
# 2. Resolva os conflitos manualmente (escolha entre <<< e >>>)
# 3. Marque como resolvido
git add arquivo.swift
git commit -m "🔀 Resolve merge conflict"
git push
```

### Esqueci de criar branch, já fiz mudanças

```bash
# Stash suas mudanças
git stash

# Crie a branch
git checkout -b feature/minha-feature

# Recupere as mudanças
git stash pop

# Continue normalmente
git add .
git commit -m "..."
```

---

## ✅ Checklist Final

Antes de fazer push, sempre verifique:

- [ ] Código compila sem erros
- [ ] Testes passam (se houver)
- [ ] Sem `print()` debug desnecessários
- [ ] Sem force unwraps (`!`) em produção
- [ ] Sem TODOs críticos
- [ ] Mensagem de commit descritiva
- [ ] Nenhum arquivo sensível (API keys, secrets)
- [ ] .gitignore atualizado

---

## 🎓 Recursos Extras

**Aprender Git:**
- [Git - Guia Prático](https://rogerdudler.github.io/git-guide/index.pt_BR.html)
- [GitHub Skills](https://skills.github.com/)
- [Oh My Git! (jogo)](https://ohmygit.org/)

**Xcode + Git:**
- [Apple Docs - Source Control](https://developer.apple.com/documentation/xcode/source-control-management)
- [Raywenderlich - Git Tutorial](https://www.raywenderlich.com/books/advanced-git/v1.0)

**Git GUI (alternativas ao Xcode):**
- [Sourcetree](https://www.sourcetreeapp.com/) (Free)
- [Fork](https://git-fork.com/) (Free)
- [GitKraken](https://www.gitkraken.com/) (Pago, mas bonito)

---

## 🚀 Pronto para Começar!

Agora você tem:
- ✅ Repositório GitHub configurado
- ✅ Xcode conectado ao Git
- ✅ .gitignore completo
- ✅ Workflow de branches
- ✅ Comandos essenciais

**Boa codificação! 💪**

---

**RESUMED iOS**
*Git + GitHub Setup Guide*
Versão 1.0 | Janeiro 2026
