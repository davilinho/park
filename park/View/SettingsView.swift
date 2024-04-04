//
// Created by David Martin on 21/2/24.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var locations: [ParkModel]

    @Binding var isShowing: Bool

    var body: some View {
        VStack {
            LazyVGrid(columns: [GridItem(.flexible())]) {
                ScrollView {
                    ForEach(self.locations, id: \.self) { location in
                        HStack {
                            Text("\(location.latitude)")
                            Text("\(location.longitude)")
                            Spacer()
                        }
                    }
                }
            }
            .padding(16)
            Button("Press to dismiss") {
                self.isShowing.toggle()
                self.dismiss()
            }
            Spacer()
        }
        .font(.title)
        .padding()
    }
}
