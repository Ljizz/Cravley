import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo and Title
                VStack(spacing: 10) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text("Cravely")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Your smart dining companion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Authentication Form
                VStack(spacing: 15) {
                    if isSignUp {
                        TextField("Full Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        Task {
                            if isSignUp {
                                await authManager.signUp(email: email, password: password, name: name)
                            } else {
                                await authManager.signIn(email: email, password: password)
                            }
                        }
                    }) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isSignUp ? "Sign Up" : "Sign In")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(authManager.isLoading || email.isEmpty || password.isEmpty || (isSignUp && name.isEmpty))
                }
                .padding(.horizontal, 30)
                
                // Social Login
                VStack(spacing: 15) {
                    Text("or continue with")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        // Google Sign In
                        Button(action: {
                            Task {
                                await authManager.signInWithGoogle()
                            }
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                Text("Google")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        
                        // Apple Sign In
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                switch result {
                                case .success(let authorization):
                                    Task {
                                        await authManager.signInWithApple(authorization: authorization)
                                    }
                                case .failure(let error):
                                    print("Apple Sign In failed: \(error)")
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Toggle Sign In/Up
                Button(action: {
                    withAnimation {
                        isSignUp.toggle()
                    }
                }) {
                    HStack {
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                            .foregroundColor(.secondary)
                        Text(isSignUp ? "Sign In" : "Sign Up")
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: .constant(authManager.errorMessage != nil)) {
            Button("OK") {
                authManager.errorMessage = nil
            }
        } message: {
            Text(authManager.errorMessage ?? "")
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
}