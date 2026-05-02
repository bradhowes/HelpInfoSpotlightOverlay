// Copyright © 2026 Brad Howes. All rights reserved.

import SwiftUI

/**
 Container of configuration items and methods to walk collection of help item IDs.
 */
struct Config<ID: Hashable, Overlay: View> {
  typealias Value = HelpInfoSpotlightOverlayPreferenceKey<ID>.Value

  let orderedIDs: [ID]
  let spotlightPadding: CGFloat
  let cornerRadius: CGFloat
  let animationDuration: TimeInterval
  let blurRadius: CGFloat
  let dimmingOpacity: CGFloat
  let scrollToItem: Bool
  let windowedMode: WindowedMode
  let helpInfoGenerator: (ID, HelpInfoSpotlightOverlayActions) -> Overlay

  let horizontalPadding: CGFloat = 16
  let verticalSeparation: CGFloat = 24
  let verticalPadding: CGFloat = 24

  func previousId(selected: ID, preferences: Value) -> ID? {
    if var index = orderedIDs.firstIndex(of: selected) {
      for _ in 0..<orderedIDs.count {
        index = index == orderedIDs.startIndex ? orderedIDs.endIndex - 1 : orderedIDs.index(before: index)
        let candidate = orderedIDs[index]
        if preferences[candidate] != nil {
          return candidate
        }
      }
    }
    return nil
  }

  func nextId(selected: ID, preferences: Value) -> ID? {
    if var index = orderedIDs.firstIndex(of: selected) {
      for _ in 0..<orderedIDs.count {
        index = index == orderedIDs.endIndex - 1 ? orderedIDs.startIndex : orderedIDs.index(after: index)
        let candidate = orderedIDs[index]
        if preferences[candidate] != nil {
          return candidate
        }
      }
    }
    return nil
  }
}

