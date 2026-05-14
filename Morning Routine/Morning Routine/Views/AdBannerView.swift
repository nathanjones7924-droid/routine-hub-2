import SwiftUI
import GoogleMobileAds

/// SwiftUI wrapper for Google Mobile Ads banner view
struct AdBannerView: UIViewControllerRepresentable {
    let adUnitID: String
    @Binding var height: CGFloat
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = viewController
        context.coordinator.bannerView = bannerView
        
        viewController.view.addSubview(bannerView)
        viewController.view.backgroundColor = .clear
        
        // Set up constraints
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = bannerView.widthAnchor.constraint(equalToConstant: GADAdSizeBanner.size.width)
        let heightConstraint = bannerView.heightAnchor.constraint(equalToConstant: GADAdSizeBanner.size.height)
        context.coordinator.widthConstraint = widthConstraint
        context.coordinator.heightConstraint = heightConstraint
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            bannerView.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor),
            widthConstraint,
            heightConstraint
        ])
        
        // Assign delegate for lifecycle callbacks
        bannerView.delegate = context.coordinator

        // Coordinator will log receipt/failure/clicks
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let bannerView = context.coordinator.bannerView else { return }
        let viewWidth = uiViewController.view.bounds.width
        guard viewWidth > 0 else { return }

        let adaptiveSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        let sizeChanged = context.coordinator.lastAdSize.width != adaptiveSize.size.width
            || context.coordinator.lastAdSize.height != adaptiveSize.size.height

        if sizeChanged {
            bannerView.adSize = adaptiveSize
            context.coordinator.widthConstraint?.constant = adaptiveSize.size.width
            context.coordinator.heightConstraint?.constant = adaptiveSize.size.height
            context.coordinator.lastAdSize = adaptiveSize.size

            if abs(height - adaptiveSize.size.height) > 0.5 {
                height = adaptiveSize.size.height
            }

            let request = GADRequest()
            print("[AdBannerView] Loading adaptive banner ad for unit: \(adUnitID)")
            bannerView.load(request)
            context.coordinator.hasLoaded = true
        } else if !context.coordinator.hasLoaded {
            let request = GADRequest()
            print("[AdBannerView] Loading banner ad for unit: \(adUnitID)")
            bannerView.load(request)
            context.coordinator.hasLoaded = true
        }
    }
}

extension AdBannerView {
    class Coordinator: NSObject, GADBannerViewDelegate {
        var bannerView: GADBannerView?
        var widthConstraint: NSLayoutConstraint?
        var heightConstraint: NSLayoutConstraint?
        var lastAdSize: CGSize = .zero
        var hasLoaded = false

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

