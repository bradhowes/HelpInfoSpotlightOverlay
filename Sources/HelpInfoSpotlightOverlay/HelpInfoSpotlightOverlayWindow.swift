import SwiftUI
import UIKit

// Based on code found in https://github.com/mmellau/swift-beacon

@MainActor
final class WindowManager<ID: Hashable, Overlay: View> {
  private var hostWindow: UIWindow?
  private var hostingController: UIHostingController<WindowedOverlay<ID, Overlay>>?

  init() {}

  func show(selection: Binding<ID?>, config: Config<ID, Overlay>, preferences: [ID: PreferenceKeyValue]) {
    guard
      hostWindow == nil,
      let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
    else {
      return
    }

    let window = UIWindow(windowScene: scene)
    window.backgroundColor = .clear
    window.windowLevel = .alert + 1  // Above sheets, alerts, etc.
    hostWindow = window

    let overlayView = WindowedOverlay<ID, Overlay>(
      selection: selection,
      config: config,
      preferences: preferences,
      dismiss: { [weak self] in
        self?.hide(after: .seconds(config.animationDuration))
      },
      containerBounds: window.frame
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
  let preferences: [ID: PreferenceKeyValue]
  let dismiss: () -> Void
  let containerBounds: CGRect

  /// The position of the view displaying the help text. This is dynamically calculated based on the location of the item being
  /// spotlit, and the size of the help text view.
  @State private var position: CGPoint = .zero
  /// When moving to the previous or next anchor, we first scroll to it and set `pending` in order to delay calulation of
  /// the info view position until the anchor is in the new location. An `onChange` modifier in the view from
  /// `spotlightOverlayContent` will set `selection` with `pending`.
  @State private var pending: ID?
  @State private var isVisible = false

  let horizontalPadding: CGFloat = 16
  let verticalSeparation: CGFloat = 24
  let verticalPadding: CGFloat = 24

  @Namespace private var spotlightAnimation
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    if let selected = selection, let preferenceValue = preferences[selected] {
      GeometryReader { proxy in
        let scrollViewProxy = preferenceValue.scrollViewProxy
        let spotlightFrame = proxy[preferenceValue.anchor]
          .insetBy(dx: -config.spotlightPadding, dy: -config.spotlightPadding)
          .offsetBy(dx: proxy.safeAreaInsets.leading, dy: proxy.safeAreaInsets.top)
        let actions = HelpInfoSpotlightOverlayActions(
          dismiss: { self.dismissAction() },
          previous: { self.previousAction(selected: selected, preferences: preferences, scrollViewProxy: scrollViewProxy) },
          next: { self.nextAction(selected: selected, preferences: preferences, scrollViewProxy: scrollViewProxy) }
        )

        ZStack(alignment: .topLeading) {
          spotlightMask(for: spotlightFrame)
            .zIndex(1)
          config.helpInfoGenerator(selected, actions)
            .preferredColorScheme(colorScheme)
            .drawingGroup()
            .onGeometryChange(for: CGSize.self) {
              $0.frame(in: .global).size
            } action: { panelSize in
              self.position = helpInfoPosition(for: spotlightFrame, panelSize: panelSize, in: containerBounds)
            }
            .frame(maxWidth: containerBounds.width - horizontalPadding * 2)
            .position(
              self.position == .zero ? .init(x: containerBounds.midX, y: containerBounds.midY) : self.position)
            .clipped()
            .zIndex(2)
        }
        .opacity(isVisible ? 1 : 0)
        .onAppear {
          withAnimation(.smooth(duration: config.animationDuration)) {
            isVisible = true
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(width: containerBounds.width, height: containerBounds.height)
        .offset(x: -proxy.safeAreaInsets.leading, y: 0)
        .animation(.smooth(duration: config.animationDuration), value: selection)
        .animation(.smooth(duration: config.animationDuration), value: position)
        .onChange(of: pending) {
          // Hack: postpone the update just a tad so that the anchor location will be valid after scrolling. What is a better way?
          Task {
            self.selection = pending
          }
        }
        .ignoresSafeArea()
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) {
          dismissAction()
        }
      }
    } else {
      ZStack(alignment: .topLeading) {
        spotlightMask(for: .init(x: 0, y: 0, width: 0, height: 0))
          .ignoresSafeArea()
      }
      .opacity(isVisible ? 1 : 0)
      .onAppear {
        withAnimation(.smooth(duration: config.animationDuration)) {
          isVisible = false
        }
      }
    }
  }

  func dismissAction() {
    selection = nil
    dismiss()
  }

  func previousAction(selected: ID, preferences: Value, scrollViewProxy: ScrollViewProxy?) {
    if let value = config.previousId(selected: selected, preferences: preferences) {
      scrollViewProxy?.scrollTo(value)
      self.pending = value
    }
  }

  func nextAction(selected: ID, preferences: Value, scrollViewProxy: ScrollViewProxy?) {
    if let value = config.nextId(selected: selected, preferences: preferences) {
      scrollViewProxy?.scrollTo(value)
      self.pending = value
    }
  }

  var spotlightBackingColor: Color {
    colorScheme == .light ? .black : .white
  }

  /**
   Create a composite full-screen image that dims everything but the indicated region. Uses `matchedGeometryEffect` so that the
   spotlight animates from one region to the next. Tapping anywhere in the mask will dismiss the spotlight.

   - parameter focusArea: the area to "punch out" to spotlight an area on the screen.
   - returns: new mask view
   */
  func spotlightMask(for focusArea: CGRect) -> some View {
    ZStack {
      spotlightBackingColor
        .opacity(config.dimmingOpacity)
        .zIndex(3)
      RoundedRectangle(cornerRadius: config.cornerRadius)
        .frame(width: focusArea.width, height: focusArea.height)
        .position(x: focusArea.midX, y: focusArea.midY)
        .matchedGeometryEffect(id: selection, in: spotlightAnimation, properties: .frame, anchor: .center, isSource: false)
        .blur(radius: config.blurRadius)
        .blendMode(.destinationOut)
        .zIndex(4)
    }
    .compositingGroup()
    .contentShape(.rect)
    .onTapGesture {
      dismissAction()
    }
  }

  /**
   Determine a reasonable location for the help info panel which does not obscure the spotlit item and keeps the info panel
   fully on the app display.

   - parameter focusFrame: the frame of the item being spotlit.
   - parameter panelSize: the area of the screen to use for positioning
   - parameter container: the bounds of the view to constrain the placement of the help info view
   - returns: the location to use for the panel
   */
  func helpInfoPosition(for focusFrame: CGRect, panelSize: CGSize, in container: CGRect) -> CGPoint {
    let panelWidth2 = panelSize.width / 2
    let panelHeight2 = panelSize.height / 2

    let centeredX = min(
      max(focusFrame.midX, container.minX + config.horizontalPadding + panelWidth2),
      container.maxX - config.horizontalPadding - panelWidth2
    )

    let preferredBelowY = focusFrame.maxY + config.verticalSeparation + panelHeight2
    let position: CGPoint

    if preferredBelowY + panelHeight2 <= container.maxY - config.verticalPadding {
      position = .init(x: centeredX, y: preferredBelowY)
    } else {
      let preferredAboveY = focusFrame.minY - config.verticalSeparation - panelHeight2
      let clampedY = min(
        max(preferredAboveY, container.minY + config.verticalPadding + panelHeight2),
        container.maxY - config.verticalPadding - panelHeight2
      )
      position = .init(x: centeredX, y: clampedY)
    }

    return position
  }
}

//
//struct BeaconCanvas: View {
//  let regions: [BeaconRegion]
//  let style: BeaconStyle
//  let animation: Animation
//  let coordinator: BeaconCoordinator
//
//  var body: some View {
//    ZStack {
//      ZStack {
//        style.color.opacity(style.opacity)
//          .onTapGesture {
//            coordinator.handleInteraction(.tappedOutside)
//          }
//          .accessibilityLabel("Dismiss spotlight")
//          .accessibilityHint("Double tap to dismiss")
//          .accessibilityAddTraits(.isButton)
//
//        if regions.count == 1, let region = regions.first {
//          AnimatedCutout(
//            frame: region.paddedFrame,
//            cornerRadius: region.cornerRadius,
//            regionId: region.id,
//            animation: animation,
//            coordinator: coordinator
//          )
//        } else {
//          ForEach(regions) { region in
//            StaticCutout(region: region, coordinator: coordinator)
//          }
//        }
//      }
//      .compositingGroup()
//      .ignoresSafeArea()
//
//      ForEach(accessories, id: \.targetId) { accessory in
//        if let region = regions.first(where: { $0.id == accessory.targetId }) {
//          Color.clear
//            .frame(width: region.paddedFrame.width, height: region.paddedFrame.height)
//            .overlay(alignment: accessory.alignment) {
//              DelayedFadeIn {
//                accessory.builder()
//                  .fixedSize()
//                  .offset(x: accessory.offset.width, y: accessory.offset.height)
//                  .allowsHitTesting(false)
//              }
//            }
//            .position(x: region.paddedFrame.midX, y: region.paddedFrame.midY)
//            .animation(animation, value: region.paddedFrame)
//        }
//      }
//    }
//    .ignoresSafeArea()
//    .accessibilityAddTraits(.isModal)
//    .accessibilityAction(.escape) {
//      Beacon.dismiss()
//    }
//  }
//
//  private var accessories: [AccessoryConfiguration] {
//    coordinator.currentPresentation?.accessories ?? []
//  }
//}
//
//private struct DelayedFadeIn<Content: View>: View {
//  @ViewBuilder let content: Content
//  @State private var isVisible = false
//
//  var body: some View {
//    content
//      .opacity(isVisible ? 1 : 0)
//      .onAppear {
//        withAnimation(.easeOut(duration: 0.25).delay(0.35)) {
//          isVisible = true
//        }
//      }
//  }
//}
//
//private struct AnimatedCutout: View {
//  let frame: CGRect
//  let cornerRadius: CGFloat
//  let regionId: String
//  let animation: Animation
//  let coordinator: BeaconCoordinator
//
//  var body: some View {
//    RoundedRectangle(cornerRadius: cornerRadius)
//      .fill(.white)
//      .frame(width: frame.width, height: frame.height)
//      .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
//      .onTapGesture {
//        coordinator.handleInteraction(.tappedRegion(regionId))
//      }
//      .position(x: frame.midX, y: frame.midY)
//      .blendMode(.destinationOut)
//      .animation(animation, value: frame)
//      .animation(animation, value: cornerRadius)
//      .accessibilityLabel("Highlighted element")
//      .accessibilityHint("Double tap to continue")
//      .accessibilityAddTraits(.isButton)
//  }
//}
//
//private struct StaticCutout: View {
//  let region: BeaconRegion
//  let coordinator: BeaconCoordinator
//
//  var body: some View {
//    RoundedRectangle(cornerRadius: region.cornerRadius)
//      .fill(.white)
//      .frame(width: region.paddedFrame.width, height: region.paddedFrame.height)
//      .contentShape(RoundedRectangle(cornerRadius: region.cornerRadius))
//      .onTapGesture {
//        coordinator.handleInteraction(.tappedRegion(region.id))
//      }
//      .position(x: region.paddedFrame.midX, y: region.paddedFrame.midY)
//      .blendMode(.destinationOut)
//      .accessibilityLabel("Highlighted element")
//      .accessibilityHint("Double tap to continue")
//      .accessibilityAddTraits(.isButton)
//  }
//}

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
