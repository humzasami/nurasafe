// NuraSafeApp.swift

import SwiftUI

@main
struct NuraSafeApp: App {

    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            NuraSafeLaunchContainer()
            #else
            Text("NuraSafe requires iOS.")
                .font(.title)
                .padding()
            #endif
        }
    }
}
