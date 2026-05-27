import SwiftUI

/**
 Mapping of view help item ID tags and view anchor geometries made available via SwiftUI preferences system. These are
 used by the spotlight overlays to move from item to item in the view hierarchy.
 */
struct IDAnchorPreferenceKey<ID: Hashable>: PreferenceKey {
  typealias Value = [ID: Anchor<CGRect>]

  static var defaultValue: Value { [:] }

  static func reduce(value: inout Value, nextValue: () -> Value) {
    // Use `merge` to gather values from embedded views without having to tag all containers in the hierarchy.
    value.merge(nextValue()) { (_, new) in new }
  }
}
