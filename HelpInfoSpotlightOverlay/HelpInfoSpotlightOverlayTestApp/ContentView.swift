// Copyright © 2026 Brad Howes. All rights reserved.

import HelpInfoSpotlightOverlay
import SwiftUI

struct ContentView: View {
  let enableAnimations: Bool
  let enableScrollTo: Bool

  var body: some View {
    tutorialSpotlightDemo(enableAnimations: enableAnimations, enableScrollTo: enableScrollTo)
  }
}

#Preview {
  ContentView(enableAnimations: true, enableScrollTo: true)
}
