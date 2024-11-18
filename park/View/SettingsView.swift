//
// Created by David Martin on 21/2/24.
//

import SwiftUI
import SwiftData
import vegaDesignSystem

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
                        ParkModelView(model: location)
                    }
                }
            }
            .padding(Dimensions.M)
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

struct ParkModelView: View {
    var model: ParkModel

    var body: some View {
        VStack(alignment: .leading) {
            Text(self.toStringDate(model.timestamp))
            HStack {
                Text("\(model.latitude)")
                Text("\(model.longitude)")
                Spacer()
            }
        }
    }

    func toStringDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return dateFormatter.string(from: date)
    }
}
