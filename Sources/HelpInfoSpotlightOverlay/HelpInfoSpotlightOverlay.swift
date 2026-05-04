// Copyright © 2026 Brad Howes. All rights reserved.
//
// Based on code by Artem Mirzabekian -- https://github.com/Livsy90/TutorialSpotlight

import SwiftUI

public enum WindowedMode {
  case useCustomWindow
  case none
}

extension View {

  /**
   Adds a help item spotlight overlay to a view.

   The overlay appears when the given binding holds a non-nil value. The items that are highlighted must be tagged with the
   ``helpInfoViewTag(_:)`` view modifier. The spotlight overlay consists of two visual components:

   - a 'spotlight' that visually focuses attention to an item in the display
   - an info panel that shows help content for the item being spotlit

   The caller provides a view builder that generates the view that shows the help content for the item being spotlit. The view
   builder is called by the `HelpInfoSpotlightOverlay` code with the ID of the current item, and a collection of "actions" that the
   view builder must use to navigate to the next or previous item, or to dismiss the spotlight activity.

   - parameter selection: binding to use to control activation of spotlight and the item to highlight.
   - parameter orderedIDs: collection of unique values to cycle through to highlight.
   - parameter spotlightPadding: padding to apply to the spotlight overlay.
   - parameter cornerRadius: corner radius to apply to the spotlight overlay.
   - parameter animationDuration: the duration of animations involving the help item spotlight.
   - parameter blurRadius: the amount of blur applied to the spotlight region.
   - parameter dimmingOpacity: the amount of dimming applied to the whole app except the area being spotlit.
   - parameter scrollToItem: attempt to make the item so spotlite visible by scrolling to it. Enabled by default, but it can be
   disabled if causing issues.
   - parameter windowedMode: if `useCustomWindow` manage overlays in a new `UIWindow` shown during help spotlighting. This is now
   the default as it offers better rendering results.
   - parameter overlay: view builder that constructs the info panel to show with the help text.
   */
  public func helpInfoSpotlightOverlay<ID: Hashable, Overlay: View>(
    selection: Binding<ID?>,
    orderedIDs: [ID],
    spotlightPadding: CGFloat = 8,
    cornerRadius: CGFloat = 28,
    animationDuration: TimeInterval = 0.6,
    blurRadius: CGFloat = 6.0,
    dimmingOpacity: CGFloat = 0.8,
    scrollToItem: Bool = true,
    windowedMode: WindowedMode = .useCustomWindow,
    @ViewBuilder overlay: @escaping (_ id: ID, _ actions: HelpInfoSpotlightOverlayActions) -> Overlay
  ) -> some View {
    modifier(
      HelpInfoSpotlightOverlayModifier(
        selection: selection,
        config: .init(
          orderedIDs: orderedIDs,
          spotlightPadding: spotlightPadding,
          cornerRadius: cornerRadius,
          animationDuration: animationDuration,
          blurRadius: blurRadius,
          dimmingOpacity: dimmingOpacity,
          scrollToItem: scrollToItem,
          windowedMode: windowedMode,
          helpInfoGenerator: overlay
        ),
        windowManager: windowedMode == .useCustomWindow ? .init() : nil
      )
    )
  }

  /**
   Assign an ID value to a view to indicate that it has help information.

   - parameter id: the value to assign
   - returns: modified view
   */
  public func helpInfoViewTag<ID: Hashable>(id: ID) -> some View {
    modifier(HelpInfoViewTagModifier(id: id))
  }
}

/**
 View modifier that handles the display of a spotlight on a help item.

 See ``helpInfoSpotlightOverlay`` View modifier for details.
 */
private struct HelpInfoSpotlightOverlayModifier<ID: Hashable, Overlay: View>: ViewModifier {
  typealias AnchorMap = HelpInfoSpotlightOverlayPreferenceKey<ID>.Value

