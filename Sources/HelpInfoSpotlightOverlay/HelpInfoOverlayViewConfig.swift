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
  /// Padding applied to the leading and trailing edges of help info overlay view to separate from the containing view edges.
  public var horizontalPadding: CGFloat
  /// Padding applied to the top and bottom edges of help info overlay view to separate from the containing view edges.
  public var verticalPadding: CGFloat
  /// Desired separation between the spotlit view rectangle and the help info overlay view.
  public var verticalSeparation: CGFloat
  /// The duration of animations involving the overlays.
  public var animationDuration: TimeInterval
  /// Opacity to apply to the masking overlay that covers the display apart from the spotlight region.
  public var lightModeDimmingOpacity: CGFloat
  /// The color to use to fill the masking overlay when in light mode.
  public var lightModeMaskColor: Color
  /// Opacity to apply to the masking overlay that covers the display apart from the spotlight region.
  public var darkModeDimmingOpacity: CGFloat
  /// The color to use to fill the masking overlay when in dark mode.
  public var darkModeMaskColor: Color
  /// When `true` performa a `scrollTo` on the item being spotlit in order to place it fully on the screen.
  public var scrollToItem: Bool
  /// Controls whether a custom window holds the overlay. Improves rendering results when enabled.
  public var windowedMode: HelpInfoSpotlightWindowedMode

  public init(
    spotlightPadding: CGFloat = 8.0,
    cornerRadius: CGFloat = 28.0,
    blurRadius: CGFloat = 6.0,
    horizontalPadding: CGFloat = 16.0,
    verticalPadding: CGFloat = 24.0,
    verticalSeparation: CGFloat = 24.0,
    animationDuration: TimeInterval = 0.65,
    lightModeDimmingOpacity: CGFloat = 0.7,
    lightModeMaskColor: Color = .black,
    darkModeDimmingOpacity: CGFloat = 0.8,
    darkModeMaskColor: Color = .white.mix(with: .black, by: 0.8),
    scrollToItem: Bool = true,
    windowedMode: HelpInfoSpotlightWindowedMode = .useCustomWindow
  ) {
    self.spotlightPadding = spotlightPadding
    self.cornerRadius = cornerRadius
    self.blurRadius = blurRadius
    self.horizontalPadding = horizontalPadding
    self.verticalPadding = verticalPadding
    self.verticalSeparation = verticalSeparation
    self.animationDuration = animationDuration
    self.lightModeDimmingOpacity = lightModeDimmingOpacity
    self.lightModeMaskColor = lightModeMaskColor
    self.darkModeDimmingOpacity = darkModeDimmingOpacity
    self.darkModeMaskColor = darkModeMaskColor
    self.scrollToItem = scrollToItem
    self.windowedMode = windowedMode
  }
}
