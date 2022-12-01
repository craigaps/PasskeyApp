//
// Login.swift
//
// Copyright contributors to the PasskeyApp
//

import Foundation
import SwiftUI
import RelyingPartyKit

class Login: ObservableObject {
    private let client = RelyingPartyClient(baseURL: URL(string: "https://\(relyingParty)")!)
    
    @AppStorage("token") var token: String = String()
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("isRegistered") var isRegistered: Bool = false
    
    @Published var username: String = "scott"
    @Published var password: String = String()
    @Published var errorMessage: String = String()
    @Published var navigate: Bool = false
    @Published var isPresentingErrorAlert: Bool = false
    
    @MainActor
    func login() async {
        do {
            let result = try await client.authenticate(username: username, password: password)
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
    
    static func fetchTokenInfo(token: String) -> Token? {
        guard let data = token.data(using: .utf8), let result = try? JSONDecoder().decode(Token.self, from: data) else {
            return nil
        }
        
        return result
    }
}
