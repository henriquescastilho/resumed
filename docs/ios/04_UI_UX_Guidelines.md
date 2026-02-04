# 04. UI/UX Guidelines - RESUMED iOS

## Design System

### Color Palette

```swift
extension Color {
    static let resumed = ResumedColors()
}

struct ResumedColors {
    // Primary Colors
    let gold = Color(hex: "D4A54A")           // Primary/Accent
    let goldLight = Color(hex: "E5C572")      // Hover states
    let goldDark = Color(hex: "8C6A28")       // Active states

    // Background
    let black = Color(hex: "000000")          // Main background
    let blackSecondary = Color(hex: "050505") // Card background
    let blackTertiary = Color(hex: "0A0A0A")  // Elevated cards

    // Border & Dividers
    let border = Color(hex: "1F1F1F")         // Default borders
    let borderLight = Color(hex: "333333")    // Hover borders

    // Text
    let white = Color(hex: "FFFFFF")          // Primary text
    let gray = Color(hex: "777777")           // Secondary text
    let grayLight = Color(hex: "A3A3A3")      // Tertiary text

    // Semantic Colors
    let success = Color(hex: "10B981")        // Green for correct answers
    let error = Color(hex: "EF4444")          // Red for errors/wrong answers
    let warning = Color(hex: "F59E0B")        // Yellow for warnings
    let info = Color(hex: "3B82F6")           // Blue for info
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double((rgbValue & 0x0000FF)) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
```

### Typography

```swift
extension Font {
    static let resumed = ResumedTypography()
}

struct ResumedTypography {
    // Headlines
    let h1 = Font.system(size: 32, weight: .black, design: .default)
    let h2 = Font.system(size: 24, weight: .bold, design: .default)
    let h3 = Font.system(size: 20, weight: .bold, design: .default)
    let h4 = Font.system(size: 18, weight: .semibold, design: .default)

    // Body
    let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    let body = Font.system(size: 14, weight: .regular, design: .default)
    let bodySmall = Font.system(size: 12, weight: .regular, design: .default)

    // Special
    let caption = Font.system(size: 10, weight: .regular, design: .default)
    let mono = Font.system(size: 12, weight: .regular, design: .monospaced)
    let button = Font.system(size: 14, weight: .bold, design: .default)
}
```

### Spacing System

```swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
```

### Corner Radius

```swift
enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let round: CGFloat = 999  // For fully rounded elements
}
```

## Reusable Components

### ResumedCard

```swift
struct ResumedCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = Spacing.md
    var background: Color = Color.resumed.blackSecondary
    var border: Color? = nil

    init(
        padding: CGFloat = Spacing.md,
        background: Color = Color.resumed.blackSecondary,
        border: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.background = background
        self.border = border
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(background)
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(border ?? .clear, lineWidth: 1)
            )
    }
}

// Usage
ResumedCard {
    VStack(alignment: .leading, spacing: Spacing.sm) {
        Text("Título")
            .font(.resumed.h3)
            .foregroundColor(.resumed.white)
        Text("Descrição")
            .font(.resumed.body)
            .foregroundColor(.resumed.gray)
    }
}
```

### ResumedButton

```swift
enum ButtonStyle {
    case primary
    case secondary
    case ghost
}

struct ResumedButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    var fullWidth: Bool = false
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                }
                Text(title)
                    .font(.resumed.button)
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(backgroundColor)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return Color.resumed.gold
        case .secondary: return Color.resumed.blackSecondary
        case .ghost: return .clear
        }
    }

    private var textColor: Color {
        switch style {
        case .primary: return Color.resumed.black
        case .secondary, .ghost: return Color.resumed.white
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: return .clear
        case .secondary, .ghost: return Color.resumed.border
        }
    }
}

// Usage
ResumedButton(title: "Continuar", style: .primary, action: {
    // Action
}, fullWidth: true)
```

### ResumedTextField

```swift
struct ResumedTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: Image? = nil
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            if let icon = icon {
                icon
                    .foregroundColor(.resumed.gray)
            }

            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle()
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle()
            }
        }
        .padding(Spacing.md)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.resumed.border, lineWidth: 1)
        )
    }
}

extension View {
    func textFieldStyle() -> some View {
        self
            .font(.resumed.body)
            .foregroundColor(.resumed.white)
            .autocapitalization(.none)
            .disableAutocorrection(true)
    }
}
```

### ProgressBar

