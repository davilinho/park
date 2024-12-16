//
// Created by David Martin on 13/2/24.
//

import FirebaseAnalytics
import MapKit
import SwiftUI
import SwiftData
import vegaDesignSystem

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

//    @AppStorage("isParkSelected") var isParkSelected = false

//    @StateObject var locationManager = LocationManager()
    @EnvironmentObject var locationManager: LocationManager
    @Query private var locations: [ParkModel]

    @StateObject private var bluetoothManager = BluetoothManager()

    @State private var isLoading: Bool = true
    @State private var route: MKRoute?
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var travelTime: String?
    @State private var selectedPosition: CLLocationCoordinate2D = .init()
    @State private var isParkSelected: Bool = false
    @State private var isParkAlertShow: Bool = false
    @State private var isShowDirections: Bool = false

    var body: some View {
        ZStack {
            MapView(isLoading: self.$isLoading,
                    selectedPosition: self.$selectedPosition,
                    route: self.$route,
                    isParkSelected: self.$isParkSelected,
                    isShowDirections: self.$isShowDirections)

            AppIcons.pin
                .resizable()
                .frame(width: Dimensions.M, height: Dimensions.XXL)
                .foregroundColor(AppColor.accent)
                .position(CGPoint(x:  UIScreen.main.bounds.size.width / 2, y: (UIScreen.main.bounds.size.height / 2) - Dimensions.L))

            if let lookAroundScene {
                LookAroundPreview(initialScene: lookAroundScene)
                    .frame(height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding([.top, .horizontal])
            }

            if let travelTime, self.isShowDirections {
                Text("Tiempo estimado de llegada: \(travelTime)")
                    .padding()
                    .font(AppFont.nunitoBody)
                    .foregroundStyle(AppColor.primary)
                    .background(.thinMaterial)
                    .cornerRadius(Dimensions.M)
                    .shadow(radius: 4)
                    .position(CGPoint(x: UIScreen.main.bounds.size.width / 2, y: UIScreen.main.bounds.size.height - 264))
            }

            ZStack {
                RoundedRectangle(cornerRadius: Dimensions.M)
                    .fill(AppColor.background)
                    .shadow(radius: 4)
                    .frame(width: 300, height: 84)

                HStack {
                    Spacer()
                        .frame(width: Dimensions.L, height: Dimensions.L)
                        .padding(Dimensions.XL)

                    Button(action: {
                        guard let source = self.locationManager.location,
                              let lastLocation = self.locations.last, lastLocation.isSelected else { return }
                        self.isShowDirections.toggle()
                        self.getDirections(source, destination: CLLocationCoordinate2D(latitude: lastLocation.latitude, longitude: lastLocation.longitude))
                    }) {
                        if self.isParkSelected {
                            AppIcons.track
                                .resizable()
                                .frame(width: Dimensions.XL, height: Dimensions.XL)
                                .tint(self.isShowDirections ? AppColor.disabled : AppColor.primary)
                        } else {
                            AppIcons.track
                                .resizable()
                                .frame(width: Dimensions.XL, height: Dimensions.XL)
                                .tint(AppColor.disabled)
                                .disabled(true)
                        }
                    }

                    Button(action: {
                        if let lastLocation = self.locations.last, lastLocation.isSelected {
                            self.isParkAlertShow.toggle()
                        } else {
                            self.park()
                        }
                    }) {
                        ZStack(alignment: .center) {
                            AppIcons.parking
                                .resizable()
                                .frame(width: Dimensions.XXL, height: Dimensions.XXL)
                                .tint(self.isParkSelected ? AppColor.disabled : AppColor.primary)
                            if self.isParkSelected {
                                Circle()
                                    .stroke(AppColor.accent, lineWidth: Dimensions.XS)
                                    .frame(width: Dimensions.XXL, height: Dimensions.XXL)
                            }
                        }
                        .frame(width: Dimensions.XXXL, height: Dimensions.XXXL)
                    }
                    .frame(maxWidth: .infinity)

                    Button(action: {
                        self.locationManager.requestLocation()
                    }) {
                        AppIcons.location
                            .resizable()
                            .frame(width: Dimensions.XL, height: Dimensions.XL)
                            .tint(AppColor.primary)
                    }

                    Spacer()
                        .frame(width: Dimensions.L, height: Dimensions.L)
                        .padding(Dimensions.XL)
                }
            }
            .position(CGPoint(x: UIScreen.main.bounds.size.width / 2, y: UIScreen.main.bounds.size.height - 180))

            if self.isLoading {
                ZStack {
                    Color.black.opacity(0.75)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                        .position(CGPoint(x:  UIScreen.main.bounds.size.width / 2, y: (UIScreen.main.bounds.size.height / 2) - Dimensions.L))
                }
                .transition(.opacity)
                .animation(.easeInOut, value: self.isLoading)
            }
        }
        .environmentObject(self.locationManager)
        .onAppear {
            self.locationManager.requestLocation()
        }
        .onAppear {
            guard let lastLocation = self.locations.last else { return }
            self.isParkSelected = lastLocation.isSelected
        }
        .alert(isPresented: self.$isParkAlertShow) {
            Alert(title: Text("¿Has llegado a tu coche?"),
                  message: Text("Indica si quieres desaparcar o voler a aparcar"),
                  primaryButton: .default(Text("Desaparcar"), action: {
                self.unPark()
            }),
                  secondaryButton: .default(Text("Volver a aparcar"), action: {
                self.unPark()
                self.park()
            }))
        }
    }

    private func getDirections(_ source: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking

        Task {
            let result = try? await MKDirections(request: request).calculate()
            self.route = result?.routes.first
            self.getTravelTime()
        }
    }

    func getLookAroundScene(_ position: CLLocationCoordinate2D) {
        self.lookAroundScene = nil
        Task {
            let request = MKLookAroundSceneRequest(coordinate: position)
            self.lookAroundScene = try? await request.scene
        }
    }

    private func getTravelTime() {
        guard let route else { return }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute]
        self.travelTime = formatter.string(from: route.expectedTravelTime)
    }
    
    private func unPark() {
        if let lastLocation = self.locations.last, lastLocation.isSelected {
            withAnimation {
                self.isParkSelected.toggle()
            }
            self.modelContext.delete(lastLocation)
            self.isShowDirections = false
        }
    }
    
    private func park() {
        self.locations.forEach { location in
            location.isSelected = false
        }
        self.modelContext.insert(ParkModel(latitude: self.selectedPosition.latitude,
                                           longitude: self.selectedPosition.longitude, timestamp: Date(),
                                           isSelected: true))
        withAnimation {
            self.isParkSelected.toggle()
        }
    }
}
