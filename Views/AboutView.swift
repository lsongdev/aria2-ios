//
//  AboutView.swift
//  Aria2
//
//  Created by Lsong on 7/26/23.
//

import SwiftUI

struct TextPairView: View {
    let leading: String
    let trailing: String
    
    var body: some View {
        HStack {
            Text(leading)
            Spacer()
            Text(trailing).foregroundColor(.secondary)
        }
    }
}

struct AboutView: View {
    var body: some View {
        Text("Aria2").font(.largeTitle)
        List {
            TextPairView(leading: "Version", trailing: "1.0.0")
            TextPairView(leading: "Author", trailing: "@song940")
        }
    }
}
