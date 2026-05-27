// Copyright © 2026 Brad Howes. All rights reserved.

import SwiftUI

/**
 View modifier that adds a help item preference value.

 Use `transformAnchorPreference` so that containers do not shadow entities they hold. Since the default value is an empty
 dictionary, this is also safe to use for non-container views.
 */
struct ViewTagModifier<ID: Hashable>: ViewModifier {
  let id: ID

  func body(content: Content) -> some View {
    content
      .transformAnchorPreference(key: IDAnchorPreferenceKey<ID>.self, value: .bounds) {
        $0[id] = $1
      }
      .id(id)
  }
}

