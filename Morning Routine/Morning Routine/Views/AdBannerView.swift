import SwiftUI
import GoogleMobileAds

/// SwiftUI wrapper for Google Mobile Ads banner view
struct AdBannerView: UIViewControllerRepresentable {
    let adUnitID: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = viewController
        
        viewController.view.addSubview(bannerView)
        viewController.view.backgroundColor = .clear
        
        // Set up constraints
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            bannerView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
        
        // Assign delegate for lifecycle callbacks
        bannerView.delegate = context.coordinator

        // Load the ad
        let request = GADRequest()
        print("[AdBannerView] Loading banner ad for unit: \(adUnitID)")
        bannerView.load(request)

        // Coordinator will log receipt/failure/clicks
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}

extension AdBannerView {
    class Coordinator: NSObject, GADBannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("[AdBannerView] bannerViewDidReceiveAd - adUnit: \(bannerView.adUnitID ?? "unknown")")
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("[AdBannerView] didFailToReceiveAdWithError: \(error.localizedDescription) - adUnit: \(bannerView.adUnitID ?? "unknown")")
        }

        func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
            print("[AdBannerView] bannerViewDidRecordImpression - adUnit: \(bannerView.adUnitID ?? "unknown")")
        }

        func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
            print("[AdBannerView] bannerViewDidRecordClick - adUnit: \(bannerView.adUnitID ?? "unknown")")
        }

        func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
            print("[AdBannerView] bannerViewWillPresentScreen - user is opening the ad")
        }

        func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
            print("[AdBannerView] bannerViewWillDismissScreen")
        }

        func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
            print("[AdBannerView] bannerViewDidDismissScreen")
        }
    }
}

