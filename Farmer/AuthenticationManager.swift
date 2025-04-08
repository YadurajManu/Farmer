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
        self.isLoading = true
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
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