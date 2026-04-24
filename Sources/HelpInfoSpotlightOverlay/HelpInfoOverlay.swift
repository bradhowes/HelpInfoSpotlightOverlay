// Copyright © 2026 Brad Howes. All rights reserved.

import SwiftUI

/**
 Example definition of an overlay that presents the help information for a view tagged by ``helpInfoViewTag``. This can be used if
 the `ID` generic implements ``HelpInfoProvider``.

 - parameter item: the ID of the view being spotlit.
 - parameter actions: the collection of actions for buttons in the overlay view
 - returns: overlay view
 */
@MainActor
public func helpInfoOverlay<ID: Hashable & HelpInfoProvider>(for item: ID, actions: HelpInfoSpotlightOverlayActions) -> some View {
  @Environment(\.colorScheme) var colorScheme
  return VStack(spacing: 16) {
    HelpInfoLayout {
      Text(item.title)
        .font(.title3.weight(.bold))
      Text(item.text)
        .foregroundStyle(.secondary)
    }
    .overlay(alignment: .topTrailing) {
      Button {
        actions.dismiss()
      } label: {
        Image(systemName: "xmark")
      }
    }
    HStack(spacing: 24) {
      Button {
        actions.previous()
      } label: {
        Image(systemName: "arrowshape.left.fill")
      }
      Button {
        actions.next()
      } label: {
        Image(systemName: "arrowshape.right.fill")
      }
    }
    .fontWeight(.semibold)
  }
  .padding(20)
  .background {
    RoundedRectangle(cornerRadius: 28)
      .fill(.background)
  }
  .shadow(color: (colorScheme == .dark ? Color.white : .black).opacity(0.20), radius: 24, y: 12)
}