```swift
struct ProgressBar: View {
    let current: Int
    let total: Int
    var height: CGFloat = 8
    var showLabel: Bool = true

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if showLabel {
                HStack {
                    Text("\(current)/\(total)")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color.resumed.blackSecondary)

                    // Progress
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color.resumed.gold)
                        .frame(width: geometry.size.width * progress)
                        .shadow(color: Color.resumed.gold.opacity(0.5), radius: 4)
                }
            }
            .frame(height: height)
        }
    }
}
```

### XPBadge

```swift
struct XPBadge: View {
    let xp: Int
    var size: CGFloat = 24

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.6))
            Text("+\(xp)")
                .font(.system(size: size * 0.7, weight: .bold, design: .rounded))
        }
        .foregroundColor(.resumed.gold)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.resumed.gold.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(Color.resumed.gold.opacity(0.3), lineWidth: 1)
        )
    }
}
```

### EmptyState

```swift
struct EmptyState: View {
    let icon: Image
    let title: String
    let subtitle: String
    var action: (() -> Void)? = nil
    var actionTitle: String? = nil

    var body: some View {
        VStack(spacing: Spacing.lg) {
            icon
                .font(.system(size: 64))
                .foregroundColor(.resumed.gray)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.resumed.h3)
                    .foregroundColor(.resumed.white)

                Text(subtitle)
                    .font(.resumed.body)
                    .foregroundColor(.resumed.gray)
                    .multilineTextAlignment(.center)
            }

            if let action = action, let actionTitle = actionTitle {
                ResumedButton(title: actionTitle, style: .primary, action: action)
            }
        }
        .padding(Spacing.xl)
    }
}
```

## Responsive Design

### Size Classes

```swift
enum DeviceType {
    case iPhone
    case iPadPortrait
    case iPadLandscape

    static func current(for horizontalSizeClass: UserInterfaceSizeClass?,
                       verticalSizeClass: UserInterfaceSizeClass?) -> DeviceType {
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            return .iPadLandscape
        } else if horizontalSizeClass == .compact && verticalSizeClass == .regular {
            return .iPhone
        } else {
            return .iPadPortrait
        }
    }
}

// Usage in views
@Environment(\.horizontalSizeClass) var horizontalSizeClass
@Environment(\.verticalSizeClass) var verticalSizeClass

var deviceType: DeviceType {
    DeviceType.current(for: horizontalSizeClass, verticalSizeClass)
}

// Conditional layout
if deviceType == .iPadLandscape {
    HStack { /* Two-column layout */ }
} else {
    VStack { /* Single-column layout */ }
}
```

### iPad-Specific Adaptations

#### Home Screen (iPad)
- **Landscape**: Show statistics cards in 2 columns instead of 1
- **Portrait**: Similar to iPhone but with larger cards (320pt width)

#### Meu Plano Screen (iPad)
- **Landscape**: Display calendar and task list side-by-side
- **Portrait**: Stack calendar above task list

#### Grey Chat (iPad)
- **Landscape**: Show chat history sidebar (280pt) + main chat area
- **Portrait**: Full-width chat with slide-over history

#### ResuCards (iPad)
- **Landscape**: Show flashcard (600pt width) centered with stats sidebar
- **Portrait**: Full-width cards with bottom stats panel

#### Desempenho (iPad)
- **Landscape**: Show radar chart and bar chart side-by-side
- **Portrait**: Stack charts vertically

#### Provas Anteriores (iPad)
- **Landscape**: Show exam list (360pt) + question detail split view
- **Portrait**: Master-detail navigation

### Adaptive Spacing

```swift
extension Spacing {
    static func adaptive(for deviceType: DeviceType, base: CGFloat) -> CGFloat {
        switch deviceType {
        case .iPhone:
            return base
        case .iPadPortrait:
            return base * 1.25
        case .iPadLandscape:
            return base * 1.5
        }
    }
}
```

## Animations

### Standard Transitions

```swift
extension AnyTransition {
    static var slideFromBottom: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }

    static var fadeIn: AnyTransition {
        .opacity.animation(.easeInOut(duration: 0.3))
    }

    static var scaleAndFade: AnyTransition {
        .scale(scale: 0.95).combined(with: .opacity)
    }
}
```

### Interaction Animations

```swift
// Button press animation
.scaleEffect(isPressed ? 0.95 : 1.0)
.animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)

// Card reveal animation
.opacity(isVisible ? 1 : 0)
.scaleEffect(isVisible ? 1 : 0.9)
.animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)

// Slide-in animation
.offset(x: isShowing ? 0 : UIScreen.main.bounds.width)
.animation(.spring(response: 0.5, dampingFraction: 0.75), value: isShowing)
```

### Loading States

