//
// Created by David Martin on 13/2/24.
//

import GoogleMobileAds
import FirebaseAnalytics
import MapKit
import SwiftUI
import SwiftData
import vegaDesignSystem

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(ParkViewModel.self) private var viewModel

    @Query private var locations: [ParkModel]

    var body: some View {
        @Bindable var viewModel = self.viewModel

        GeometryReader { geometry in
            let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(geometry.size.width)

            VStack {
                ZStack {
                    MapView()

                    AppIcons.pin
                        .resizable()
                        .frame(width: Dimensions.M, height: Dimensions.XXL)
                        .foregroundColor(AppColor.accent)
                        .position(CGPoint(x:  UIScreen.main.bounds.size.width / 2, y: (UIScreen.main.bounds.size.height / 2) - 150))

                    if let travelTime = viewModel.travelTime, viewModel.uiStatus.isDirectionsShowing {
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
                                guard let source = viewModel.locationManager.location,
                                      let lastLocation = self.locations.last, lastLocation.isSelected else { return }
                                viewModel.set(uiStatus: .directionsShowing)
                                viewModel.getDirections(source, destination: CLLocationCoordinate2D(latitude: lastLocation.latitude, longitude: lastLocation.longitude))
                            }) {
                                if viewModel.status.isParked {
                                    AppIcons.track
                                        .resizable()
                                        .frame(width: Dimensions.XL, height: Dimensions.XL)
                                        .tint(viewModel.uiStatus.isDirectionsShowing ? AppColor.disabled : AppColor.primary)
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
                                    viewModel.set(uiStatus: .alertShowing)
                                } else {
                                    self.park()
                                }
                            }) {
                                ZStack(alignment: .center) {
                                    AppIcons.parking
                                        .resizable()
                                        .frame(width: Dimensions.XXL, height: Dimensions.XXL)
                                        .tint(viewModel.status.isParked ? AppColor.disabled : AppColor.primary)
                                    if viewModel.status.isParked {
                                        Circle()
                                            .stroke(AppColor.accent, lineWidth: Dimensions.XS)
                                            .frame(width: Dimensions.XXL, height: Dimensions.XXL)
                                    }
                                }
                                .frame(width: Dimensions.XXXL, height: Dimensions.XXXL)
                            }
                            .frame(maxWidth: .infinity)

                            Button(action: {
                                viewModel.locationManager.requestLocation()
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
                    .position(CGPoint(x: UIScreen.main.bounds.size.width / 2, y: UIScreen.main.bounds.size.height - 320))

                    if viewModel.uiStatus.isLoading {
                        ZStack {
                            Color.black.opacity(0.75)
                                .ignoresSafeArea()

                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(2)
                                .position(CGPoint(x:  UIScreen.main.bounds.size.width / 2, y: (UIScreen.main.bounds.size.height / 2) - 120))
                        }
                        .transition(.opacity)
                        .animation(.easeInOut, value: viewModel.uiStatus.isLoading)
                    }
                }

                BannerView(adSize)
                    .frame(height: adSize.size.height)
            }
        }
        .safeAreaInset(edge: .top, alignment: .trailing) {
            Button {
                viewModel.set(uiStatus: .shareActionShowing)
            } label: {
                RoundedRectangle(cornerRadius: Dimensions.S)
                    .fill(.thinMaterial)
                    .shadow(radius: Dimensions.XS)
                    .frame(width: Dimensions.XXL, height: Dimensions.XXL)
                    .overlay {
                        AppIcons.share
                            .resizable()
                            .frame(width: Dimensions.XL, height: Dimensions.XL)
                            .tint(AppColor.primary)
                    }
                    .padding(Dimensions.M)
            }
            .disabled(viewModel.status.iusNotParked)
        }
        .onAppear {
            viewModel.locationManager.requestLocation()
        }
        .onAppear {
            guard let lastLocation = self.locations.last else { return }
            viewModel.set(status: lastLocation.isSelected ? .parked : .notParked)
        }
        .onChange(of: self.scenePhase) { oldPhase, newPhase in
            guard oldPhase != newPhase else { return }
            switch newPhase {
            case .active:
                viewModel.startAdTimer()
            default:
                viewModel.stopTimer()
            }
        }
        .onChange(of: viewModel.uiStatus.isShareActionShowing) { oldValue, newValue in
            guard oldValue != newValue else { return }
            viewModel.sharePark(location: self.locations.last)
            viewModel.set(uiStatus: .none)
        }
        .onReceive(viewModel.bluetoothManager.$isConnected) { newValue in
            if newValue {
                self.unPark()
            } else {
                self.park()
            }
        }
        .alert(isPresented: $viewModel.uiStatus.isAlertShowing) {
            Alert(title: Text("¿Has llegado a tu coche?"),
                  message: Text("Indica si quieres aparcar"),
                  primaryButton: .default(Text("Aparcar"), action: {
                self.unPark()
                self.park()
            }),
                  secondaryButton: .destructive(Text("Cerrar"), action: {
                viewModel.set(uiStatus: .none)
            }))
        }
    }
    
    private func unPark() {
        @Bindable var viewModel = self.viewModel

        if let lastLocation = self.locations.last, lastLocation.isSelected {
            withAnimation {
                viewModel.set(status: .notParked)
            }
            self.modelContext.delete(lastLocation)
            viewModel.set(uiStatus: .none)
        }
    }
    
    private func park() {
        @Bindable var viewModel = self.viewModel

        self.locations.forEach { location in
            location.isSelected = false
        }
        self.modelContext.insert(ParkModel(latitude: viewModel.selectedPosition.latitude,
                                           longitude: viewModel.selectedPosition.longitude,
                                           timestamp: Date(),
                                           isSelected: true))
        withAnimation {
            viewModel.set(status: .parked)
        }
    }
}
