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
@ViewBuilder
public func helpInfoOverlay<ID: Hashable & HelpInfoProvider>(for item: ID, actions: HelpInfoSpotlightOverlayActions) -> some View {
  @Environment(\.colorScheme) var colorScheme

  VStack(spacing: 16) {
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
      .fill(colorScheme == .light ? .white : .black)
  }
  .shadow(color: (colorScheme == .dark ? Color.white : .black).opacity(0.20), radius: 24, y: 12)
}

private enum HelpInfo {
  case login
  case addItem
  case deleteItem
  case changeName
}

extension View {
  fileprivate func helpInfoViewTag(_ id: HelpInfo) -> some View { helpInfoViewTag(id: id) }
}

struct DemoAppView: View {
  @State private var selectedHelpInfoItem: HelpInfo?
  var body: some View {
    NavigationStack {
      VStack {
        Button("Login") {}
          .helpInfoViewTag(.login)
        Button("Add Item") {}
          .helpInfoViewTag(.addItem)
        Button("Delete Item") {}
          .helpInfoViewTag(.deleteItem)
        Button("Rename") {}
          .helpInfoViewTag(.changeName)
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("?") { selectedHelpInfoItem = .login }
        }
      }
    }
    .helpInfoSpotlightOverlay(
      selection: $selectedHelpInfoItem,
      orderedIDs: [HelpInfo.login, .addItem, .deleteItem, .changeName],
      overlay: helpInfoOverlay
    )
  }
}

extension HelpInfo: CaseIterable, HelpInfoProvider {
  var title: LocalizedStringKey {
    switch self {
    case .login: return "Login"
    case .addItem: return "Add"
    case .deleteItem: return "Delete"
    case .changeName: return "Rename"
    }
  }
  var text: LocalizedStringKey {
    switch self {
    case .login: return "Touch to log in to the system."
    case .addItem: return "Adds a new item to the collection."
    case .deleteItem: return "Delete the current item from the collection."
    case .changeName: return "Change the name of the current item."
    }
  }
}

#Preview {
  DemoAppView()
}
