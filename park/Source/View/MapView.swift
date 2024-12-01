//
// Created by David Martin on 13/2/24.
//

import SwiftData
import SwiftUI
import MapKit
import vegaDesignSystem

struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var locationManager: LocationManager

    @State private var position: MapCameraPosition = MapCameraPosition.automatic
    @Query private var locations: [ParkModel]

    @Binding var isLoading: Bool
    @Binding var selectedPosition: CLLocationCoordinate2D

    @Binding var route: MKRoute?
    @Binding var isParkSelected: Bool
    @Binding var isShowDirections: Bool
    @State private var isShowShareAction: Bool = false
    @State private var isActionSheetShow: Bool = true
    @State private var isSettingsSheetShow: Bool = false

    var body: some View {
        VStack {
            MapReader { proxy in
                Map(position: self.$position) {
                    if let lastLocation = self.locations.last, lastLocation.isSelected {
                        Annotation("", coordinate: CLLocationCoordinate2D(latitude: lastLocation.latitude, longitude: lastLocation.longitude)) {
                            ZStack {
                                Circle()
                                    .fill(AppColor.background)
                                    .frame(width: Dimensions.XXXL, height: Dimensions.XXXL)
                                AppIcons.car
                                    .resizable()
                                    .frame(width: Dimensions.XXL, height: Dimensions.XXL)
                                    .foregroundColor(AppColor.primary)
                            }
                            .shadow(radius: 4)
                        }
                    }

                    if let position = self.locationManager.location {
                        Annotation("", coordinate: position) {
                            ZStack {
                                Circle()
                                    .fill(AppColor.background)
                                    .frame(width: Dimensions.XL, height: Dimensions.XL)
                                AppIcons.marker
                                    .resizable()
                                    .frame(width: Dimensions.L, height: Dimensions.L)
                                    .foregroundColor(AppColor.primary)
                            }
                            .shadow(radius: 4)
                        }
                    }

                    if let route, self.isShowDirections {
                        MapPolyline(route.polyline)
                            .stroke(AppColor.primary, lineWidth: 8)
                    }
                }
                .mapStyle(.standard(elevation: .automatic, pointsOfInterest: .including([.parking])))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .onTapGesture { newValue in
                    if let position = proxy.convert(newValue, from: .local) {
                        withAnimation {
                            self.position = MapCameraPosition.camera(MapCamera(centerCoordinate: position, distance: 15))
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .top, alignment: .trailing) {
            Button {
                self.isShowShareAction.toggle()
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
            .disabled(!self.isParkSelected)
        }
//        .safeAreaInset(edge: .top, alignment: .trailing) {
//            RoundedRectangle(cornerRadius: 8)
//                .fill(.white)
//                .shadow(radius: 4)
//                .frame(width: 44, height: 44)
//                .overlay {
//                    Button(action: {
//                        self.isActionSheetShow.toggle()
//                        self.isSettingsSheetShow.toggle()
//                    }) {
//                        Image(systemName: "gearshape.fill")
//                            .resizable()
//                            .frame(width: Dimensions.L, height: Dimensions.L)
//                            .tint(AppColor.primary)
//                    }
//                }
//                .padding(Dimensions.M)
//        }
//        .safeAreaInset(edge: .top, alignment: .center) {
//            Button(action: {
//
//            }) {
//                Text("Update to PRO")
//                    .padding()
//                    .background(AppColor.primary)
//                    .foregroundStyle(.white)
//                    .bold()
//                    .font(.nunitoBody)
//            }
//            .frame(height: 32)
//            .clipShape(.capsule)
//        }
//        .sheet(isPresented: self.$isSettingsSheetShow) {
//            SettingsView(isShowing: self.$isActionSheetShow)
//                .presentationDetents([.large])
//                .presentationDragIndicator(.visible)
//                .presentationBackgroundInteraction(.enabled)
////                .interactiveDismissDisabled()
//                .padding(.top, 32)
//                .presentationBackground(.white)
//        }
        .onMapCameraChange { context in
            withAnimation {
                self.selectedPosition = context.region.center
            }
        }
        .onReceive(self.locationManager.$location) { newValue in
            withAnimation {
                guard let position = newValue else { return }
                self.position = MapCameraPosition.region(
                    MKCoordinateRegion(
                        center: position,
                        span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                    )
                )
                self.isLoading = false
            }
        }
        .onChange(of: self.isShowDirections) { oldValue, newValue in
            guard oldValue != newValue, let route else { return }
            withAnimation {
                self.position = MapCameraPosition.camera(MapCamera(centerCoordinate: route.polyline.coordinate, distance: route.distance))
            }
        }
        .onChange(of: self.isShowShareAction) { oldValue, newValue in
            guard oldValue != newValue else { return }
            self.sharePark()
        }
    }
    
    private func sharePark() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        guard let location = self.locations.last else { return }
        let mapsIntentUrl = "https://www.google.com/maps/dir/?api=1&destination=\(location.latitude),\(location.longitude)&travelmode=walking"
        let activityViewController = UIActivityViewController(activityItems: ["El coche está aparcado aquí: \(mapsIntentUrl)"], applicationActivities: nil)
        rootViewController.present(activityViewController, animated: true, completion: nil)
    }
}
