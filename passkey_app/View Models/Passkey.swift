//
//  Passkey.swift
//  passkey_app
//
//  Created by Craig Pearson on 11/10/2022.
//

import Foundation
import SwiftUI

class Passkey: ObservableObject {
    @AppStorage("token") var token: String = String()
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("isRegistered") var isRegistered: Bool = false
    
    @Published var navigate: Bool = false
    @Published var username: String = String()
    
    init() {
        if let token = Login.fetchTokenInfo(token: token), let idToken = token.idToken, let claims = try? decode(jwtToken: idToken) {
            self.username = claims["name"] as? String ?? "User"
        }
    }
    
    @MainActor
    func logout() {
        self.isLoggedIn = false
        self.navigate = true
    }
    
    @MainActor
    func reset() {
        self.isLoggedIn = false
        self.isRegistered = false
        self.token = ""
        self.navigate = true
    }
}

