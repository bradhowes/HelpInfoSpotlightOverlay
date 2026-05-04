import SwiftUI
import UIKit

/**
 Manage the creation and presentation of the top-level window that hosts the help spotlight overlays.

 Creates the window in its `show` routine, but only creates it once -- the `show` method can be called multiple times while SwiftUI
 is laying out views and adjusting to state changes.

 The window is torn down in the `hide` routine, which is triggered by a dismiss action.
 */
@MainActor
final class WindowManager<ID: Hashable, Overlay: View> {
  private var hostWindow: UIWindow?
  private var hostingController: UIHostingController<WindowedOverlay<ID, Overlay>>?
  private var windowedOverlayState: WindowedOverlayState<ID> = .init()

  init() {}

  /**
   Create/update window and its overlay view.

   If the window already exists, refresh the anchor map it uses to locate the tagged help items in the root view. Otherwise,
   create the window and show it.

   - parameter selection: the binding to use to track the currently active help item.
   - parameter config: the configuration to use for behavior and UI settings.
   - parameter anchors: the mapping of tagged help item IDs and their anchor geometries.
   - parameter scrollViewProxy: optional `ScrollViewProxy` to use to reposition a help item onto the screen.
   - parameter animationNamespace: the animation namespace to use
   */
  func show(
    selection: Binding<ID?>,
    config: Config<ID, Overlay>,
    anchors: [ID: Anchor<CGRect>],
    scrollViewProxy: ScrollViewProxy?,
    animationNamespace: Namespace.ID
  ) {
    guard
      hostWindow == nil,
      let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
    else {
      windowedOverlayState.anchors = anchors
      return
    }

    let window = UIWindow(windowScene: scene)
    window.backgroundColor = .clear
    window.windowLevel = .alert + 1  // Above sheets, alerts, etc.
    hostWindow = window

    let overlayView = WindowedOverlay<ID, Overlay>(
      selection: selection,
      config: config,
      windowedOverlayState: windowedOverlayState,
      dismissAction: { [weak self] in
        // Animate the disappearance of the spotlight overlay.
        withAnimation(.smooth(duration: config.animationDuration)) {
          selection.wrappedValue = nil
        }
        self?.hide(after: .seconds(config.animationDuration))
      },
      scrollViewProxy: scrollViewProxy,
      animationNamespace: animationNamespace
    )

    let controller = UIHostingController(rootView: overlayView)
    controller.view.backgroundColor = .clear
    hostingController = controller
    window.rootViewController = controller
    window.isHidden = false
  }

  /**
   Tear-down the window.

   - parameter duration: the amount of time to wait before tearing down. This should match the animation duration so that the view
   hierarchy exists while the animation used during the dismissal of the spotlight is active.
   */
  private func hide(after duration: Duration) {
    Task { [weak self] in
      try? await Task.sleep(for: duration)
      if let self {
        self.hostWindow?.isHidden = true
        self.hostWindow?.rootViewController = nil
        self.hostWindow = nil
        self.hostingController = nil
      }
    }
  }
}

/**
 When the WindowedOverlay is up, allow for changes to the collection of anchors.
 */
@Observable
class WindowedOverlayState<ID: Hashable> {
  var anchors: [ID: Anchor<CGRect>] = [:]
}

/**
 The main view of the window that shows the spotlight overlay.
 */
struct WindowedOverlay<ID: Hashable, Overlay: View>: View {
  typealias Value = HelpInfoSpotlightOverlayPreferenceKey<ID>.Value

  @Binding var selection: ID?
  let config: Config<ID, Overlay>
  @State var windowedOverlayState: WindowedOverlayState<ID>
  @State var isVisible = false
  let dismissAction: () -> Void
  let scrollViewProxy: ScrollViewProxy?
  let animationNamespace: Namespace.ID

  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    if let selected = selection, let anchor = windowedOverlayState.anchors[selected] {
      // Important to use our own `GeometryReader` and not the one injected by ``HelpInfoSpotlightOverlayModifier`` since the
      // container bounds are probably different.
      GeometryReader { geometryProxy in
        SpotlightOverlay(
          selection: $selection,
          animationNamespace: animationNamespace,
          config: config,
          anchors: windowedOverlayState.anchors,
          geometryProxy: geometryProxy,
          scrollViewProxy: scrollViewProxy,
          selected: selected,
          anchor: anchor,
          dismissAction: dismissAction
        )
      }
      // Animate the appearance of the spotlight overlay. The animation for the disappearance is handled in the `dismissAction`.
      .opacity(isVisible ? 1 : 0)
      .animation(.smooth(duration: config.animationDuration), value: selection)
      .animation(.smooth(duration: config.animationDuration), value: isVisible)
      .onAppear {
        isVisible = true
      }
    } else {
      EmptyView()
    }
  }
}

#if DEBUG

#Preview {

#if os(macOS)

  TutorialSpotlightDemo()
    .frame(width: 800, height: 600)

#else

  TutorialSpotlightDemo()

#endif

}

#endif // DEBUG
