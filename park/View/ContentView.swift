//
// Created by David Martin on 13/2/24.
//

import MapKit
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

//    @AppStorage("isParkSelected") var isParkSelected = false

//    @StateObject var locationManager = LocationManager()
    @EnvironmentObject var locationManager: LocationManager
    @Query private var locations: [ParkModel]

    @StateObject private var bluetoothManager = BluetoothManager()

    @State private var route: MKRoute?
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var travelTime: String?
    @State private var selectedPosition: CLLocationCoordinate2D = .init()
    @State private var isParkSelected: Bool = false
    @State private var isParkSelectedDotAnimation: Bool = false
    @State private var isParkAlertShow: Bool = false
    @State private var isShowDirections: Bool = false

    var body: some View {
        ZStack {
            MapView(selectedPosition: self.$selectedPosition, route: self.$route, isParkSelected: self.$isParkSelected, isShowDirections: self.$isShowDirections)

            Image(systemName: "mappin")
                .resizable()
                .frame(width: 16, height: 48)
                .foregroundColor(.red)
                .position(CGPoint(x:  UIScreen.main.bounds.size.width / 2, y: (UIScreen.main.bounds.size.height / 2) - 64))

            if let lookAroundScene {
                LookAroundPreview(initialScene: lookAroundScene)
                    .frame(height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding([.top, .horizontal])
            }

            if let travelTime, self.isShowDirections {
                Text("Tiempo estimado de llegada: \(travelTime)")
                    .padding()
                    .font(.caption)
                    .foregroundStyle(.black)
                    .background(.thinMaterial)
                    .cornerRadius(16)
                    .shadow(radius: 4)
                    .position(CGPoint(x: UIScreen.main.bounds.size.width / 2, y: UIScreen.main.bounds.size.height - 264))
            }

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(radius: 4)
                    .frame(width: 300, height: 84)

                HStack {
                    Spacer()
                        .frame(width: 24, height: 24)
                        .padding(32)

                    Button(action: {
                        guard let source = self.locationManager.location,
                              let lastLocation = self.locations.last, lastLocation.isSelected else { return }
                        self.isShowDirections.toggle()
                        self.getDirections(source, destination: CLLocationCoordinate2D(latitude: lastLocation.latitude, longitude: lastLocation.longitude))
                    }) {
                        Image(systemName: "figure.walk.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .tint(self.isShowDirections ? .gray : .blue)
                    }

                    Button(action: {
                        if let lastLocation = self.locations.last, lastLocation.isSelected {
                            self.isParkAlertShow.toggle()
                        } else {
                            self.locations.forEach { location in
                                location.isSelected = false
                            }
                            self.modelContext.insert(ParkModel(latitude: self.selectedPosition.latitude,
                                                               longitude: self.selectedPosition.longitude, timestamp: Date(),
                                                               isSelected: true))
                            self.isParkSelected.toggle()
                        }
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "parkingsign.circle.fill")
                                .resizable()
                                .frame(width: 48, height: 48)
                                .tint(self.isParkSelected ? .gray : .blue)
                            if self.isParkSelected, self.isParkSelectedDotAnimation {
                                Circle()
                                    .frame(width: 16, height: 16)
                                    .foregroundStyle(.red)
                            }
                        }
                        .frame(width: 48, height: 48)
                    }
                    .frame(maxWidth: .infinity)

                    Button(action: {
                        self.locationManager.requestLocation()
                    }) {
                        Image(systemName: "location.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .tint(.blue)
                    }

                    Spacer()
                        .frame(width: 24, height: 24)
                        .padding(32)
                }
            }
            .position(CGPoint(x: UIScreen.main.bounds.size.width / 2, y: UIScreen.main.bounds.size.height - 180))
        }
        .environmentObject(self.locationManager)
        .onAppear {
            self.locationManager.requestLocation()
        }
        .onAppear {
            guard let lastLocation = self.locations.last else { return }
            self.isParkSelected = lastLocation.isSelected
            
            if self.isParkSelected {
                self.startBlinking()
            }
        }
        .alert(isPresented: self.$isParkAlertShow) {
            Alert(title: Text("¿Has llegado a tu coche?"),
                  message: Text("Indica si quieres desaparcar"),
                  primaryButton: .cancel(Text("Cancelar"), action: {}),
                  secondaryButton: .default(Text("Desaparcar"), action: {
                if let lastLocation = self.locations.last, lastLocation.isSelected {
                    self.isParkSelected.toggle()
                    self.modelContext.delete(lastLocation)
                }
            }))
        }
    }

    func getDirections(_ source: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile

        Task {
            let result = try? await MKDirections(request: request).calculate()
            self.route = result?.routes.first
            self.getTravelTime()
        }
    }

    func getLookAroundScene(_ position: CLLocationCoordinate2D) {
        lookAroundScene = nil
        Task {
            let request = MKLookAroundSceneRequest(coordinate: position)
            lookAroundScene = try? await request.scene
        }
    }

    private func getTravelTime() {
        guard let route else { return }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute]
        self.travelTime = formatter.string(from: route.expectedTravelTime)
    }
    
    private func startBlinking() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.isParkSelectedDotAnimation.toggle()
        }
    }
}
