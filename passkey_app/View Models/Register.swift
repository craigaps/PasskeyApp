//
//  Register.swift
//  passkey_app
//
//  Created by Craig Pearson on 11/10/2022.
//

import Foundation
import SwiftUI
import Core
import AuthenticationServices
import Authentication

class Register: NSObject, ObservableObject {
    private var authenticationAnchor: ASPresentationAnchor?
    private let domain = "milano.dev.verify.ibmcloudsecurity.com"
    private let userId = "604000470T"
    private let attestationOptionsUri = URL(string: "\(Login.baseUrl)/v2.0/factors/fido2/relyingparties/\(Register.relyingPartyId)/attestation/options")!
    private let attestationResultUri = URL(string: "\(Login.baseUrl)/v2.0/factors/fido2/relyingparties/\(Register.relyingPartyId)/attestation/result")!
    
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
            challenge = challenge.base64UrlEncodedStringWithPadding // The challenge needs to be Base64Url encoded, because rawClientDataJSON will do this.  Otherwise your FIDO server won't match the challenges.
            print("Challenge:\n\t\(challenge)")
        }
        catch let error {
            self.errorMessage = error.localizedDescription
            self.isPresentingErrorAlert = true
            return
        }
        
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
        let request = provider.createCredentialRegistrationRequest(challenge: Data(base64Encoded: challenge)!, name: nickname, userID: Data(self.userId.utf8))
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func fetchAttestationChallenge() async throws -> String {
        guard let token = Login.fetchTokenInfo(token: token) else {
            throw "Invalid access token."
        }
        
        let json = """
        {
            "displayName": "\(self.nickname)",
            "userId": "\(self.userId)"
        }
        """
        print("Attestation Options Request:\n\t\(json)")
        let body = Data(json.utf8)
        
        // Construct the request and parsing method.
        let resource = HTTPResource<String>(.post, url: self.attestationOptionsUri, accept: .json, contentType: .json, body: body, headers: ["Authorization": token.authorizationHeader]) { data, response in
            guard let data = data else {
                return Result.failure("Unable to fetch attestation options.")
            }
            
            print("Attestation Options Response:\n\t\(String(data: data, encoding: .utf8)!)")
            
            // Parse out the userId and challenge from the attestation options.
            do {
                let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let challenge = dictionary!["challenge"] as? String {
                    return Result.success(challenge)
                }
            }
            catch let error {
                return Result.failure(error)
            }
            
            return Result.failure("No challenge found.")
        }
        
        return try await URLSession.shared.dataTask(for: resource)
    }
    
    func createCredential(registration: ASAuthorizationPlatformPublicKeyCredentialRegistration) async throws {
        guard let token = Login.fetchTokenInfo(token: token) else {
            throw "Invalid access token."
        }
        
        // Create the attestation result request data.
        let json = """
        {
            "type": "public-key",
            "enabled": "true",
            "id": "\(registration.credentialID.base64UrlEncodedString(options: [.safeUrlCharacters]))",
            "rawId": "\(registration.credentialID.base64UrlEncodedString(options: [.safeUrlCharacters]))",
            "nickname": "\(self.nickname)",
            "response": {
                "clientDataJSON": "\(registration.rawClientDataJSON.base64UrlEncodedString())",
                "attestationObject": "\(registration.rawAttestationObject!.base64UrlEncodedString(options: [.safeUrlCharacters]))"
            }
        }
        """
        
        print("Attestation Result Request (payload):\n\t\(json)")
        let body = Data(json.utf8)
        
        // Create the request to the FIDO service to register the credential
        let resource = HTTPResource<Void>(.post, url: self.attestationResultUri, accept: .json, contentType: .json, body: body, headers: ["Authorization": token.authorizationHeader]) { data, response in
            if let httpRepsonse = response as? HTTPURLResponse, httpRepsonse.statusCode > 200 {
                return Result.failure("Unable to complete registration.")
            }
            
            let json = try? JSONSerialization.jsonObject(with: data!, options: [])
            let jsonData = try? JSONSerialization.data(withJSONObject: json!, options: [.prettyPrinted])
            let prettyPrintedString = String(data: jsonData!, encoding: .utf8)

            print("Attestation Result Request:\n\t\(prettyPrintedString!)")
            
            return Result.success(())
        }
        
        try await URLSession.shared.dataTask(for: resource)
    }
    
    static let relyingPartyId = "4d100a38-4daf-4013-bb68-4b2137b2ca03"
}

extension Register: ASAuthorizationControllerDelegate {
    @MainActor
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            // Verify the attestationObject and clientDataJSON with your service.
            // The attestationObject contains the user's new public key to store and use for subsequent sign-ins.
            // let attestationObject = credentialRegistration.rawAttestationObject
            // let clientDataJSON = credentialRegistration.rawClientDataJSON
            
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
