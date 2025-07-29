import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import AuthenticationServices

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private let firestore = Firestore.firestore()
    
    init() {
        // Check if user is already authenticated
        if let firebaseUser = auth.currentUser {
            isAuthenticated = true
            loadUserProfile(for: firebaseUser.uid)
        }
        
        // Listen for auth state changes
        auth.addStateDidChangeListener { [weak self] _, user in
            self?.isAuthenticated = user != nil
            if let user = user {
                self?.loadUserProfile(for: user.uid)
            } else {
                self?.currentUser = nil
            }
        }
    }
    
    // MARK: - Email Authentication
    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let user = User(email: email, name: name)
            try await saveUserProfile(user, for: result.user.uid)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await auth.signIn(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
            errorMessage = "Unable to get root view controller"
            isLoading = false
            return
        }
        
        do {
            guard let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) else {
                isLoading = false
                return
            }
            
            let user = result.user
            guard let idToken = user.idToken?.tokenString else {
                errorMessage = "Failed to get ID token"
                isLoading = false
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: user.accessToken.tokenString)
            
            let authResult = try await auth.signIn(with: credential)
            
            // Check if this is a new user
            if authResult.additionalUserInfo?.isNewUser == true {
                let newUser = User(email: user.profile?.email ?? "", 
                                 name: user.profile?.name ?? "")
                try await saveUserProfile(newUser, for: authResult.user.uid)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Apple Sign In
    func signInWithApple(authorization: ASAuthorization) async {
        isLoading = true
        errorMessage = nil
        
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Invalid Apple ID credential"
            isLoading = false
            return
        }
        
        guard let idToken = credential.identityToken,
              let idTokenString = String(data: idToken, encoding: .utf8) else {
            errorMessage = "Failed to get ID token"
            isLoading = false
            return
        }
        
        do {
            var nonce: String?
            if let authorizationCode = credential.authorizationCode,
               let authCode = String(data: authorizationCode, encoding: .utf8) {
                nonce = authCode
            }
            
            let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com",
                                                            idToken: idTokenString,
                                                            rawNonce: nonce)
            
            let authResult = try await auth.signIn(with: firebaseCredential)
            
            // Check if this is a new user
            if authResult.additionalUserInfo?.isNewUser == true {
                let email = credential.email ?? authResult.user.email ?? ""
                let name = credential.fullName?.formatted() ?? "Apple User"
                let newUser = User(email: email, name: name)
                try await saveUserProfile(newUser, for: authResult.user.uid)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - User Management
    func signOut() {
        do {
            try auth.signOut()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateUserProfile(_ user: User) async {
        guard let userID = auth.currentUser?.uid else { return }
        
        do {
            try await saveUserProfile(user, for: userID)
            currentUser = user
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadUserProfile(for userID: String) {
        firestore.collection("users").document(userID).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                if let data = snapshot?.data() {
                    do {
                        let user = try Firestore.Decoder().decode(User.self, from: data)
                        self?.currentUser = user
                    } catch {
                        self?.errorMessage = "Failed to decode user profile"
                    }
                }
            }
        }
    }
    
    private func saveUserProfile(_ user: User, for userID: String) async throws {
        let data = try Firestore.Encoder().encode(user)
        try await firestore.collection("users").document(userID).setData(data)
        currentUser = user
    }
}