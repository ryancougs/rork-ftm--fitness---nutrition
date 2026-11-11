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
                if mode == .signup {
                    legalLine
                }
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
            ForgotPasswordSheet(prefilledEmail: email)
                .presentationDetents([.large])
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
                Text(AppInfo.name)
                    .font(.title.weight(.bold))
                    .foregroundStyle(TF.blue)
                    .multilineTextAlignment(.center)
                Text("Training, nutrition and community, built for trans masculine lifters.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
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
                .autocorrectionDisabled()
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
            fieldLabel("Password")
            HStack(spacing: 8) {
                textField("At least 6 characters", text: $password, field: .password, keyboard: .default, secure: !showPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(mode == .signup ? UITextContentType.newPassword : UITextContentType.password)
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

    /// Apple asks apps with a community to get agreement to the terms
    /// (including the no-abuse rules) before an account is created.
    private var legalLine: some View {
        VStack(spacing: 4) {
            Text("By creating an account you agree to our")
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Link("Terms of Use", destination: AppInfo.termsURL)
                Text("and").foregroundStyle(.secondary)
                Link("Privacy Policy", destination: AppInfo.privacyURL)
            }
            .tint(TF.blue)
        }
        .font(.caption)
        .multilineTextAlignment(.center)
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
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
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

/// Reset a forgotten password without leaving the app: ask for the email,
/// then enter the code from the reset email and choose a new password.
struct ForgotPasswordSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var prefilledEmail: String = ""

    private enum Step { case email, code }

    @State private var step: Step = .email
    @State private var email: String = ""
    @State private var code: String = ""
    @State private var newPassword: String = ""
    @State private var codeVerified: Bool = false
    @State private var isWorking: Bool = false
    @State private var error: String? = nil
    @State private var notice: String? = nil

    private var cleanEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var cleanCode: String {
        code.filter { $0.isNumber }
    }

    private var emailIsValid: Bool {
        cleanEmail.contains("@") && cleanEmail.contains(".")
    }

    private var canFinish: Bool {
        cleanCode.count >= 6 && newPassword.count >= 6
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if !AppInfo.selfServePasswordReset {
                        contactStep
                    } else {
                        switch step {
                        case .email: emailStep
                        case .code: codeStep
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(TF.bg.ignoresSafeArea())
            .dismissKeyboardOnTap()
            .keyboardDoneBar()
            .navigationTitle("Reset password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(TF.blue)
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if email.isEmpty { email = prefilledEmail }
        }
    }

    /// Shown while self-serve reset is off: a person resets the password by hand.
    private var contactStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(TF.blue)
            Text("We'll reset it for you")
                .font(.title3.weight(.bold))
                .foregroundStyle(TF.text)
            Text("Email us from the address you signed up with and we'll send you a temporary password, usually within a day.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let url = URL(string: "mailto:\(AppInfo.supportEmail)?subject=FTM%20password%20reset") {
                Link(destination: url) {
                    Label("Email \(AppInfo.supportEmail)", systemImage: "paperplane.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.blue))
                        .foregroundStyle(.white)
                }
            }
            Button("Copy email address") {
                UIPasteboard.general.string = AppInfo.supportEmail
                notice = "Copied."
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(TF.blue)
            .buttonStyle(.plain)
            messages
        }
    }

    private var emailStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(TF.blue)
            Text("Enter the email you signed up with and we'll send you a reset code.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            TextField("you@example.com", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.username)
                .submitLabel(.done)
                .onSubmit { dismissKeyboard() }
                .foregroundStyle(TF.text)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
            messages
            TFButton(title: "Send reset code", systemImage: "paperplane.fill", style: .primary,
                     isLoading: isWorking, disabled: !emailIsValid, action: sendCode)
        }
    }

    private var codeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(TF.blue)
            Text("Check your email")
                .font(.title3.weight(.bold))
                .foregroundStyle(TF.text)
            Text("If an account exists for \(cleanEmail), a reset code is on its way. It can take a few minutes, and it may land in spam.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 6) {
                Text("Code from the email")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TF.text)
                TextField("123456", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .foregroundStyle(TF.text)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
                    .disabled(codeVerified)
                    .opacity(codeVerified ? 0.6 : 1)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("New password")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TF.text)
                SecureField("At least 6 characters", text: $newPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.newPassword)
                    .foregroundStyle(TF.text)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
            }
            messages
            TFButton(title: "Save new password", systemImage: "checkmark", style: .primary,
                     isLoading: isWorking, disabled: !canFinish, action: finish)
            if !codeVerified {
                Button("Send a new code") { sendCode() }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(TF.blue)
                    .buttonStyle(.plain)
                    .disabled(isWorking)
            }
        }
    }

    @ViewBuilder
    private var messages: some View {
        if let error {
            Text(error)
                .font(.footnote.weight(.medium))
                .foregroundStyle(TF.danger)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        if let notice {
            Text(notice)
                .font(.footnote.weight(.medium))
                .foregroundStyle(TF.blue)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func sendCode() {
        error = nil
        notice = nil
        isWorking = true
        let address = cleanEmail
        let isResend = step == .code
        Task { @MainActor in
            defer { isWorking = false }
            do {
                try await SupabaseService.shared.sendPasswordReset(email: address)
                if isResend { notice = "New code sent. Use the newest email." }
                withAnimation { step = .code }
            } catch let err {
                error = SupabaseService.friendlyMessage(for: err)
            }
        }
    }

    private func finish() {
        error = nil
        notice = nil
        isWorking = true
        dismissKeyboard()
        let address = cleanEmail
        let token = cleanCode
        let password = newPassword
        Task { @MainActor in
            defer { isWorking = false }
            do {
                // The code only works once. If saving the password fails
                // after that (too short, same as the old one), the retry
                // skips straight to saving.
                if !codeVerified {
                    try await SupabaseService.shared.verifyPasswordResetCode(email: address, code: token)
                    codeVerified = true
                }
                let result = try await SupabaseService.shared.setNewPassword(password)
                dismiss()
                await app.finishSignIn(email: result.email ?? address)
            } catch let err {
                error = SupabaseService.friendlyMessage(for: err)
            }
        }
    }
}

#Preview {
    AuthView().environment(AppModel())
}
