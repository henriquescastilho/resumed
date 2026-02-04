# 🛠️ RESUMED iOS - Tech Stack

**Tecnologias, Frameworks e Dependências**

---

## 📱 Core Technologies

### **Linguagem**
- **Swift 5.9+**
  - Async/await para networking
  - Structured concurrency (Tasks, AsyncSequence)
  - Modern error handling

### **UI Framework**
- **SwiftUI 4**
  - Declarative UI
  - State management (@State, @StateObject, @EnvironmentObject)
  - NavigationStack (iOS 16+)
  - Animations nativas

### **Minimum Deployment Target**
- **iOS 16.0+**
- **iPadOS 16.0+**

---

## 🏗️ Arquitetura

### **Padrão: MVVM (Model-View-ViewModel)**

```swift
// Model
struct UserProfile: Codable, Identifiable {
    let id: UUID
    let name: String
    let targetExams: [String]
    // ...
}

// ViewModel
@MainActor
class PlanViewModel: ObservableObject {
    @Published var plan: StudyPlan?
    @Published var isLoading = false

    func loadPlan() async {
        // Fetch from API...
    }
}

// View
struct PlanView: View {
    @StateObject private var viewModel = PlanViewModel()

    var body: some View {
        // UI...
    }
}
```

---

## 📦 Dependências (Swift Package Manager)

### **1. Networking & API**

#### **Alamofire** (Opcional - usar URLSession nativo é preferível)
```swift
// Se usar Alamofire:
.package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0")

// Preferência: URLSession nativo com async/await
```

**Decisão:** ✅ **URLSession nativo** (sem dependência externa)

---

### **2. Autenticação**

#### **Firebase Authentication**
```swift
.package(
    url: "https://github.com/firebase/firebase-ios-sdk",
    from: "10.20.0"
)
```

**Features usadas:**
- Google Sign-In
- ID Token para backend

**Configuração:**
```swift
import FirebaseCore
import FirebaseAuth

// AppDelegate
FirebaseApp.configure()

// Sign in
func signInWithGoogle() async throws -> String {
    let result = try await Auth.auth().signIn(with: credential)
    let idToken = try await result.user.getIDToken()
    return idToken
}
```

---

### **3. Persistência Local**

#### **Core Data** (Nativo - sem dependência)
```swift
// Stack nativo do iOS
import CoreData

// PersistenceController.swift
struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    // ...
}
```

**Entities:**
- `UserProfileEntity`
- `StudyPlanEntity`
- `ResuCardEntity`
- `QuestionEntity`
- `PerformanceRecordEntity`

---

### **4. Keychain (Segurança)**

#### **KeychainAccess** (Wrapper simplificado)
```swift
.package(
    url: "https://github.com/kishikawakatsumi/KeychainAccess.git",
    from: "4.2.2"
)
```

**Uso:**
```swift
import KeychainAccess

let keychain = Keychain(service: "com.resumed.app")

// Save
keychain["jwt_token"] = jwtToken

// Retrieve
let token = keychain["jwt_token"]
```

**Alternativa:** ✅ **Security framework nativo** (sem dependência)

---

### **5. Markdown Rendering**

#### **MarkdownUI** (Para textos formatados do Grey)
```swift
.package(
    url: "https://github.com/gonzalezreal/swift-markdown-ui",
    from: "2.3.0"
)
```

**Uso:**
```swift
import MarkdownUI

Markdown("""
**Insuficiência Cardíaca**

Principais sintomas:
- Dispneia
- Edema de MMII
""")
.markdownTheme(.gitHub)
```

---

### **6. Charts & Analytics**

#### **Swift Charts** (Nativo iOS 16+)
```swift
import Charts

// Radar chart para performance
Chart(data) {
    LineMark(x: .value("Área", $0.area), y: .value("Score", $0.score))
        .foregroundStyle(.resumed.gold)
}
```

**Features:**
- ✅ Radar charts (competências)
- ✅ Bar charts (horas/semana)
- ✅ Line charts (progresso temporal)
- ✅ Animações nativas

---

### **7. AI Integration**

#### **Google Generative AI SDK**
```swift
.package(
    url: "https://github.com/google/generative-ai-swift",
    from: "0.4.0"
)
```

**Uso:**
```swift
import GoogleGenerativeAI

let model = GenerativeModel(
    name: "gemini-1.5-flash",
    apiKey: APIKey.gemini
)

let response = try await model.generateContent(prompt)
```

**Alternativa:** ✅ **Via Backend API** (mais seguro)

---

## 🎨 UI Components

### **Design System**

