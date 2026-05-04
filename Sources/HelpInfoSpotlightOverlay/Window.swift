import SwiftUI
import UIKit

// Based on code found in https://github.com/mmellau/swift-beacon

@Observable
class WindowState<ID: Hashable> {
  var preferences: [ID: Anchor<CGRect>] = [:]
}

@MainActor
final class WindowManager<ID: Hashable, Overlay: View> {
  private var hostWindow: UIWindow?
  private var hostingController: UIHostingController<WindowedOverlay<ID, Overlay>>?
  private var windowState: WindowState<ID> = .init()

  init() {}

  func show(
    selection: Binding<ID?>,
    config: Config<ID, Overlay>,
    preferences: [ID: Anchor<CGRect>],
    scrollViewProxy: ScrollViewProxy?,
    animationNamespace: Namespace.ID
  ) {
    guard
      hostWindow == nil,
      let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
    else {
      windowState.preferences = preferences
      return
    }

    let window = UIWindow(windowScene: scene)
    window.backgroundColor = .clear
    window.windowLevel = .alert + 1  // Above sheets, alerts, etc.
    hostWindow = window

    let overlayView = WindowedOverlay<ID, Overlay>(
      selection: selection,
      config: config,
      windowState: windowState,
      dismiss: { [weak self] in
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

  func hide(after duration: Duration) {
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

struct WindowedOverlay<ID: Hashable, Overlay: View>: View {
  typealias Value = HelpInfoSpotlightOverlayPreferenceKey<ID>.Value

  @Binding var selection: ID?
  let config: Config<ID, Overlay>
  @State var windowState: WindowState<ID>
  @State var isVisible = true
  let dismiss: () -> Void
  let scrollViewProxy: ScrollViewProxy?
  let animationNamespace: Namespace.ID

  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    if let selected = selection, let anchor = windowState.preferences[selected] {
      GeometryReader { geometryProxy in
        SpotlightOverlayContent<ID, Overlay>(
          selection: $selection,
          spotlightAnimation: animationNamespace,
          config: config,
          preferences: windowState.preferences,
          geometryProxy: geometryProxy,
          scrollViewProxy: scrollViewProxy,
          selected: selected,
          anchor: anchor,
          dismiss: self.dismiss
        )
        .transition(.opacity)
      }
      .animation(.smooth(duration: config.animationDuration), value: selection)
    } else {
      EmptyView()
//      ZStack(alignment: .topLeading) {
//        SpotlightMask(
//          config: config,
//          selection: selection,
//          focusArea: .zero,
//          animationNamespace: animationNamespace,
//          dismissAction: dismiss
//        )
//        .ignoresSafeArea()
//      }
//      .opacity(isVisible ? 1 : 0)
//      .onAppear {
//        withAnimation(.smooth(duration: config.animationDuration)) {
//          isVisible = false
//        }
//      }
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
