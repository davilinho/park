//
// Created by David Martin on 13/2/24.
//

import SwiftData
import SwiftUI
import MapKit

struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var locationManager: LocationManager

    @State private var position: MapCameraPosition = MapCameraPosition.automatic
    @Query private var locations: [ParkModel]

    @Binding var selectedPosition: CLLocationCoordinate2D

    @Binding var route: MKRoute?
    @Binding var isParkSelected: Bool
    @Binding var isShowDirections: Bool
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
                                    .fill(.white)
                                    .frame(width: 54, height: 54)
                                Image(systemName: "car.circle")
                                    .resizable()
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(.blue)
                            }
                            .shadow(radius: 4)
                        }
                    }

                    if let position = self.locationManager.location {
                        Annotation("", coordinate: position) {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "smallcircle.filled.circle.fill")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.blue)
                            }
                            .shadow(radius: 4)
                        }
                    }

                    if let route, self.isShowDirections {
                        MapPolyline(route.polyline)
                            .stroke(.blue, lineWidth: 8)
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
//                            .frame(width: 24, height: 24)
//                            .tint(.blue)
//                    }
//                }
//                .padding(16)
//        }
//        .safeAreaInset(edge: .top, alignment: .center) {
//            Button(action: {
//
//            }) {
//                Text("Update to PRO")
//                    .padding()
//                    .background(.blue)
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
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    )
                )
            }
        }
    }
}
