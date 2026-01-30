import SwiftUI

struct GreyChatView: View {
    @StateObject private var viewModel = GreyChatViewModel()
    
    var body: some View {
        ZStack {
            Color(hex: "0A0A0A").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(Color(hex: "D4A54A"))
                    Text("GREY")
                        .font(.headline)
                        .tracking(2)
                        .foregroundColor(Color(hex: "D4A54A"))
                    Spacer()
                }
                .padding()
                .background(Color(hex: "141414"))
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { msg in
                                ChatBubble(message: msg)
                                    .id(msg.id)
                            }
                            if viewModel.isLoading {
                                HStack {
                                    GreyTypingIndicator()
                                    Spacer()
                                }
                                .padding(.leading)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let last = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Suggestions
                if viewModel.messages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.suggestions, id: \.self) { suggestion in
                                Button(action: {
                                    Task { await viewModel.sendMessage(suggestion) }
                                }) {
                                    Text(suggestion)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(hex: "1C1C1E"))
                                        .cornerRadius(16)
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.3)))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                }
                
                // Input
                HStack {
                    TextField("Pergunte sobre medicina...", text: $viewModel.inputMessage)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color(hex: "1C1C1E"))
                        .cornerRadius(20)
                    
                    Button(action: {
                        Task { await viewModel.sendMessage() }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(viewModel.inputMessage.isEmpty ? .gray : Color(hex: "D4A54A"))
                    }
                    .disabled(viewModel.inputMessage.isEmpty)
                }
                .padding()
                .background(Color(hex: "141414"))
            }
        }
    }
}

struct ChatBubble: View {
    let message: GreyChatViewModel.ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isUser {
                Spacer()
                Text(message.text)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color(hex: "1C1C1E"))
                    .cornerRadius(16, corners: [.topLeft, .topRight, .bottomLeft])
            } else {
                // Grey Avatar
                Image(systemName: "brain.head.profile")
                    .foregroundColor(Color(hex: "D4A54A"))
                    .frame(width: 32, height: 32)
                    .background(Color.black)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(hex: "D4A54A"), lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 10) {
                    // Render "Markdown" (Text with manual parsing if needed, or simple Text for MVP)
                    // For MVP Phase 3: Text supports basic markdown in iOS 16+
                    Text(LocalizedStringKey(message.text))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color(hex: "141414"))
                        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    
                    // Flashcard Suggestion
                    if let fc = message.flashcard {
                        FlashcardSuggestionView(front: fc.front, back: fc.back)
                    }
                }
                Spacer()
            }
        }
    }
}

struct FlashcardSuggestionView: View {
    let front: String
    let back: String
    @State private var isSaved = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Color(hex: "D4A54A"))
                Text("Flashcard Sugerido")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "D4A54A"))
                Spacer()
            }
            
            Text(front)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.vertical, 2)
            
            Divider().background(Color.gray)
            
            Text(back)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.vertical, 2)
            
            Button(action: {
                // Here we would call API to save card
                isSaved = true
            }) {
                HStack {
                    Text(isSaved ? "Salvo" : "Adicionar ao Deck")
                    if isSaved { Image(systemName: "checkmark") }
                }
                .font(.caption2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSaved ? Color.gray : Color(hex: "D4A54A"))
                .foregroundColor(isSaved ? .white : .black)
                .cornerRadius(8)
            }
            .disabled(isSaved)
        }
        .padding(12)
        .background(Color(hex: "000000"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "D4A54A").opacity(0.5), lineWidth: 1))
    }
}

struct GreyTypingIndicator: View {
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color(hex: "D4A54A"))
                    .frame(width: 8, height: 8)
                    .scaleEffect(scale)
                    .animation(Animation.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.2), value: scale)
            }
        }
        .onAppear { scale = 1.0 }
    }
}
