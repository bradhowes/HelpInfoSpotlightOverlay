// Copyright © 2026 Brad Howes. All rights reserved.

import SwiftUI

/**
 Example definition of an overlay that presents the help information for a view tagged by ``helpInfoViewTag``.

 This can be used as-is if the `ID` generic implements ``HelpInfoProvider``. The overlay contains three buttons that correspond to
 the actions found in  ``HelpInfoSpotlightOverlayActions``:

 * `cancel` -- dismiss the spotlight overlay
 * `previous` -- show the previous item in the collection of IDs
 * `next` -- show the next item in the collection of IDs

 The collection of IDs is not found here but is captured in the action closures that is handed to this function. There is no
 business logic here, just presentation.

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
        Text("Tap the '?' to begin spotlighting.")
        VStack(spacing: 24) {
          Button("Login") {}
            .helpInfoViewTag(.login)
          Spacer()
          HStack(spacing: 48) {
            Button("Add Item") {}
              .helpInfoViewTag(.addItem)
            Button("Delete Item") {}
              .helpInfoViewTag(.deleteItem)
          }
          Spacer()
          Button("Rename") {}
            .helpInfoViewTag(.changeName)
        }
      }
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Button("?") { selectedHelpInfoItem = .login }
        }
      }
    }
    .helpInfoSpotlightOverlay(
      selection: $selectedHelpInfoItem,
      orderedIDs: HelpInfo.allCases,
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

#if os(macOS)

  DemoAppView()
    .frame(width: 400, height: 400)

#else

  DemoAppView()

#endif

}
