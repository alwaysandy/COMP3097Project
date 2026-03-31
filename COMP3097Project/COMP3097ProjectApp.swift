//
//  HackerNewsClientPrototypeApp.swift
//  HackerNewsClientPrototype
//
//  Created by Andy Daurio-Sas on 2026-02-03.
//

import SwiftUI

@main
struct HackerNewsClientPrototypeApp: App {
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
