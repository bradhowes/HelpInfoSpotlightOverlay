// Copyright © 2026 Brad Howes. All rights reserved.

import UIKit
import SwiftUI

@main
struct HelpInfoSpotlightOverlayTestApp: App {

  let enableAnimations: Bool
  let enableScrollTo: Bool

  init() {
    if ProcessInfo.processInfo.arguments.contains("UITEST") {
      UIView.setAnimationsEnabled(false)
      self.enableAnimations = false
    } else {
      self.enableAnimations = true
    }
    self.enableScrollTo = !ProcessInfo.processInfo.arguments.contains("NO_SCROLLTO")
  }

  var body: some Scene {
    WindowGroup {
      ContentView(enableAnimations: enableAnimations, enableScrollTo: enableScrollTo)
    }
  }
}