  @Binding var selection: ID?
  let config: Config<ID, Overlay>
  let windowManager: WindowManager<ID, Overlay>?
  @Namespace private var animationNamespace
  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    if config.scrollToItem {
      ScrollViewReader { scrollViewProxy in
        contentModifier(content, scrollViewProxy: scrollViewProxy)
      }
    } else {
      contentModifier(content, scrollViewProxy: nil)
    }
  }

  /**
   Inject the mapping of help item IDs and their anchor geometries into an overlay view.

   - parameter content: the view being modified
   - parameter scrollViewProxy: the `ScrollViewProxy` to use to make an item visible on the screen.
   - returns: modified view
   */
  private func contentModifier(_ content: Content, scrollViewProxy: ScrollViewProxy?) -> some View {
    content
      .coordinateSpace(.named(HelpInfoSpotlightCoordinateSpace.name))
      .helpInfoSpotlightAnimationNamespace(animationNamespace)
      .overlayPreferenceValue(HelpInfoSpotlightOverlayPreferenceKey<ID>.self) { anchors in
        GeometryReader { geometryProxy in
          spotlightOverlayContent(anchors: anchors, geometryProxy: geometryProxy, scrollViewProxy: scrollViewProxy)
        }
      }
      .animation(.smooth(duration: config.animationDuration), value: selection)
  }
  /**
   Create the spotlight view to hilight an item in the UI and show help text for it.

   This is the main entry point for spotlight overlay. As the ``selection`` value changes, the spotlight will move to the new view,
   and the contents of the info view will change to show the help text for the new view.

   - parameter anchors: the collection of known UI elements with `Anchor<CGRect>` values.
   - parameter geometryProxy: a `GeometryProxy` to use to obtain frame values from the anchors.
   - parameter scrollViewProxy: a `ScrollViewProxy` to use to scroll help items into view.
   - returns: new view made up of a spotlight mask and a info view overlay containing the help text for the active item.
   */
  @ViewBuilder
  private func spotlightOverlayContent(
    anchors: AnchorMap,
    geometryProxy: GeometryProxy,
    scrollViewProxy: ScrollViewProxy? = nil
  ) -> some View {
    if let selected = selection, let anchor = anchors[selected] {
      if let windowManager {

        // When using a top-level window to host the spotlight overlay, we need to create and show the window and its overlay view.
        // The window is only created once, but it can receive updates to the anchors if/when they change due to scrolling.
        let _ = windowManager.show(
          selection: $selection,
          config: config,
          anchors: anchors,
          scrollViewProxy: scrollViewProxy,
          animationNamespace: animationNamespace
        )
        // The top-level window is showing the spotlight overlay, so nothing to inject here.
        EmptyView()
      } else {
        // Embed the spotlight overlay the the current view hierarchy. Note that this may not lead to great rendering results when
        // compared to windowed mode.
        SpotlightOverlay(
          selection: $selection,
          animationNamespace: animationNamespace,
          config: config,
          anchors: anchors,
          geometryProxy: geometryProxy,
          scrollViewProxy: scrollViewProxy,
          selected: selected,
          anchor: anchor,
          dismissAction: {
            self.selection = nil
          }
        )
      }
    } else {
      EmptyView()
    }
  }
}

/**
 View that shows the spotlight overlay mask and the information card with text about the item in the spotlight.
 */
struct SpotlightOverlay<ID: Hashable, Overlay: View>: View {
  typealias AnchorMap = HelpInfoSpotlightOverlayPreferenceKey<ID>.Value

  @Binding var selection: ID?
  @State var pending: ID?
  @State var position: CGPoint = .zero
  let animationNamespace: Namespace.ID

  let config: Config<ID, Overlay>
  let anchors: AnchorMap
  let geometryProxy: GeometryProxy
  let scrollViewProxy: ScrollViewProxy?
  let selected: ID
  let anchor: Anchor<CGRect>
  let dismissAction: () -> Void

  @Environment(\.colorScheme) private var colorScheme

  var containerBounds: CGRect { geometryProxy.containerBounds }
  var spotlightFrame: CGRect {
    geometryProxy[anchor]
      .insetBy(dx: -config.spotlightPadding, dy: -config.spotlightPadding)
      .offsetBy(dx: geometryProxy.safeAreaInsets.leading, dy: geometryProxy.safeAreaInsets.top)
  }
  var actions: HelpInfoSpotlightOverlayActions {
    .init(
      dismiss: self.dismissAction,
      previous: { self.previousAction(selected: selected, anchors: anchors, scrollViewProxy: scrollViewProxy) },
      next: { self.nextAction(selected: selected, anchors: anchors, scrollViewProxy: scrollViewProxy) }
    )
  }

  var body: some View {
    ZStack(alignment: .topLeading) {

      // The mask that dims everything on the screen but the item being focused on.
      SpotlightMask(
        config: config,
        selection: selected,
        focusArea: spotlightFrame,
        animationNamespace: animationNamespace,
        dismissAction: actions.dismiss
      ).zIndex(1)

      // The information card that shows the help info for the item being focused on.
      config.helpInfoGenerator(selected, actions)
        .preferredColorScheme(colorScheme)
        .drawingGroup()
        .onGeometryChange(for: CGSize.self) {
          $0.frame(in: .named(HelpInfoSpotlightCoordinateSpace.name)).size
        } action: { panelSize in
          self.position = helpInfoPosition(for: spotlightFrame, panelSize: panelSize, in: containerBounds)
        }
        .frame(maxWidth: containerBounds.width - config.horizontalPadding * 2)
        .position(
          self.position == .zero ? .init(x: containerBounds.midX, y: containerBounds.midY) : self.position)
        .clipped()
        .zIndex(2)
    }
    .frame(width: containerBounds.width, height: containerBounds.height)
    .offset(x: -geometryProxy.safeAreaInsets.leading, y: -geometryProxy.safeAreaInsets.top)
    .animation(.smooth(duration: config.animationDuration), value: position)
    .onChange(of: pending) {
      // Postpone the update just a tad so that the anchor location will be valid after scrolling.
      Task {
        self.selection = pending
      }
    }
  }

