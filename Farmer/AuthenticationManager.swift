import Foundation
import Firebase
import FirebaseAuth
import SwiftUI

// Authentication states
enum AuthState {
    case signedIn
    case signedOut
    case loading
}

// User registration data model
struct RegistrationDetails {
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var fullName: String = ""
}

// Login data model
struct LoginDetails {
    var email: String = ""
    var password: String = ""
}

// Authentication error messages
enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case passwordMismatch
    case emptyField
    case other(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password should be at least 6 characters"
        case .passwordMismatch:
            return "Passwords do not match"
        case .emptyField:
            return "Please fill in all fields"
        case .other(let message):
            return message
        }
    }
}

// Authentication Manager - Handles all Firebase Auth functions
class AuthenticationManager: ObservableObject {
    @Published var user: User?
    @Published var authState: AuthState = .loading
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    init() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            DispatchQueue.main.async {
                self?.user = user
                self?.authState = user != nil ? .signedIn : .signedOut
            }
        }
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    
    // MARK: - Validation Methods
    
    func validateRegistration(_ details: RegistrationDetails) -> Result<Void, AuthError> {
        // Check for empty fields
        if details.email.isEmpty || details.password.isEmpty || details.confirmPassword.isEmpty || details.fullName.isEmpty {
            return .failure(.emptyField)
        }
        
        // Check for valid email format
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        if !emailPred.evaluate(with: details.email) {
            return .failure(.invalidEmail)
        }
        
        // Check for password strength
        if details.password.count < 6 {
            return .failure(.weakPassword)
        }
        
        // Check if passwords match
        if details.password != details.confirmPassword {
            return .failure(.passwordMismatch)
        }
        
        return .success(())
    }
    
    func validateLogin(_ details: LoginDetails) -> Result<Void, AuthError> {
        // Check for empty fields
        if details.email.isEmpty || details.password.isEmpty {
            return .failure(.emptyField)
        }
        
        // Check for valid email format
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        if !emailPred.evaluate(with: details.email) {
            return .failure(.invalidEmail)
        }
        
        return .success(())
    }
    
    // MARK: - Authentication Methods
    
    func registerUser(with details: RegistrationDetails, completion: @escaping (Result<User, Error>) -> Void) {
        // First validate registration details
        let validationResult = validateRegistration(details)
        
        switch validationResult {
        case .failure(let error):
            completion(.failure(error))
            return
            
        case .success:
            self.isLoading = true
            self.errorMessage = nil
            
            // Create user in Firebase
            Auth.auth().createUser(withEmail: details.email, password: details.password) { [weak self] authResult, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        completion(.failure(error))
                        return
                    }
                    
                    if let user = authResult?.user {
                        // Update display name
                        let changeRequest = user.createProfileChangeRequest()
                        changeRequest.displayName = details.fullName
                        changeRequest.commitChanges { error in
                            if let error = error {
                                print("Error updating display name: \(error.localizedDescription)")
                            }
                        }
                        
                        self?.user = user
                        self?.authState = .signedIn
                        completion(.success(user))
                    }
                }
            }
        }
    }
    
    func loginUser(with details: LoginDetails, completion: @escaping (Result<User, Error>) -> Void) {
        // First validate login details
        let validationResult = validateLogin(details)
        
        switch validationResult {
        case .failure(let error):
            completion(.failure(error))
            return
            
        case .success:
            self.isLoading = true
            self.errorMessage = nil
            
            // Sign in with Firebase
            Auth.auth().signIn(withEmail: details.email, password: details.password) { [weak self] authResult, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        completion(.failure(error))
                        return
                    }
                    
                    if let user = authResult?.user {
                        self?.user = user
                        self?.authState = .signedIn
                        completion(.success(user))
                    }
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.authState = .signedOut
        } catch let error {
            self.errorMessage = error.localizedDescription
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    func resetPassword(for email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Check if email is empty
        if email.isEmpty {
            self.errorMessage = "Please enter your email address"
            completion(.failure(AuthError.emptyField))
            return
        }
        
        // Validate email format
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        if !emailPred.evaluate(with: email) {
            self.errorMessage = "Please enter a valid email address"
            completion(.failure(AuthError.invalidEmail))
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    if (error as NSError).code == AuthErrorCode.userNotFound.rawValue {
                        // Don't reveal if the user exists for security reasons
                        self?.errorMessage = "If this email is registered, you will receive a password reset link"
                        completion(.success(()))
                    } else {
                        self?.errorMessage = error.localizedDescription
                        completion(.failure(error))
                    }
                    return
                }
                
                completion(.success(()))
            }
        }
    }
    
    // MARK: - User Profile Methods
    
    func updateProfile(displayName: String? = nil, photoURL: URL? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is signed in"])))
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        let changeRequest = user.createProfileChangeRequest()
        
        if let displayName = displayName {
            changeRequest.displayName = displayName
        }
        
        if let photoURL = photoURL {
            changeRequest.photoURL = photoURL
        }
        
        changeRequest.commitChanges { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                // Update the local user object
                self?.user = Auth.auth().currentUser
                completion(.success(()))
            }
        }
    }
    
    func changeEmail(to newEmail: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is signed in"])))
            return
        }
        
        // Validate email format
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        if !emailPred.evaluate(with: newEmail) {
            self.errorMessage = "Please enter a valid email address"
            completion(.failure(AuthError.invalidEmail))
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        user.updateEmail(to: newEmail) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                // Update the local user object
                self?.user = Auth.auth().currentUser
                completion(.success(()))
            }
        }
    }
    
    func changePassword(from currentPassword: String, to newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is signed in"])))
            return
        }
        
        // Check for password strength
        if newPassword.count < 6 {
            self.errorMessage = "Password should be at least 6 characters"
            completion(.failure(AuthError.weakPassword))
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        // First, reauthenticate the user
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { [weak self] _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Current password is incorrect"
                    completion(.failure(error))
                }
                return
            }
            
            // Now change the password
            user.updatePassword(to: newPassword) { error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        completion(.failure(error))
                        return
                    }
                    
                    completion(.success(()))
                }
            }
        }
    }
    
    func deleteAccount(password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is signed in"])))
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        // First, reauthenticate the user
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        
        user.reauthenticate(with: credential) { [weak self] _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Password is incorrect"
                    completion(.failure(error))
                }
                return
            }
            
            // Now delete the account
            user.delete { error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        completion(.failure(error))
                        return
                    }
                    
                    // User will be signed out automatically by Firebase
                    // AuthStateDidChangeListener will handle updating the UI
                    completion(.success(()))
                }
            }
        }
    }
    
    func checkAuthState() {
        // This method can be called to refresh the auth state
        self.user = Auth.auth().currentUser
        self.authState = user != nil ? .signedIn : .signedOut
    }
} 