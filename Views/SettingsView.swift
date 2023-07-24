//
//  SettingsView.swift
//  Aria2
//
//  Created by Lsong on 7/26/23.
//

import SwiftUI

let serverAddressKey = "serverAddress"
let tokenKey = "token"

struct SettingsView: View {
    @Binding var isPresented: Bool
    @AppStorage(serverAddressKey) var serverAddress = "http://localhost:6800/jsonrpc"
    @AppStorage(tokenKey) var token = "xxxxxxxxxx"

    var body: some View {
        NavigationView {
            Form{
                Section("Server information"){
                    TextField("Server Address", text: $serverAddress)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    TextField("Token", text: $token)
                        .autocapitalization(.none)
                    
                }
                Section(){
                    NavigationLink(destination: AboutView()) {
                        Text("About")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(
                trailing: Button("Done") {
                    isPresented = false
                }
            )
        }
    }
}