  private func previousAction(selected: ID, anchors: AnchorMap, scrollViewProxy: ScrollViewProxy?) {
    if let value = config.previousId(selected: selected, anchors: anchors) {
      scrollViewProxy?.scrollTo(value)
      self.pending = value
    }
  }

  private func nextAction(selected: ID, anchors: AnchorMap, scrollViewProxy: ScrollViewProxy?) {
    if let value = config.nextId(selected: selected, anchors: anchors) {
      scrollViewProxy?.scrollTo(value)
      self.pending = value
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
  private func helpInfoPosition(for focusFrame: CGRect, panelSize: CGSize, in container: CGRect) -> CGPoint {
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

/**
 Create a composite full-screen image that dims everything but the indicated region. Uses `matchedGeometryEffect` so that the
 spotlight animates from one region to the next. Tapping anywhere in the mask will dismiss the spotlight.
 */
struct SpotlightMask<ID: Hashable, Overlay: View>: View {
  let config: Config<ID, Overlay>
  let selection: ID?
  let focusArea: CGRect
  let animationNamespace: Namespace.ID
  let dismissAction: () -> Void

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    ZStack {

      // The mask that dims everything on the screen.
      spotlightBackingColor
        .opacity(config.dimmingOpacity)
        .zIndex(3)

      // The region that shows the item to spotlight.
      RoundedRectangle(cornerRadius: config.cornerRadius)
        .frame(width: focusArea.width, height: focusArea.height)
        .position(x: focusArea.midX, y: focusArea.midY)
        .matchedGeometryEffect(id: selection, in: animationNamespace, properties: .frame, anchor: .center, isSource: false)
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

  private var spotlightBackingColor: Color {
    colorScheme == .light ? .black : .white
  }
}

/**
 Mapping of view help item ID tags and view anchor geometries made available via SwiftUI preferences system. These are used by the
 spotlight overlays to move from item to item in the view hiearchy.
 */
struct HelpInfoSpotlightOverlayPreferenceKey<ID: Hashable>: PreferenceKey {
  typealias Value = [ID: Anchor<CGRect>]

  static var defaultValue: Value { [:] }

  static func reduce(value: inout Value, nextValue: () -> Value) {
    value.merge(nextValue()) { (_, new) in new }
  }
}

/**
 View modifier that adds a help item preference value.

 Use `transformAnchorPreference` so that containers do not shadow entities they hold. Since the default value is an empty
 dictionary, this is also safe to use for non-container views.

 Note that during tests, it is possible that `namespace` is not installed, thus the need to conditionally apply the
 `matchedGeometryEffect` modifier.
 */
private struct HelpInfoViewTagModifier<ID: Hashable>: ViewModifier {
  let id: ID
  @Environment(\.helpInfoSpotlightAnimationNamespace) private var namespace

  func body(content: Content) -> some View {
    if let namespace = namespace {
      content
        .matchedGeometryEffect(id: id, in: namespace, properties: .frame, anchor: .center, isSource: true)
        .transformAnchorPreference(key: HelpInfoSpotlightOverlayPreferenceKey<ID>.self, value: .bounds) {
          $0[id] = $1
        }
        .id(id)
    } else {
      content
        .transformAnchorPreference(key: HelpInfoSpotlightOverlayPreferenceKey<ID>.self, value: .bounds) {
          $0[id] = $1
        }
        .id(id)
    }
  }
}

private enum HelpInfoSpotlightCoordinateSpace {
  // Shared coordinate space name used by spotlight sources and the container.
  static let name = "HelpInfoSpotlightCoordinateSpace"
}

extension GeometryProxy {

  var containerBounds: CGRect {
    .init(
      origin: .zero,
      size: .init(
        width: size.width + safeAreaInsets.leading + safeAreaInsets.trailing,
        height: size.height + safeAreaInsets.top + safeAreaInsets.bottom
      )
    )
  }
}

private struct HelpInfoSpotlightNamespaceEnvironmentKey: EnvironmentKey {
  fileprivate static var defaultValue: Namespace.ID? { nil }
}

extension EnvironmentValues {

  /// Custom EnvironmentValues property that provides the help spotlight animation namespace.
  fileprivate var helpInfoSpotlightAnimationNamespace: Namespace.ID? {
    get { self[HelpInfoSpotlightNamespaceEnvironmentKey.self] }
    set { self[HelpInfoSpotlightNamespaceEnvironmentKey.self] = newValue }
  }
}

extension View {

  fileprivate func helpInfoSpotlightAnimationNamespace(_ value: Namespace.ID) -> some View {
    environment(\.helpInfoSpotlightAnimationNamespace, value)
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
