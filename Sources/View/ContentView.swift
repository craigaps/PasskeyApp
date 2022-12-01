//
// ContentView.swift
//
// Copyright contributors to the PasskeyApp
//

import SwiftUI

struct ContentView: View {
    @AppStorage("token") private var token = String()
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("isRegistered") private var isRegistered: Bool = false
    
    var body: some View {
        VStack {
            if self.isRegistered && !self.isLoggedIn {
                PasskeyLoginView()
            }
            else if !self.isRegistered && self.isLoggedIn {
                RegisterView()
            }
            else if self.token.isEmpty {
                LoginView()
            }
            else {
                PasskeyView()
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
