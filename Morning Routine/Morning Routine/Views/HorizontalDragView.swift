import SwiftUI
import UIKit

// MARK: - UIKit gesture recognizer that only tracks horizontal pans

/// A UIPanGestureRecognizer subclass that immediately fails when the
/// initial movement is more vertical than horizontal, letting the
/// enclosing UIScrollView (SwiftUI ScrollView) scroll normally.
private class HorizontalPanGesture: UIPanGestureRecognizer {
    private var hasDecidedDirection = false

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        if !hasDecidedDirection {
            hasDecidedDirection = true
            let v = velocity(in: view)
            // If the vertical component is larger, fail immediately
            if abs(v.y) > abs(v.x) {
                state = .failed
            }
        }
    }

    override func reset() {
        super.reset()
        hasDecidedDirection = false
    }
}

// MARK: - UIViewRepresentable wrapper

/// An invisible overlay that attaches a horizontal-only UIPanGestureRecognizer.
/// When the user swipes vertically, the recognizer fails and the scroll view
/// takes over as if nothing is there. Horizontal drags report the normalised
/// x-position (0…1) via the `onHorizontalDrag` closure.
struct HorizontalDragOverlay: UIViewRepresentable {
    /// Called with normalised x (0…1) on each horizontal drag update.
    var onHorizontalDrag: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onDrag: onHorizontalDrag) }

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.backgroundColor = .clear

        let pan = HorizontalPanGesture(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        // Allow the scroll view's own pan to work simultaneously when ours fails
        pan.delegate = context.coordinator
        v.addGestureRecognizer(pan)

        // Also handle simple taps (touch-down without movement) so the user
        // can tap a spot on the slider to jump there.
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        v.addGestureRecognizer(tap)

        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onDrag = onHorizontalDrag
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onDrag: (CGFloat) -> Void

        init(onDrag: @escaping (CGFloat) -> Void) { self.onDrag = onDrag }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }
            let loc = gesture.location(in: view)
            let width = max(view.bounds.width, 1)
            let norm = min(max(loc.x / width, 0), 1)
            if gesture.state == .changed || gesture.state == .began {
                onDrag(norm)
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view else { return }
            let loc = gesture.location(in: view)
            let width = max(view.bounds.width, 1)
            let norm = min(max(loc.x / width, 0), 1)
            onDrag(norm)
        }

        // Allow vertical scroll views to scroll simultaneously,
        // but block paging scroll views (TabView page swiping).
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            if let scrollView = other.view as? UIScrollView, scrollView.isPagingEnabled {
                return false
            }
            return true
        }

        // Make the TabView's paging pan gesture wait for our gesture
        // to fail before it can begin. If we succeed (horizontal swipe),
        // the page turn never fires. If we fail (vertical swipe), the
        // page gesture is free to try (but will ignore vertical movement).
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy other: UIGestureRecognizer
        ) -> Bool {
            if let scrollView = other.view as? UIScrollView, scrollView.isPagingEnabled {
                return true
            }
            return false
        }
    }
}
