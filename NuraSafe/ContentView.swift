 // ContentView.swift

import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(iOS)
        NuraSafeLaunchContainer()
        #else
        Text("NuraSafe requires iOS.")
            .font(.title)
            .padding()
        #endif
    }
}

#Preview {
    ContentView()
}
