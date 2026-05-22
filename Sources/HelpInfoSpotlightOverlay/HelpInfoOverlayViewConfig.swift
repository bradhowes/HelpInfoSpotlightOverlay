// Copyright © 2026 Brad Howes. All rights reserved.

import SwiftUI

/**
 Collection of attributes that affects the behavior and appearance of the help info overlays.
 */
public struct HelpInfoOverlayViewConfig {
  /// The amount of padding added to the spotlight centered on the current item.
  public var spotlightPadding: CGFloat
  /// The corner radius applied to spotlight framing rectangle.
  public var cornerRadius: CGFloat
  /// The amount of blurring to apply to the edge of the spotlight frame.
  public var blurRadius: CGFloat
  /// Opacity to apply to the overlay covering the display apart from the spotlight region.
  public var dimmingOpacity: CGFloat
  /// Padding applied to the leading and trailing edges of help info overlay view to separate from the containing view edges.
  public var horizontalPadding: CGFloat
  /// Padding applied to the top and bottom edges of help info overlay view to separate from the containing view edges.
  public var verticalPadding: CGFloat
  /// Desired separation between the spotlit view rectangle and the help info overlay view.
  public var verticalSeparation: CGFloat
  /// The duration of animations involving the overlays.
  public var animationDuration: TimeInterval
  /// When `true` performa a `scrollTo` on the item being spotlit in order to place it fully on the screen.
  public var scrollToItem: Bool
  /// Controls whether a custom window holds the overlay. Improves rendering results when enabled.
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
