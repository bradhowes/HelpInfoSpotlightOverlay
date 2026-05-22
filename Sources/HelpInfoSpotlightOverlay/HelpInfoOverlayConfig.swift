// Copyright © 2026 Brad Howes. All rights reserved.

import SwiftUI

/**
 Container of configuration items and methods to walk collection of help item IDs.
 */
public struct HelpInfoOverlayConfig<ID: Hashable, Overlay: View> {
  typealias AnchorMap = HelpInfoSpotlightOverlayPreferenceKey<ID>.Value

  public typealias Placer = (_ panelSize: CGSize, _ spotlightFrame: CGRect, _ containerBounds: CGRect, _ config: Self) -> CGPoint
  public typealias Framer = (_ id: ID, _ anchor: Anchor<CGRect>, _ proxy: GeometryProxy, _ config: Self) -> CGRect
  public typealias Generator = (ID, HelpInfoSpotlightOverlayActions) -> Overlay

  public var orderedIDs: [ID]
  public var viewConfig: HelpInfoOverlayViewConfig
  public var generator: Generator
  public var placer: Placer?
  public var framer: Framer?

  public init(
    orderedIDs: [ID] = [],
    viewConfig: HelpInfoOverlayViewConfig? = nil,
    generator: @escaping Generator,
    placer: Placer? = nil,
    framer: Framer? = nil
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
  var windowManager: WindowManager<ID, Overlay>? {
#if os(iOS)
    let windowManager: WindowManager<ID, Overlay>? = viewConfig.windowedMode == .useCustomWindow ? .init() : nil
#else
    let windowManager: WindowManager<ID, Overlay>? = nil
#endif
    return windowManager
  }

  /**
   Calculate where to place the help info overlay panel. Preference is to put above or below the spotlight item frame. This is the
   default behavior when there is not a custom `placer` method.

   - parameter panelSize: the dimensions of the overlay panel
   - parameter spotlightFrame: the location and size of the spotlight region
   - parameter containerBounds: the screen bounds available for placing the overlay panel
   - returns: the calculated location to use
   */
  public func calculatePanelPosition(panelSize: CGSize, spotlightFrame: CGRect, containerBounds: CGRect) -> CGPoint {
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

  /**
   Calculate the frame to use for the time in the spotlight. This is the default behavior when there is not a custom `framer`
   methoed.

   - parameter anchor: the anchor of the item in the spotlight.
   - parameter proxy: the proxy to use to obtain geometric values from the anchor
   - returns: the calculate frame to use
   */
  public func calculateItemFrame(anchor: Anchor<CGRect>, proxy: GeometryProxy) -> CGRect {
    proxy[anchor]
      .insetBy(dx: -viewConfig.spotlightPadding, dy: -viewConfig.spotlightPadding)
      .offsetBy(dx: proxy.safeAreaInsets.leading, dy: proxy.safeAreaInsets.top)
  }

  func place(panelSize: CGSize, spotlightFrame: CGRect, containerBounds: CGRect) -> CGPoint {
    if let placer {
      return placer(panelSize, spotlightFrame, containerBounds, self)
    }
    return calculatePanelPosition(panelSize: panelSize, spotlightFrame: spotlightFrame, containerBounds: containerBounds)
  }

  func frame(id: ID, anchor: Anchor<CGRect>, proxy: GeometryProxy) -> CGRect {
    if let framer {
      return framer(id, anchor, proxy, self)
    }

    return calculateItemFrame(anchor: anchor, proxy: proxy)
  }

  static func helpInfoOverlay(for item: ID, actions: HelpInfoSpotlightOverlayActions) -> some View where ID: HelpInfoProvider {
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
