// Copyright © 2026 Brad Howes. All rights reserved.

import SwiftUI

/**
 Protocol for a tag type that can provide help information for a view tagged with a tag type value.
 */
public protocol HelpInfoProvider {

  /// The content to use for the title `Text` view.
  var title: LocalizedStringKey { get }
  /// The content to use for the body `Text` view that provides details about the item.
  var text: LocalizedStringKey { get }
}

