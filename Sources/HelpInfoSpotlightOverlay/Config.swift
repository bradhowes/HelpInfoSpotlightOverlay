// Copyright © 2026 Brad Howes. All rights reserved.

import SwiftUI

public struct ViewConfig {
  public var spotlightPadding: CGFloat
  public var cornerRadius: CGFloat
  public var blurRadius: CGFloat
  public var dimmingOpacity: CGFloat
  /// Padding applied to the leading and trailing edges of help info overlay view to separate from the containing view edges.
  public var horizontalPadding: CGFloat
  /// Padding applied to the top and bottom edges of help info overlay view to separate from the containing view edges.
  public var verticalPadding: CGFloat
  /// Desired separation between the spotlit view rectangle and the help info overlay view.
  public var verticalSeparation: CGFloat
  public var animationDuration: TimeInterval
  public var scrollToItem: Bool
  public var windowedMode: WindowedMode

  public init(
    spotlightPadding: CGFloat = 8.0,
    cornerRadius: CGFloat = 28.0,
    blurRadius: CGFloat = 6.0,
    dimmingOpacity: CGFloat = 0.7,
    horizontalPadding: CGFloat = 16.0,
    verticalPadding: CGFloat = 24.0,
    verticalSeparation: CGFloat = 24.0,
    animationDuration: TimeInterval = 0.65,
    scrollToItem: Bool = true,
    windowedMode: WindowedMode = .useCustomWindow,
  ) {
    self.spotlightPadding = spotlightPadding
    self.cornerRadius = cornerRadius
    self.blurRadius = blurRadius
    self.dimmingOpacity = dimmingOpacity
    self.horizontalPadding = horizontalPadding
    self.verticalPadding = verticalPadding
    self.verticalSeparation = verticalSeparation
    self.animationDuration = animationDuration
    self.scrollToItem = scrollToItem
    self.windowedMode = windowedMode
  }
}

/**
 Container of configuration items and methods to walk collection of help item IDs.
 */
public struct Config<ID: Hashable, Overlay: View> {
  typealias AnchorMap = HelpInfoSpotlightOverlayPreferenceKey<ID>.Value

  public var orderedIDs: [ID]
  public let viewConfig: ViewConfig

  /**
   Determine a reasonable location for the help info panel which does not obscure the spotlit item and keeps the info panel
   fully on the app display.

   - parameter panelSize: the area of the screen to use for positioning
   - returns: the location to use for the panel
   */
  public typealias Placer = (_ panelSize: CGSize, _ spotlightFrame: CGRect, _ containerBounds: CGRect, _ viewConfig: ViewConfig) -> CGPoint

  public typealias Framer = (_ id: ID, _ anchor: Anchor<CGRect>, _ proxy: GeometryProxy, _ ViewConfig: ViewConfig) -> CGRect

  public typealias Generator = (ID, HelpInfoSpotlightOverlayActions) -> Overlay

  public var placer: Placer?
  public var framer: Framer?
  public var generator: Generator?

  public init(
    orderedIDs: [ID] = [],
    viewConfig: ViewConfig? = nil,
    placer: Placer? = nil,
    framer: Framer? = nil,
    generator: Generator? = nil
  ) {
    self.orderedIDs = orderedIDs
    self.viewConfig = viewConfig ?? .init()
    self.placer = placer
    self.framer = framer
    self.generator = generator
  }

  /**
   Move to the previous help info item ID, skipping over items that are not found in the view.

   - parameter selected: the current ID
   - parameter anchors: the mapping of IDs to view anchors
   - returns: the new ID to select, or nil if none found.
   */
  func previousId(selected: ID, anchors: AnchorMap) -> ID? {
    if var index = orderedIDs.firstIndex(of: selected) {
      for _ in 0..<orderedIDs.count {
        index = index == orderedIDs.startIndex ? orderedIDs.endIndex - 1 : orderedIDs.index(before: index)
        let candidate = orderedIDs[index]
        if anchors[candidate] != nil {
          return candidate
        }
      }
    }
    return nil
  }

