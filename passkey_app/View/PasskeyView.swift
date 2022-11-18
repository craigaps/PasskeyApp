//
//  PasskeyView.swift
//  passkey_app
//
//  Created by Craig Pearson on 11/10/2022.
//

import SwiftUI

struct PasskeyView: View {
    @StateObject var model: Passkey = Passkey()
    
    var body: some View {
        VStack {
            Image(systemName: "person.fill")
                .imageScale(.large)
                .foregroundColor(.accentColor)
                .font(.system(size: 32))
            Text("Welcome, \($model.username.wrappedValue)")
                .font(.title2)
                .foregroundColor(.black)
                .padding(2)
            VStack {
                Button(action: {
                    self.model.logout()
                }) {
                    ZStack {
                       Text("Logout")
                        .frame(maxWidth:.infinity)
                    }
                }
                .fullScreenCover(isPresented: $model.navigate) {
                    PasskeyLoginView()
                }
                .padding()
                .foregroundColor(.white)
                .background(.blue)
                .cornerRadius(8)
                
                Button {
                    self.model.reset()
                } label: {
                    Text("Reset")
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .frame(maxWidth:.infinity)
                }
                .fullScreenCover(isPresented: $model.navigate) {
                    ContentView()
                }
                .padding(.top)
            }
            .padding()
        }
        .padding(16)
    }
}

struct PasskeyView_Previews: PreviewProvider {
    static var previews: some View {
        PasskeyView()
    }
}
