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
    
    @MainActor
    func logout() {
        self.isLoggedIn = false
        self.navigate = true
    }
    
    @MainActor
    func reset() {
        self.isLoggedIn = false
        self.isRegistered = false
        self.token = String()
        self.navigate = true
    }
}

