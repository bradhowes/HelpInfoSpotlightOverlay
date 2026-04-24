// Copyright © 2026 Brad Howes. All rights reserved.

/**
 Collection of actions available in a help spotlight info panel overlay.
 */
public struct HelpInfoSpotlightOverlayActions {
  /// Closes the spotlight flow and removes the overlay.
  public let dismiss: () -> Void
  /// Move to the previous item in `orderedIDs`. Skips over items that are not found in the collection of registered views.
  public let previous: () -> Void
  /// Move to the next item in `orderedIDs`. Skips over items that are not found in the collection of registered views.
  public let next: () -> Void
}

