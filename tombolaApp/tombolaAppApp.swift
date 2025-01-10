//
//  tombolaAppApp.swift
//  tombolaApp
// 
//  Created by Charlie Culbert on 1/9/25.
//

import SwiftUI

@main
struct tombolaAppApp: App {
    var body: some Scene {
        WindowGroup {
            TombolaView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 600)
    }
}

#Preview {
    TombolaView()
        .frame(width: 800, height: 600)
}
