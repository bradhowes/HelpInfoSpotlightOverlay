// Copyright © 2026 Brad Howes. All rights reserved.

import SwiftUI

/**
 View that shows the spotlight overlay mask and the information card with text about the item in the spotlight.
 */
struct SpotlightOverlay<ID: Hashable, Overlay: View>: View {
  typealias AnchorMap = IDAnchorPreferenceKey<ID>.Value

  @Binding private var selection: ID?
  @State private var pending: ID?
  @State private var position: CGPoint = .zero

  private let animationNamespace: Namespace.ID
  private let config: HelpInfoOverlayConfig<ID, Overlay>
  private let anchors: AnchorMap
  private let geometryProxy: GeometryProxy
  private let scrollViewProxy: ScrollViewProxy?
  private let selected: ID
  private let anchor: Anchor<CGRect>
  private let dismissAction: () -> Void

  @Environment(\.colorScheme) private var colorScheme

  private var containerBounds: CGRect { geometryProxy.containerBounds }
  private var spotlightFrame: CGRect { config.frame(id: selected, anchor: anchor, proxy: geometryProxy) }

  var actions: HelpInfoSpotlightOverlayActions {
    .init(
      dismiss: self.dismissAction,
      previous: { self.previousAction(selected: selected, anchors: anchors, scrollViewProxy: scrollViewProxy) },
      next: { self.nextAction(selected: selected, anchors: anchors, scrollViewProxy: scrollViewProxy) }
    )
  }

  init(
    selection: Binding<ID?>,
    animationNamespace: Namespace.ID,
    config: HelpInfoOverlayConfig<ID, Overlay>,
    anchors: [ID: Anchor<CGRect>],
    geometryProxy: GeometryProxy,
    scrollViewProxy: ScrollViewProxy?,
    selected: ID,
    anchor: Anchor<CGRect>,
    dismissAction: @escaping () -> Void
  ) {
    self._selection = selection
    self.animationNamespace = animationNamespace
    self.config = config
    self.anchors = anchors
    self.geometryProxy = geometryProxy
    self.scrollViewProxy = scrollViewProxy
    self.selected = selected
    self.anchor = anchor
    self.dismissAction = dismissAction
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      // The mask that dims everything on the screen but the item being focused on.
      spotlightMask
        .zIndex(1)

      // The information card that shows the help info for the item being focused on.
      config.generator(selected, actions, colorScheme)
        // Generate image from view for proper animation of contents when the view moves and resizes.
        .drawingGroup()
        .onGeometryChange(for: CGSize.self) {
          $0.frame(in: .named(SpotlightCoordinateSpace.name)).size
        } action: { panelSize in
          self.position = config.place(panelSize: panelSize, spotlightFrame: spotlightFrame, containerBounds: containerBounds)
        }
        .frame(maxWidth: containerBounds.width - config.viewConfig.horizontalPadding * 2)
        .position(self.position == .zero ? .init(x: containerBounds.midX, y: containerBounds.midY) : self.position)
        .clipped()
        .zIndex(2)
    }
    .frame(width: containerBounds.width, height: containerBounds.height)
    .offset(x: -geometryProxy.safeAreaInsets.leading, y: -geometryProxy.safeAreaInsets.top)
    .animation(.smooth(duration: config.viewConfig.animationDuration), value: position)
    .onChange(of: pending) {
      // Postpone the update just a tad so that the anchor location will be valid after scrolling.
      // This is a hack until we can figure out how to animate the scrollTo and have valid anchor geometries.
      // (see https://github.com/bradhowes/HelpInfoSpotlightOverlay/issues/2)
      Task {
        self.selection = pending
      }
    }
  }

  private func setPending(_ value: ID) {
    if self.pending != value {
      scrollViewProxy?.scrollTo(value)
      self.pending = value
    }
  }

  private func previousAction(selected: ID, anchors: AnchorMap, scrollViewProxy: ScrollViewProxy?) {
    if let value = config.previousId(selected: selected, anchors: anchors) {
      setPending(value)
    }
  }

  private func nextAction(selected: ID, anchors: AnchorMap, scrollViewProxy: ScrollViewProxy?) {
    if let value = config.nextId(selected: selected, anchors: anchors) {
      setPending(value)
    }
  }

  /**
   Create the masking layer that dims the main view except for the region under the spotlight.
   */
  private var spotlightMask: some View {
    ZStack {

      // The mask that dims everything on the screen.
      spotlightBackingColor
        .opacity(dimmingOpacity)
        .zIndex(3)

      // The region that shows the item to spotlight.
      RoundedRectangle(cornerRadius: config.viewConfig.cornerRadius)
        .frame(width: spotlightFrame.width, height: spotlightFrame.height)
        .position(x: spotlightFrame.midX, y: spotlightFrame.midY)
        .blur(radius: config.viewConfig.blurRadius)
        .blendMode(.destinationOut)
        .zIndex(4)
    }
    .compositingGroup()
    .contentShape(Rectangle())
    .onTapGesture {
      dismissAction()
    }
  }

  private var dimmingOpacity: CGFloat {
    colorScheme == .light ? config.viewConfig.lightModeDimmingOpacity : config.viewConfig.darkModeDimmingOpacity
  }

  private var spotlightBackingColor: Color {
    colorScheme == .light ? config.viewConfig.lightModeMaskColor : config.viewConfig.darkModeMaskColor
  }
}
