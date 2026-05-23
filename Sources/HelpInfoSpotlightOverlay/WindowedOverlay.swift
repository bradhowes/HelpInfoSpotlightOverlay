import SwiftUI

#if os(iOS)

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

  init() {
    print("WindowManager - init")
  }

  /**
   Create/update window and its overlay view.

   If the window already exists, refresh the anchor map it uses to locate the tagged help items in the root view. Otherwise,
   create the window and show it.

   - parameter selection: the binding to use to track the currently active help item.
   - parameter config: the configuration to use for behavior and UI settings.
   - parameter anchors: the mapping of tagged help item IDs and their anchor geometries.
   - parameter scrollViewProxy: optional `ScrollViewProxy` to use to reposition a help item onto the screen.
   - parameter animationNamespace: the animation namespace to use
   - returns: `EmptyView` as a placeholder in the parent hierarchy.
   */
  func show(
    selection: Binding<ID?>,
    config: HelpInfoOverlayConfig<ID, Overlay>,
    anchors: [ID: Anchor<CGRect>],
    scrollViewProxy: ScrollViewProxy?,
    animationNamespace: Namespace.ID
  ) -> some View {
    guard
      hostWindow == nil,
      let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
    else {
      self.windowedOverlayState.anchors = anchors
      return EmptyView()
    }

    print("WindowManager - show")
    let window = UIWindow(windowScene: scene)
    window.backgroundColor = .clear
    window.windowLevel = .alert
    hostWindow = window

    let overlayView = WindowedOverlay<ID, Overlay>(
      selection: selection,
      config: config,
      windowedOverlayState: self.windowedOverlayState,
      dismissAction: { [weak self] in
        // Animate the disappearance of the spotlight overlay.
        withAnimation(.smooth(duration: config.viewConfig.animationDuration)) {
          selection.wrappedValue = nil
        }
        self?.hide(after: .seconds(config.viewConfig.animationDuration))
      },
      scrollViewProxy: scrollViewProxy,
      animationNamespace: animationNamespace
    )

    let controller = UIHostingController(rootView: overlayView)
    controller.view.backgroundColor = .clear
    hostingController = controller
    window.rootViewController = controller
    window.isHidden = false

    return EmptyView()
  }

  /**
   Tear down the window with the dismissal of the overlay.

   - parameter duration: the amount of time to wait before tearing down. This should match the animation duration so that the view
   hierarchy exists while the animation used during the dismissal of the spotlight is active.
   */
  private func hide(after duration: Duration) {
    print("WindowManager - hide")
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
 When the WindowedOverlay is up, allow for changes to the collection of anchors to affect the overlay view.
 */
@Observable
private class WindowedOverlayState<ID: Hashable> {
  var anchors: [ID: Anchor<CGRect>] = [:]

  init() {
    print("WindowedOverlayState - init")
  }
}

/**
 The main view of the custom UIWindow that shows the spotlight overlay.
 */
private struct WindowedOverlay<ID: Hashable, Overlay: View>: View {
  typealias Value = SpotlightOverlayPreferenceKey<ID>.Value

  @Binding private var selection: ID?
  private let config: HelpInfoOverlayConfig<ID, Overlay>
  @State private var windowedOverlayState: WindowedOverlayState<ID>
  private let dismissAction: () -> Void
  private let scrollViewProxy: ScrollViewProxy?
  private let animationNamespace: Namespace.ID

  @State var isVisible = false

  init(
    selection: Binding<ID?>,
    config: HelpInfoOverlayConfig<ID, Overlay>,
    windowedOverlayState: WindowedOverlayState<ID>,
    dismissAction: @escaping () -> Void,
    scrollViewProxy: ScrollViewProxy?,
    animationNamespace: Namespace.ID,
  ) {
    print("WindowOverlay -init")
    self._selection = selection
    self.config = config
    self.windowedOverlayState = windowedOverlayState
    self.dismissAction = dismissAction
    self.scrollViewProxy = scrollViewProxy
    self.animationNamespace = animationNamespace
  }

  var body: some View {
    if let selected = selection, let anchor = self.windowedOverlayState.anchors[selected] {
      // Important to use our own `GeometryReader` and not the one injected by ``HelpInfoSpotlightOverlayModifier`` since the
      // container bounds are probably different.
      GeometryReader { geometryProxy in
        SpotlightOverlay(
          selection: $selection,
          animationNamespace: animationNamespace,
          config: config,
          anchors: self.windowedOverlayState.anchors,
          geometryProxy: geometryProxy,
          scrollViewProxy: scrollViewProxy,
          selected: selected,
          anchor: anchor,
          dismissAction: dismissAction,
        )
      }
      // Animate the appearance of the spotlight overlay. The animation for the disappearance is handled in the `dismissAction`.
      .opacity(isVisible ? 1 : 0)
      .animation(.smooth(duration: config.viewConfig.animationDuration), value: selection)
      .animation(.smooth(duration: config.viewConfig.animationDuration), value: isVisible)
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

#else

@MainActor
final class WindowManager<ID: Hashable, Overlay: View> {
  init() {}

  func show(
    selection: Binding<ID?>,
    config: Config<ID, Overlay>,
    anchors: [ID: Anchor<CGRect>],
    scrollViewProxy: ScrollViewProxy?,
    animationNamespace: Namespace.ID
  ) {}
}

#endif // os(iOS)
