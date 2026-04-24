// Copyright © 2026 Brad Howes. All rights reserved.

import SwiftUI

/**
 Protocol for entities that can provide help information for a view tagged by ``helpInfoViewTag``.
 */
public protocol HelpInfoProvider {

  /// The content to use for the title `Text` view
  var title: LocalizedStringKey { get }
  /// The generator to use for the content of the text `Text` view. This delays `String` interpolation to properly honor embedded
  /// `Image(systemName:)` terms.
  var text: LocalizedStringKey { get }
}

