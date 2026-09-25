//
//  AuthView.swift
//  FTMFitnessNutrition
//

import SwiftUI

/// Email + password sign up / log in screen.
struct AuthView: View {
    @Environment(AppModel.self) private var app

    @State private var mode: Mode = .signup
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var error: String? = nil
    @State private var info: String? = nil
    @State private var showingForgotPassword = false
    @State private var isLoading: Bool = false
    @FocusState private var focusedField: Field?

    private enum Mode { case signup, login }
    private enum Field: Hashable { case name, email, password }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                formCard
                if let error {
                    Text(error)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(TF.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 18)
                }
                if let info {
                    Text(info)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(TF.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 18)
                }
                submitButton
                if mode == .login {
                    Button {
                        showingForgotPassword = true
                    } label: {
                        Text("Forgot your password?")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(TF.blue)
                    }
                    .buttonStyle(.plain)
                }
                modeToggle
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
        }
        .scrollDismissesKeyboard(.immediately)
        .dismissKeyboardOnTap()
        .background(TF.bg.ignoresSafeArea())
        .animation(.easeOut(duration: 0.2), value: mode)
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 108, height: 108)
            VStack(spacing: 4) {
                Text("FTM Team")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(TF.blue)
                Text("A community based fitness app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text("Free at launch")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TF.blue)
            }
        }
        .padding(.top, 8)
    }

    private var formCard: some View {
        VStack(spacing: 14) {
            if mode == .signup {
                fieldLabel("Your name")
                textField("Jordan", text: $name, field: .name)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .email }
            }
            fieldLabel("Email")
            textField("you@example.com", text: $email, field: .email, keyboard: .emailAddress)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
            fieldLabel("Password")
            HStack(spacing: 8) {
                textField("At least 6 characters", text: $password, field: .password, keyboard: .default, secure: !showPassword)
                    .submitLabel(.go)
                    .onSubmit(submit)
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: TF.cornerL)
                .fill(TF.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TF.cornerL)
                .strokeBorder(TF.border, lineWidth: 1)
        )
    }

    private var submitButton: some View {
        TFButton(
            title: mode == .signup ? "Create account" : "Log in",
            systemImage: mode == .signup ? "person.badge.plus" : "arrow.right.circle.fill",
            style: .primary,
            isLoading: isLoading,
            disabled: !isValid,
            action: submit
        )
    }

    private var modeToggle: some View {
        HStack(spacing: 6) {
            Text(mode == .signup ? "Already have an account?" : "New here?")
                .foregroundStyle(.secondary)
            Button(mode == .signup ? "Log in" : "Sign up") {
                error = nil
                info = nil
                mode = (mode == .signup) ? .login : .signup
            }
            .fontWeight(.semibold)
            .foregroundStyle(TF.blue)
        }
        .font(.subheadline)
    }

    private var isValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let pwValid = password.count >= 6
        if mode == .signup {
            return !name.trimmingCharacters(in: .whitespaces).isEmpty && emailValid && pwValid
        }
        return emailValid && !password.isEmpty
    }

    private func submit() {
        error = nil
        info = nil
        isLoading = true
        focusedField = nil
        let email = email.trimmingCharacters(in: .whitespaces)
        let name = name.trimmingCharacters(in: .whitespaces)
        Task { @MainActor in
            defer { isLoading = false }
            do {
                switch mode {
                case .signup:
                    try await app.signUp(name: name, email: email, password: password)
                case .login:
                    try await app.logIn(email: email, password: password)
                }
            } catch let err {
                if let authError = err as? SupabaseService.AuthError,
                   case .emailConfirmationRequired = authError {
                    info = authError.localizedDescription
                } else {
                    error = SupabaseService.friendlyMessage(for: err)
                }
            }
        }
    }

    @ViewBuilder
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(TF.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func textField(_ placeholder: String, text: Binding<String>, field: Field, keyboard: UIKeyboardType = .default, secure: Bool = false) -> some View {
        Group {
            if secure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: TF.cornerS)
                .fill(TF.input)
        )
        .foregroundStyle(TF.text)
        .focused($focusedField, equals: field)
    }
}

// MARK: - Forgot password sheet

struct ForgotPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var isSending: Bool = false
    @State private var sent: Bool = false
    @State private var error: String? = nil

    private var isValid: Bool {
        email.contains("@") && email.contains(".")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if sent {
                    sentView
                } else {
                    formView
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(TF.bg.ignoresSafeArea())
            .dismissKeyboardOnTap()
            .navigationTitle("Reset password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TF.blue)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var formView: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(TF.blue)
            Text("Enter the email you signed up with and we'll send you a reset link.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            TextField("you@example.com", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .submitLabel(.done)
                .onSubmit { dismissKeyboard() }
                .foregroundStyle(TF.text)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
            if let error {
                Text(error)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(TF.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            TFButton(title: "Send reset link", systemImage: "paperplane.fill", style: .primary,
                     isLoading: isSending, disabled: !isValid, action: send)
        }
    }

    private var sentView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(TF.blue)
            Text("Check your email")
                .font(.title3.weight(.bold))
                .foregroundStyle(TF.text)
            Text("If an account exists for that email, a reset link is on its way. It might take a few minutes — check spam if it doesn't show up.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func send() {
        error = nil
        isSending = true
        let email = email.trimmingCharacters(in: .whitespaces)
        Task { @MainActor in
            defer { isSending = false }
            do {
                try await SupabaseService.shared.sendPasswordReset(email: email)
                sent = true
            } catch let err {
                error = SupabaseService.friendlyMessage(for: err)
            }
        }
    }
}

#Preview {
    AuthView().environment(AppModel())
}
