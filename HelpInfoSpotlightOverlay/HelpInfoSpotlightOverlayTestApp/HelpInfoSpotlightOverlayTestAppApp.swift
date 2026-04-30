// Copyright © 2026 Brad Howes. All rights reserved.

import HelpInfoSpotlightOverlay
import SwiftUI

enum HelpInfo: CaseIterable, HelpInfoProvider {
  case hello
  case world

  var title: LocalizedStringKey {
    switch self {
    case .hello: return "Hello"
    case .world: return "World"
    }
  }

  var text: LocalizedStringKey {
    switch self {
    case .hello: return "This how we greet someone."
    case .world: return "This is where we live."
    }
  }
}

@main
struct HelpInfoSpotlightOverlayTestAppApp: App {
  @State private var helpInfo: HelpInfo?

  var body: some Scene {
    WindowGroup {
      ContentView(helpInfo: $helpInfo)
        .helpInfoSpotlightOverlay(selection: $helpInfo, orderedIDs: HelpInfo.allCases, overlay: helpInfoOverlay)
    }
  }
}
