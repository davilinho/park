//
//  AdMobManager.swift
//  park
//
//  Created by David Martin Nevado on 19/1/25.
//

import GoogleMobileAds
import SwiftUI

@MainActor
class AdMobManager: NSObject, GADFullScreenContentDelegate {
    private enum Constants {
        static let interstitialAdUnitId: String = "ca-app-pub-7484598801086427/2876996696"
        static let bannerAdUnitId: String = "ca-app-pub-7484598801086427/9371921152"
    }

    // MARK: - Interstitial

    private var interstitial: GADInterstitialAd?

    func showInterstitialAd(from rootViewController: UIViewController) {
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: Constants.interstitialAdUnitId, request: request) { [weak self] ad, error in
            guard let self else { return }

            if let error {
                FirebaseLog.instance.error("Failed to load interstitial ad: %@", error.localizedDescription)
                return
            }

            self.interstitial = ad

            guard let interstitial else { return }

            interstitial.fullScreenContentDelegate = self

            do {
                try interstitial.canPresent(fromRootViewController: rootViewController)
                interstitial.present(fromRootViewController: rootViewController)
            } catch {
                FirebaseLog.instance.error("Can't show interstitial: %@", error.localizedDescription)
            }
        }
    }

    // MARK: - Banner

    private(set) lazy var bannerView: GADBannerView = {
        guard let parent else { return GADBannerView() }
        let banner = GADBannerView(adSize: parent.adSize)
        banner.adUnitID = Constants.bannerAdUnitId
        banner.load(GADRequest())
        banner.delegate = self
        return banner
    }()

    let parent: BannerView?

    init(_ parent: BannerView? = nil) {
        self.parent = parent
    }

    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        bannerView.alpha = 0
        UIView.animate(withDuration: 1) {
            bannerView.alpha = 1
        }
    }
}

extension AdMobManager: @preconcurrency GADBannerViewDelegate {
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        FirebaseLog.instance.error("bannerView:didFailToReceiveAdWithError: %@", error.localizedDescription)
    }

    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        FirebaseLog.instance.debug("bannerViewDidRecordImpression")
    }

    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        FirebaseLog.instance.debug("bannerViewWillPresentScreen")
    }

    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        FirebaseLog.instance.debug("bannerViewWillDIsmissScreen")
    }

    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        FirebaseLog.instance.debug("bannerViewDidDismissScreen")
    }
}

struct BannerView: UIViewRepresentable {
    let adSize: GADAdSize

    init(_ adSize: GADAdSize) {
        self.adSize = adSize
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.addSubview(context.coordinator.bannerView)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.bannerView.adSize = adSize
    }

    func makeCoordinator() -> AdMobManager {
        AdMobManager(self)
    }
}