```swift
struct ShimmerEffect: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        LinearGradient(
            colors: [
                Color.resumed.blackSecondary,
                Color.resumed.border,
                Color.resumed.blackSecondary
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: phase)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 400
            }
        }
    }
}

// Usage
ResumedCard {
    VStack(spacing: Spacing.md) {
        ShimmerEffect()
            .frame(height: 20)
        ShimmerEffect()
            .frame(height: 20)
    }
}
```

## Accessibility

### VoiceOver Support

```swift
// Card with accessibility
ResumedCard {
    VStack {
        Text(title)
        Text(subtitle)
    }
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(title), \(subtitle)")
.accessibilityHint("Toque duas vezes para abrir")

// Button with accessibility
ResumedButton(title: "Continuar", style: .primary) {
    // Action
}
.accessibilityLabel("Continuar para próxima questão")
.accessibilityHint("Avança para a próxima pergunta do estudo")
```

### Dynamic Type

```swift
// All text should support Dynamic Type
Text("Título")
    .font(.resumed.h2)
    .dynamicTypeSize(.medium...  .xxxLarge)  // Limit scaling if needed

// For custom fonts
.font(.system(size: 18, weight: .bold))
.dynamicTypeSize(.large)
```

### Color Contrast

Todas as cores seguem WCAG AA (mínimo 4.5:1 para texto normal):
- Gold (#D4A54A) em Black (#000000): 8.2:1 ✅
- White (#FFFFFF) em Black (#000000): 21:1 ✅
- Gray (#777777) em Black (#000000): 4.6:1 ✅

## Dark Mode

O app possui apenas tema escuro (dark mode permanente):
- Simplifica o design system
- Reduz fadiga visual durante estudo noturno
- Economiza bateria em dispositivos OLED

```swift
// Força dark mode permanente
.preferredColorScheme(.dark)
```

## Haptic Feedback

```swift
class HapticManager {
    static let shared = HapticManager()

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// Usage
// Correct answer
HapticManager.shared.notification(.success)

// Wrong answer
HapticManager.shared.notification(.error)

// Card flip
HapticManager.shared.impact(.medium)

// Button tap
HapticManager.shared.impact(.light)

// List selection
HapticManager.shared.selection()
```

## Loading & Error States

### Loading Skeleton

```swift
struct LoadingView: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                ResumedCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ShimmerEffect()
                            .frame(height: 24)
                            .frame(maxWidth: 200)

                        ShimmerEffect()
                            .frame(height: 16)
                            .frame(maxWidth: .infinity)

                        ShimmerEffect()
                            .frame(height: 16)
                            .frame(maxWidth: 250)
                    }
                }
            }
        }
        .padding(Spacing.md)
    }
}
```

### Error View

```swift
struct ErrorView: View {
    let error: Error
    let retry: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(.resumed.error)

            VStack(spacing: Spacing.sm) {
                Text("Algo deu errado")
                    .font(.resumed.h3)
                    .foregroundColor(.resumed.white)

                Text(error.localizedDescription)
                    .font(.resumed.body)
                    .foregroundColor(.resumed.gray)
                    .multilineTextAlignment(.center)
            }

            ResumedButton(title: "Tentar novamente", style: .primary, action: retry)
        }
        .padding(Spacing.xl)
    }
}
```

## Safe Area & Navigation

```swift
// Respeitar Safe Area
VStack {
    // Content
}
.padding(.top, 1)  // Mínimo para ativar safe area
.ignoresSafeArea(.keyboard)  // Permite teclado sobrepor

// Tab bar custom com safe area
ZStack {
    // Main content

    VStack {
        Spacer()
        CustomTabBar()
            .padding(.bottom)  // Respeita safe area inferior
    }
}
.ignoresSafeArea(.keyboard)
```

## Performance Best Practices

### LazyVStack/LazyHStack

```swift
// Para listas longas, sempre usar Lazy
ScrollView {
    LazyVStack(spacing: Spacing.md) {
        ForEach(items) { item in
            ItemCard(item: item)
        }
    }
}

// Evitar
ScrollView {
    VStack {  // ❌ Renderiza tudo de uma vez
        ForEach(items) { item in
            ItemCard(item: item)
        }
    }
}
```

### @State vs @StateObject

```swift
// Use @State para tipos simples
@State private var isExpanded = false
@State private var searchText = ""

// Use @StateObject para ObservableObjects
@StateObject private var viewModel = HomeViewModel()

// Use @ObservedObject quando recebido de um parent
@ObservedObject var viewModel: HomeViewModel
```

### Image Optimization

```swift
// Sempre redimensionar imagens
AsyncImage(url: imageURL) { image in
    image
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 100, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
} placeholder: {
    ShimmerEffect()
        .frame(width: 100, height: 100)
}
```
