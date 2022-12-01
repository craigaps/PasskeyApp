//
// Register.swift
//
// Copyright contributors to the PasskeyApp
//

import Foundation
import SwiftUI
import AuthenticationServices
import RelyingPartyKit

class Register: NSObject, ObservableObject {
    private var authenticationAnchor: ASPresentationAnchor?
    private let client = RelyingPartyClient(baseURL: URL(string: "https://\(relyingParty)")!)
    
    @AppStorage("token") var token: String = String()
    @AppStorage("isRegistered") var isRegistered: Bool = false
    
    @Published var nickname: String = String()
    @Published var errorMessage: String = String()
    @Published var navigate: Bool = false
    @Published var isPresentingErrorAlert: Bool = false
    
    @MainActor
    func register() async {
       var challenge = String()
        
        do {
            challenge = try await fetchAttestationChallenge()
            // The challenge needs to be Base64Url encoded, because rawClientDataJSON will do this.  Otherwise your FIDO server won't match the challenges.
            challenge = challenge.base64UrlEncodedStringWithPadding
            print("Attestation challenge: \(challenge)")
        }
        catch let error {
            self.errorMessage = error.localizedDescription
            self.isPresentingErrorAlert = true
            return
        }
        
        // Get the UserId from the id_token
        var userId = UUID().uuidString
        var username: String = "User"
        
        if let token = Login.fetchTokenInfo(token: token), let idToken = token.idToken, let claims = try? decode(jwtToken: idToken) {
            userId = claims["sub"] as! String
            username = claims["name"] as? String ?? "User"
        }
        
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingParty)
        let request = provider.createCredentialRegistrationRequest(challenge: Data(base64Encoded: challenge)!, name: username, userID: Data(userId.utf8))
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func fetchAttestationChallenge() async throws -> String {
        guard let token = Login.fetchTokenInfo(token: token) else {
            throw "Invalid access token."
        }
        
        let result = try await client.challenge(type: .attestation, displayName: self.nickname, token: token)
        return result.challenge
    }

    
    func createCredential(registration: ASAuthorizationPlatformPublicKeyCredentialRegistration) async throws {
        guard let token = Login.fetchTokenInfo(token: token) else {
            throw "Invalid access token."
        }
        
        print(String(decoding: registration.rawClientDataJSON, as: UTF8.self))
        
        try await client.register(nickname: self.nickname,
                                               clientDataJSON: registration.rawClientDataJSON,
                                               attestationObject: registration.rawAttestationObject!,
                                               credentialId: registration.credentialID,
                                               token: token)
    }
}

extension Register: ASAuthorizationControllerDelegate {
    @MainActor
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            // After the server verifies the registration and creates the user account, sign in the user with the new account.
            Task {
                do {
                    try await createCredential(registration: credential)
                     
                    self.isRegistered = true
                    self.navigate = true
                }
                catch let error {
                    print("Attestation Result Response:\n\t\(error.localizedDescription)")
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

extension Register: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return authenticationAnchor!
    }
}