#### **Custom Components (Swift Package interno)**
```swift
// ResumedUIKit/
├── Components/
│   ├── ResumedCard.swift
│   ├── GoldButton.swift
│   ├── OutlineButton.swift
│   ├── ProgressRing.swift
│   └── StatCard.swift
├── Extensions/
│   ├── Color+Resumed.swift
│   └── View+Extensions.swift
└── Theme/
    └── ResumedTheme.swift
```

**Exemplo:**
```swift
struct GoldButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.resumed.gold)
                .cornerRadius(12)
        }
    }
}
```

---

## 📡 Networking Layer

### **APIClient (Custom)**

```swift
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum APIError: Error {
    case invalidURL
    case unauthorized
    case serverError(Int)
    case decodingError
}

@MainActor
class APIClient {
    static let shared = APIClient()
    private let baseURL = "https://api.resumed.app"
    private let session = URLSession.shared

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add JWT token
        if requiresAuth, let token = SessionManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add body
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError(0)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            throw APIError.serverError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }
}
```

---

## 🔔 Notifications

### **Local Notifications** (UserNotifications framework)

```swift
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
            return false
        }
    }

    func scheduleDailyReminder(at hour: Int) {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )

        let content = UNMutableNotificationContent()
        content.title = "RESUMED"
        content.body = "Bom dia! Você tem 15 ResuCards para revisar 🧠"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "dailyReminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
```

---

## 📊 Analytics

### **Apple Analytics** (Nativo - sem 3rd party)

```swift
import os.log

class AnalyticsManager {
    static let shared = AnalyticsManager()
    private let logger = Logger(
        subsystem: "com.resumed.app",
        category: "analytics"
    )

    func track(event: String, parameters: [String: Any]? = nil) {
        logger.info("Event: \(event), Params: \(parameters ?? [:])")
        // Processar localmente, enviar para backend se necessário
    }
}

// Uso
AnalyticsManager.shared.track(
    event: "question_answered",
    parameters: ["area": "Cardiologia", "correct": true]
)
```

---

## 🧪 Testing

### **Frameworks:**

1. **XCTest** (Nativo - Unit Tests)
```swift
import XCTest
@testable import ResumedApp

final class PlanViewModelTests: XCTestCase {
    func testLoadPlan() async throws {
        let viewModel = PlanViewModel()
        await viewModel.loadPlan()
        XCTAssertNotNil(viewModel.plan)
    }
}
```

2. **SwiftUI Previews** (Live development)
```swift
#Preview {
    HomeView()
        .environmentObject(UserViewModel())
}
```

---

## 🔧 Build Configuration

### **Xcode Build Settings:**

```swift
// Debug
API_BASE_URL = "https://dev-api.resumed.app"
GEMINI_API_KEY = "dev-key"

// Release
API_BASE_URL = "https://api.resumed.app"
GEMINI_API_KEY = "prod-key"
```

### **Info.plist:**
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>

<key>UIUserInterfaceStyle</key>
<string>Dark</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>resumed</string>
        </array>
    </dict>
</array>
```

---

## 📋 Dependências Finais (Package.swift)

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ResumedApp",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "ResumedApp", targets: ["ResumedApp"]),
    ],
    dependencies: [
        // Firebase (Auth)
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk",
            from: "10.20.0"
        ),
        // Keychain
        .package(
            url: "https://github.com/kishikawakatsumi/KeychainAccess.git",
            from: "4.2.2"
        ),
        // Markdown
        .package(
            url: "https://github.com/gonzalezreal/swift-markdown-ui",
            from: "2.3.0"
        ),
    ],
    targets: [
        .target(
            name: "ResumedApp",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                "KeychainAccess",
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ]
        ),
    ]
)
```

---

## 🚀 CI/CD

### **Fastlane** (Build automation)

```ruby
# Fastfile
default_platform(:ios)

platform :ios do
  desc "Run tests"
  lane :test do
    run_tests(scheme: "ResumedApp")
  end

  desc "Build for TestFlight"
  lane :beta do
    increment_build_number
    build_app(scheme: "ResumedApp")
    upload_to_testflight
  end

  desc "Release to App Store"
  lane :release do
    build_app(scheme: "ResumedApp")
    upload_to_app_store
  end
end
```

---

## 📝 Versioning

### **Semantic Versioning:**
- **Major.Minor.Patch** (ex: 1.0.0)
- Build number auto-incrementado

### **Git Tags:**
```bash
git tag -a v1.0.0 -m "Release 1.0.0 - MVP Launch"
git push origin v1.0.0
```

---

**Última atualização:** 30/01/2026
**Versão do documento:** 1.0
