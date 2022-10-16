//
//  Login.swift
//  passkey_app
//
//  Created by Craig Pearson on 11/10/2022.
//

import Foundation
import SwiftUI
import Authentication

class Login: ObservableObject {
    private let clientId = "0637679e-e3a0-4320-921f-798520481fa7"
    private let tokenUri = URL(string: "\(Login.baseUrl)/v1.0/endpoint/default/token")!
    
    @AppStorage("token") var token: String = String()
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("isRegistered") var isRegistered: Bool = false
    
    @Published var username: String = "craigaps@au1.ibm.com"
    @Published var password: String = String()
    @Published var errorMessage: String = String()
    @Published var navigate: Bool = false
    @Published var isPresentingErrorAlert: Bool = false
    
    @MainActor
    func login() async {
        let provider = OAuthProvider(clientId: clientId)
        
        do {
            let result = try await provider.authorize(issuer: tokenUri, username: username, password: password)
            let data = try JSONEncoder().encode(result)
            
            self.token = String(data: data, encoding: .utf8)!
            self.isLoggedIn = true
            print("Token Response:\n\t\(token)")
            self.navigate.toggle()
        }
        catch let error {
            self.errorMessage = error.localizedDescription
            self.isPresentingErrorAlert.toggle()
        }
    }
    
    static func fetchTokenInfo(token: String) -> TokenInfo? {
        guard let data = token.data(using: .utf8), let result = try? JSONDecoder().decode(TokenInfo.self, from: data) else {
            return nil
        }
        
        return result
    }
    
    static let baseUrl = "https://milano.dev.verify.ibmcloudsecurity.com"
}

extension String: Error {}