  /**
   Move to the next help info item ID, skipping over items that are not found in the view.

   - parameter selected: the current ID
   - parameter anchors: the mapping of IDs to view anchors
   - returns: the new ID to select, or nil if none found.
   */
  func nextId(selected: ID, anchors: AnchorMap) -> ID? {
    if var index = orderedIDs.firstIndex(of: selected) {
      for _ in 0..<orderedIDs.count {
        index = index == orderedIDs.endIndex - 1 ? orderedIDs.startIndex : orderedIDs.index(after: index)
        let candidate = orderedIDs[index]
        if anchors[candidate] != nil {
          return candidate
        }
      }
    }
    return nil
  }

  @MainActor
  func place(
    panelSize: CGSize,
    spotlightFrame: CGRect,
    containerBounds: CGRect,
  ) -> CGPoint {
    if let placer {
      return placer(panelSize, spotlightFrame, containerBounds, viewConfig)
    }

    let panelWidth2 = panelSize.width / 2
    let panelHeight2 = panelSize.height / 2

    let centeredX = min(
      max(spotlightFrame.midX, containerBounds.minX + viewConfig.horizontalPadding + panelWidth2),
      containerBounds.maxX - viewConfig.horizontalPadding - panelWidth2
    )

    let preferredBelowY = spotlightFrame.maxY + viewConfig.verticalSeparation + panelHeight2
    let position: CGPoint

    if preferredBelowY + panelHeight2 <= containerBounds.maxY - viewConfig.verticalPadding {
      position = .init(x: centeredX, y: preferredBelowY)
    } else {
      let preferredAboveY = spotlightFrame.minY - viewConfig.verticalSeparation - panelHeight2
      let clampedY = min(
        max(preferredAboveY, containerBounds.minY + viewConfig.verticalPadding + panelHeight2),
        containerBounds.maxY - viewConfig.verticalPadding - panelHeight2
      )
      position = .init(x: centeredX, y: clampedY)
    }

    return position
  }

  func frame(id: ID, anchor: Anchor<CGRect>, proxy: GeometryProxy, viewConfig: ViewConfig) -> CGRect {
    if let framer {
      return framer(id, anchor, proxy, viewConfig)
    }

    return proxy[anchor]
      .insetBy(dx: -viewConfig.spotlightPadding, dy: -viewConfig.spotlightPadding)
      .offsetBy(dx: proxy.safeAreaInsets.leading, dy: proxy.safeAreaInsets.top)
  }

  func generate(id: ID, actions: HelpInfoSpotlightOverlayActions) -> some View {
    Group {
      if let generator {
        generator(id, actions)
      } else {
        Text("Missing")
      }
    }
  }

  func helpInfoOverlay(for item: ID, actions: HelpInfoSpotlightOverlayActions) -> some View where ID: HelpInfoProvider {
    VStack(spacing: 16) {
      HelpInfoLayout {
        Text(item.title)
          .font(.title3.weight(.bold))
          .contentTransition(.opacity)
        Text(item.text)
          .foregroundStyle(.secondary)
          .contentTransition(.opacity)
      }
      .overlay(alignment: .topTrailing) {
        Button {
          actions.dismiss()
        } label: {
          Image(systemName: "xmark")
        }
        .accessibilityLabel("exit")
        .accessibilityHint("Double tap to quit help spotlight")
      }
      HStack(spacing: 24) {
        Button {
          actions.previous()
        } label: {
          Image(systemName: "arrowshape.left.fill")
        }
        .accessibilityLabel("previous")
        .accessibilityHint("Double tap to go to previous help item")
        Button {
          actions.next()
        } label: {
          Image(systemName: "arrowshape.right.fill")
        }
        .accessibilityLabel("next")
        .accessibilityHint("Double tap to go to next help item")
      }
      .fontWeight(.semibold)
    }
    .padding(20)
    .background {
      RoundedRectangle(cornerRadius: 28)
        .fill(.background)
    }
  }
}
