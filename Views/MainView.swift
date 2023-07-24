//
//  MainView.swift
//  Aria2
//
//  Created by Lsong on 7/26/23.
//

import SwiftUI

struct MainView: View {
    var rpc = Aria2API()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            List {
                Section() {
                    NavigationLink(destination: TaskListView(rpc: rpc)) {
                        Text("Downloading")
                    }
                    NavigationLink(destination: TaskListView(rpc: rpc)) {
                        Text("Waitting")
                    }
                    NavigationLink(destination: TaskListView(rpc: rpc)) {
                        Text("Stopped")
                    }
                }
                
            }
            .navigationBarItems(trailing: Button(action: {
                showingSettings = true
            }){
                Image(systemName: "gear")
            })
            .navigationTitle("Aria2")
            .sheet(isPresented: $showingSettings) {
                SettingsView(isPresented: $showingSettings)
            }
            
            Text("Select an item")
                .font(.largeTitle)
                .foregroundColor(.gray)
        }
       
    }
}
