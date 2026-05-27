import SwiftUI

/**
 View modifier that handles the display of a spotlight on a help item.

 See ``helpInfoSpotlightOverlay`` View modifier for details.
 */
struct SpotlightOverlayModifier<ID: Hashable, Overlay: View>: ViewModifier {
  typealias AnchorMap = IDAnchorPreferenceKey<ID>.Value

  @Binding private var selection: ID?
  private let config: HelpInfoOverlayConfig<ID, Overlay>
  @State private var windowManager: WindowManager<ID, Overlay>?
  @Namespace private var animationNamespace
  @Environment(\.colorScheme) private var colorScheme

  init(
    selection: Binding<ID?>,
    config: HelpInfoOverlayConfig<ID, Overlay>
  ) {
    self._selection = selection
    self.config = config
    self._windowManager = .init(initialValue: config.windowManager)
  }

  func body(content: Content) -> some View {
    if config.viewConfig.scrollToItem {
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
      .coordinateSpace(.named(SpotlightCoordinateSpace.name))
      .helpInfoSpotlightAnimationNamespace(animationNamespace)
      .overlayPreferenceValue(IDAnchorPreferenceKey<ID>.self) { anchors in
        spotlightOverlayContent(anchors: anchors, scrollViewProxy: scrollViewProxy)
      }
      .animation(.smooth(duration: config.viewConfig.animationDuration), value: selection)
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
    scrollViewProxy: ScrollViewProxy? = nil
  ) -> some View {
    if let selected = selection, let anchor = anchors[selected] {
      if let windowManager {

        // When using a top-level window to host the spotlight overlay, this creates and show the window and its overlay view.
        // The window is only created once, but it can receive updates to the anchors if/when they change due to scrolling. As such,
        // this method can be called multiple times while the overlay is up.
        windowManager.show(
          selection: $selection,
          config: config,
          anchors: anchors,
          scrollViewProxy: scrollViewProxy,
          animationNamespace: animationNamespace,
          colorScheme: colorScheme
        )
      } else {
        // Embed the spotlight overlay the the current view hierarchy. Note that this may not lead to great rendering results when
        // compared to windowed mode.
        GeometryReader { geometryProxy in
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
      }
    } else {
      EmptyView()
    }
  }
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
