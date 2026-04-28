// Copyright © 2026 Brad Howes. All rights reserved.

import SwiftUI

/**
 Custom layout for help info text views.

 The layout is not very robust, so best to limit what it manages to one or more `Text` views. It does guarantee the smallest
 bounding rectangle for the `Text` views it manages, and honors a `frame` `maxWidth` value if set.
 */
public struct HelpInfoLayout: Layout {
  public let spacing: CGFloat

  public init(spacing: CGFloat = 16.0) {
    self.spacing = spacing
  }

  public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    guard !subviews.isEmpty else { return .zero }
    var maxWidth: CGFloat = 0
    var maxHeight: CGFloat = 0
    for subview in subviews {
      let unlimited = subview.sizeThatFits(ProposedViewSize.unspecified)
      let limited = subview.sizeThatFits(proposal)
      maxWidth = max(maxWidth, min(unlimited.width, limited.width))
      maxHeight += limited.height + spacing
    }
    return .init(width: maxWidth, height: maxHeight - spacing)
  }

  public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let size = sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
    let actual = ProposedViewSize(width: size.width, height: nil)
    var height: CGFloat = bounds.minY
    for subview in subviews {
      let limited = subview.sizeThatFits(actual)
      subview.place(at: .init(x: bounds.minX, y: height), anchor: .topLeading, proposal: actual)
      height += limited.height + spacing
    }
  }
}

#if DEBUG

#Preview {
  VStack(spacing: 32) {
    HelpInfoLayout {
      Text("Title Width")
        .font(.title3.weight(.bold))
      Text(
"""
The quick fox.
The quick fox.
"""
      )
        .font(.footnote)
    }
    .border(.black, width: 1)
    .background(.yellow)

    HelpInfoLayout {
      Text("Body Width")
        .font(.title3.weight(.bold))
      Text(
"""
The quick brown fox jumped.
The quick brown fox sat.
"""
      )
        .font(.footnote)
    }
    .border(.black, width: 1)
    .background(.yellow)

    HelpInfoLayout {
      Text("Wrapped by Parent Width")
        .font(.title3.weight(.bold))
      Text(
"""
The quick brown fox jumped over the lazy fox. \
The quick brown fox jumped over the lazy fox. \
The quick brown fox jumped over the lazy fox.
"""
      )
      .font(.footnote)
    }
    .border(.black, width: 1)
    .background(.yellow)

    HelpInfoLayout {
      Text("Wrapped by maxWidth")
        .font(.title3.weight(.bold))
      Text(
"""
The quick brown fox jumped over the lazy fox. \
The quick brown fox jumped over the lazy fox. \
The quick brown fox jumped over the lazy fox.
"""
      )
      .font(.footnote)
    }
    .frame(maxWidth: 260)
    .border(.black, width: 1)
    .background(.yellow)
  }
}

#endif // DEBUG
