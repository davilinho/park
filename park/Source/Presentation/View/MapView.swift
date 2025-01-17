//
// Created by David Martin on 13/2/24.
//

import SwiftData
import SwiftUI
import MapKit
import vegaDesignSystem

struct MapView: View {
    @Environment(ParkViewModel.self) private var viewModel

    @State private var position: MapCameraPosition = MapCameraPosition.automatic
    @Query private var locations: [ParkModel]

    var body: some View {
        @Bindable var viewModel = self.viewModel

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

                    if let position = viewModel.locationManager.location {
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

                    if let route = viewModel.route, viewModel.uiStatus.isDirectionsShowing {
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
        .onMapCameraChange { context in
            withAnimation {
                viewModel.selectedPosition = context.region.center
            }
        }
        .onReceive(viewModel.locationManager.$location) { newValue in
            withAnimation {
                guard let position = newValue else { return }
                self.position = MapCameraPosition.region(
                    MKCoordinateRegion(
                        center: position,
                        span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                    )
                )
                viewModel.set(uiStatus: .none)
            }
        }
        .onChange(of: viewModel.uiStatus.isDirectionsShowing) { oldValue, newValue in
            withAnimation {
                guard oldValue != newValue, newValue,
                      let lastLocation = self.locations.last, lastLocation.isSelected else { return }
                self.position = MapCameraPosition.region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: lastLocation.latitude, longitude: lastLocation.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
                    )
                )
            }
        }
    }
}
