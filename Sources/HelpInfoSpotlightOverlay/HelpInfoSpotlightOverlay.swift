// Copyright © 2026 Brad Howes. All rights reserved.
//
// Originally based on code by Artem Mirzabekian -- https://github.com/Livsy90/TutorialSpotlight -- but the architecture and
// feature set is vastly different now.

import SwiftUI

extension View {

  /**
   Install a help info overlay onto the current view.

   - parameter selection: a binding to the state variable that controls which item is under the spotlight.
   - parameter config: the complete configuration for the overlay view and operation.
   - returns: the modified view
   */
  public func helpInfoSpotlightOverlay<ID: Hashable, Overlay: View>(
    selection: Binding<ID?>,
    config: HelpInfoOverlayConfig<ID, Overlay>
  ) -> some View {
    modifier(SpotlightOverlayModifier(selection: selection, config: config))
  }

  /**
   Install a help info overlay onto the current view.

   - parameter selection: a binding to the state variable that controls which item is under the spotlight.
   - parameter orderedIDs: the collection of IDs that indicate the views to show help info for.
   - parameter viewConfig: view configuration used when showing the help info.
   - parameter generator: a view generator that shows the help info text and controls to change the view under the spotlight.
   - parameter placer: optional function that determines where to put the help info overlay in relation to the item under the
   spotlight. The default behavior is found in the `Config.place` method.
   - parameter framer: optional function that generates the frame of the item under the spotlight. The default behavior is found
   in the `Config.frame` method.
   - returns: the modified view
   */
  public func helpInfoSpotlightOverlay<ID: Hashable, Overlay: View>(
    selection: Binding<ID?>,
    orderedIDs: [ID] = [],
    viewConfig: HelpInfoSpotlightOverlayViewConfig = .init(),
    generator: @escaping HelpInfoOverlayConfig<ID, Overlay>.Generator,
    placer: HelpInfoOverlayConfig<ID, Overlay>.Placer? = nil,
    framer: HelpInfoOverlayConfig<ID, Overlay>.Framer? = nil
  ) -> some View where ID: HelpInfoProvider {
    helpInfoSpotlightOverlay(
      selection: selection,
      config: .init(
        orderedIDs: orderedIDs,
        viewConfig: viewConfig,
        generator: generator,
        placer: placer,
        framer: framer,
      )
    )
  }

  /**
   Adds a help info spotlight overlay to a view.

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
  @available(*, deprecated, message: "Use method taking a Config parameter.")
  public func helpInfoSpotlightOverlay<ID: Hashable, Overlay: View>(
    selection: Binding<ID?>,
    orderedIDs: [ID],
    spotlightPadding: CGFloat = 8,
    cornerRadius: CGFloat = 28,
    animationDuration: TimeInterval = 0.65,
    blurRadius: CGFloat = 6.0,
    dimmingOpacity: CGFloat = 0.7,
    scrollToItem: Bool = true,
    windowedMode: HelpInfoSpotlightWindowedMode = .useCustomWindow,
    overlay: @escaping (_ id: ID, _ actions: HelpInfoSpotlightOverlayActions) -> Overlay
  ) -> some View {
    modifier(
      SpotlightOverlayModifier(
        selection: selection,
        config: .init(
          orderedIDs: orderedIDs,
          viewConfig: .init(
            spotlightPadding: spotlightPadding,
            cornerRadius: cornerRadius,
            blurRadius: blurRadius,
            animationDuration: animationDuration,
            lightModeDimmingOpacity: dimmingOpacity,
            darkModeDimmingOpacity: dimmingOpacity,
            scrollToItem: scrollToItem,
            windowedMode: windowedMode
            ),
          generator: { id, actions, _ in overlay(id, actions) }
        )
      )
    )
  }

  /**
   Assign an ID value to a view to indicate that it has help information.

   - parameter id: the value to assign
   - returns: modified view
   */
  public func helpInfoViewTag<ID: Hashable>(id: ID) -> some View {
    modifier(ViewTagModifier(id: id))
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

