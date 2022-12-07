//
// Copyright contributors to the IBM Security Verify Passkey Sample App
//

import Foundation
import SwiftUI
import AuthenticationServices
import RelyingPartyKit

class PasskeyLogin: NSObject, ObservableObject {
    private var authenticationAnchor: ASPresentationAnchor?
    private let client = RelyingPartyClient(baseURL: URL(string: "https://\(relyingParty)")!)
    
    @AppStorage("token") var token: String = String()
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("isRegistered") var isRegistered: Bool = false
    
    @Published var initCompleted: Bool = false
    @Published var errorMessage: String = String()
    @Published var navigate: Bool = false
    @Published var isPresentingErrorAlert: Bool = false
    
    @MainActor
    func passwordless() async {
        var challenge = String()
        
        do {
           challenge = try await fetchAssertionChallenge()
            
            // The challenge needs to be Base64Url encoded, because rawClientDataJSON will do this.  Otherwise your FIDO server won't match the challenges.
            challenge = challenge.base64UrlEncodedStringWithPadding
            print("Assertion challenge: \(challenge)")
        }
        catch let error {
            self.errorMessage = error.localizedDescription
            self.isPresentingErrorAlert = true
            return
        }
        
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingParty)
        let request = provider.createCredentialAssertionRequest(challenge: Data(base64Encoded: challenge)!)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    @MainActor
    func reset() {
        self.isLoggedIn = false
        self.isRegistered = false
        self.token = ""
        self.navigate = true
    }
    
    func fetchAssertionChallenge() async throws -> String {
        let result = try await client.challenge(type: .assertion)
        return result.challenge
    }
    
    func createAssertion(assertion: ASAuthorizationPlatformPublicKeyCredentialAssertion) async throws {
        print(String(decoding: assertion.rawClientDataJSON, as: UTF8.self))
        
        let result = try await client.signin(signature: assertion.signature,
                                             clientDataJSON: assertion.rawClientDataJSON,
                                             authenticatorData: assertion.rawAuthenticatorData,
                                             credentialId: assertion.credentialID,
                                             userId: assertion.userID)
                                                   
        // Encode the token to a string.
        let data = try JSONEncoder().encode(result)
        DispatchQueue.main.async {
            self.token = String(decoding: data, as: UTF8.self)
        }
    }
}

extension PasskeyLogin: ASAuthorizationControllerDelegate {
    @MainActor
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
            Task {
                do {
                    try await createAssertion(assertion: credential)
                    self.navigate = true
                }
                catch let error {
                    print("Assertion Result Response:\n\t\(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.isPresentingErrorAlert = true
                }
            }
        }
    }

    @MainActor
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        guard let authorizationError = error as? ASAuthorizationError else {
            self.errorMessage = error.localizedDescription
            self.isPresentingErrorAlert = true
            return
        }

        if authorizationError.code == .canceled {
            // Either the system doesn't find any credentials and the request ends silently, or the user cancels the request.
            // This is a good time to show a traditional login form, or ask the user to create an account.
            self.errorMessage = "Request canceled."
        }
        else {
            // Another ASAuthorization error.
            // Note: The userInfo dictionary contains useful information.
            self.errorMessage = error.localizedDescription
        }
        
        self.isPresentingErrorAlert = true
    }
}


extension PasskeyLogin: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return authenticationAnchor!
    }
}

