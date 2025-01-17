//
// Created by David Martin on 13/2/24.
//

import FirebaseAnalytics
@preconcurrency import MapKit
import SwiftUI
import SwiftData
import vegaDesignSystem

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ContentViewModel.self) private var viewModel

    @EnvironmentObject var locationManager: LocationManager
    @Query private var locations: [ParkModel]

    @StateObject private var bluetoothManager = BluetoothManager()

    @State private var lookAroundScene: MKLookAroundScene?
    @State private var selectedPosition: CLLocationCoordinate2D = .init()

    var body: some View {
        @Bindable var viewModel = self.viewModel

        ZStack {
            MapView(isLoading: $viewModel.isLoading,
                    selectedPosition: self.$selectedPosition,
                    route: $viewModel.route,
                    isParkSelected: $viewModel.isParkSelected,
                    isShowDirections: $viewModel.isShowDirections)

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

            if let travelTime = viewModel.travelTime, viewModel.isShowDirections {
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
                        viewModel.isShowDirections.toggle()
                        viewModel.getDirections(source, destination: CLLocationCoordinate2D(latitude: lastLocation.latitude, longitude: lastLocation.longitude))
                    }) {
                        if viewModel.isParkSelected {
                            AppIcons.track
                                .resizable()
                                .frame(width: Dimensions.XL, height: Dimensions.XL)
                                .tint(viewModel.isShowDirections ? AppColor.disabled : AppColor.primary)
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
                            viewModel.isParkAlertShow.toggle()
                        } else {
                            self.park()
                        }
                    }) {
                        ZStack(alignment: .center) {
                            AppIcons.parking
                                .resizable()
                                .frame(width: Dimensions.XXL, height: Dimensions.XXL)
                                .tint(viewModel.isParkSelected ? AppColor.disabled : AppColor.primary)
                            if viewModel.isParkSelected {
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

            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.75)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                        .position(CGPoint(x:  UIScreen.main.bounds.size.width / 2, y: (UIScreen.main.bounds.size.height / 2) - Dimensions.L))
                }
                .transition(.opacity)
                .animation(.easeInOut, value: viewModel.isLoading)
            }
        }
        .environmentObject(self.locationManager)
        .onAppear {
            self.locationManager.requestLocation()
        }
        .onAppear {
            guard let lastLocation = self.locations.last else { return }
            viewModel.isParkSelected = lastLocation.isSelected
        }
        .alert(isPresented: $viewModel.isParkAlertShow) {
            Alert(title: Text("¿Has llegado a tu coche?"),
                  message: Text("Indica si quieres aparcar"),
                  primaryButton: .default(Text("Aparcar"), action: {
                self.unPark()
                self.park()
            }),
                  secondaryButton: .destructive(Text("Cerrar"), action: {
                viewModel.isParkAlertShow.toggle()
            }))
        }
    }

    func getLookAroundScene(_ position: CLLocationCoordinate2D) {
        self.lookAroundScene = nil
        Task {
            let request = MKLookAroundSceneRequest(coordinate: position)
            self.lookAroundScene = try? await request.scene
        }
    }
    
    private func unPark() {
        @Bindable var viewModel = self.viewModel

        if let lastLocation = self.locations.last, lastLocation.isSelected {
            withAnimation {
                viewModel.isParkSelected.toggle()
            }
            self.modelContext.delete(lastLocation)
            viewModel.isShowDirections = false
        }
    }
    
    private func park() {
        @Bindable var viewModel = self.viewModel

        self.locations.forEach { location in
            location.isSelected = false
        }
        self.modelContext.insert(ParkModel(latitude: self.selectedPosition.latitude,
                                           longitude: self.selectedPosition.longitude, timestamp: Date(),
                                           isSelected: true))
        withAnimation {
            viewModel.isParkSelected.toggle()
        }
    }
}
