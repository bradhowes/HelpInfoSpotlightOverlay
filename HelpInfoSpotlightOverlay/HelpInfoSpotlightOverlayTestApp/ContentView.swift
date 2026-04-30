// Copyright © 2026 Brad Howes. All rights reserved.

import HelpInfoSpotlightOverlay
import SwiftUI

struct ContentView: View {
  @Binding private var helpInfo: HelpInfo?

  init(helpInfo: Binding<HelpInfo?>) {
    self._helpInfo = helpInfo
  }

  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
        .helpInfoViewTag(id: HelpInfo.world)
      Text("Hello, world!")
        .helpInfoViewTag(id: HelpInfo.hello)
      Button("?") { helpInfo = .hello }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
}

#Preview {
  @Previewable @State var helpInfo: HelpInfo?
  ContentView(helpInfo: $helpInfo)
    .helpInfoSpotlightOverlay(selection: $helpInfo, orderedIDs: HelpInfo.allCases, overlay: helpInfoOverlay)
}
