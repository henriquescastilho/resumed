//
//  ResumedTextField.swift
//  Resumed
//
//  Design System - Text Input Components
//

import SwiftUI

// MARK: - Resumed Text Field

struct ResumedTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String?
    let isSecure: Bool
    let keyboardType: UIKeyboardType

    @FocusState private var isFocused: Bool

    init(
        placeholder: String,
        text: Binding<String>,
        icon: String? = nil,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
        self.keyboardType = keyboardType
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: IconSize.md))
                    .foregroundColor(isFocused ? .resumed.gold : .resumed.gray)
            }

            if isSecure {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .keyboardType(keyboardType)
            }
        }
        .font(.resumed.body)
        .foregroundColor(.resumed.white)
        .padding(Spacing.md)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(isFocused ? Color.resumed.gold : Color.resumed.border, lineWidth: 1)
        )
    }
}

// MARK: - Search Field

struct SearchField: View {
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    init(text: Binding<String>, placeholder: String = "Buscar...", onSubmit: @escaping () -> Void = {}) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: IconSize.md))
                .foregroundColor(.resumed.gray)

            TextField(placeholder, text: $text)
                .font(.resumed.body)
                .foregroundColor(.resumed.white)
                .focused($isFocused)
                .onSubmit(onSubmit)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: IconSize.md))
                        .foregroundColor(.resumed.gray)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.round)
    }
}

// MARK: - Chat Input Bar

struct ChatInputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    let isLoading: Bool
    var isDisabled: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.sm) {
            TextField("Digite sua mensagem...", text: $text, axis: .vertical)
                .font(.resumed.body)
                .foregroundColor(.resumed.white)
                .focused($isFocused)
                .lineLimit(1...5)
                .onSubmit {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend()
                    }
                }
                .disabled(isDisabled)

            Button(action: onSend) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .resumed.black))
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(text.isEmpty ? .resumed.gray : .resumed.gold)
                }
            }
            .disabled(isDisabled || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.resumed.blackSecondary)
        .opacity(isDisabled ? 0.6 : 1)
    }
}

// MARK: - Text Area

struct ResumedTextArea: View {
    let placeholder: String
    @Binding var text: String
    let minHeight: CGFloat

    @FocusState private var isFocused: Bool

    init(placeholder: String, text: Binding<String>, minHeight: CGFloat = 100) {
        self.placeholder = placeholder
        self._text = text
        self.minHeight = minHeight
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.resumed.body)
                    .foregroundColor(.resumed.gray)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
            }

            TextEditor(text: $text)
                .font(.resumed.body)
                .foregroundColor(.resumed.white)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
        }
        .frame(minHeight: minHeight)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(isFocused ? Color.resumed.gold : Color.resumed.border, lineWidth: 1)
        )
    }
}
