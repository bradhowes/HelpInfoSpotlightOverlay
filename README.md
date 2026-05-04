[![][spiv]][spi]
[![][spip]][spi]
[![][mit]][license]

# HelpInfoSpotlightOverlay

Swift package that provides an elegant way to spotlight a SwiftUI view and display help information about it.

![demo](demo.gif)

## Usage

Define an `enum` to serve as a source of unique ids to tag important views in your UI:

```swift
enum HelpInfo {
case login
case addItem
case deleteItem
case changeName
}
```

Visit your SwiftUI code and tag important entities using the `HelpInfo` tags from above. First, add a small `View` extension to 
allow for `HelpInfo` completions:

```swift
extension View {
  func helpInfoViewTag(_ id: HelpInfo) -> some View { helpInfoViewTag(id: id) }
}
```

Annotate the views with `helpInfoViewTag` using auto-completion of `HelpInfo` values:

```swift
struct AppView: View {
  var body: some View {
    NavigationStack {
      VStack {
        Button("Login") {}
        .helpInfoViewTag(.login)
        Button("Add Item") {}
        .helpInfoViewTag(.addItem)
        Button("Delete Item") {}
        .helpInfoViewTag(.deleteItem)
        Button("Rename") {}
        .helpInfoViewTag(.changeName)
      }
    }
  }
}
```

Now, add a `@State` variable to track the active help info item, and a toolbar button to set this with the first enum case to get
things rolling. Add the `helpInfoSpotlightOverlay` modifier to the top-level view:

```swift
struct DemoAppView: View {
  @State private var selectedHelpInfoItem: HelpInfo?

  var body: some View {
    NavigationStack {
    ...
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("?") { selectedHelpInfoItem = .login }
        }
    }
    .helpInfoSpotlightOverlay(
      selection: $selectedHelpInfoItem, 
      orderedIDs: [HelpInfo.login, .addItem, .deleteItem, .changeName],
      overlay: helpInfoOverlay
    )
  }
}
```

The collection `HelpInfo` enum cases could be simplified by extending `HelpInfo` with `CaseIterable` to make available 
`HelpInfo.allCases`.

See the [DemoAppView][dav] definition for the finished example. You can also demo it in the Xcode preview for the file.

The last missing piece is to add to `HelpInfo` the `HelpInfoProvider` conformance so that the `helpInfoOverlay` function can 
extract the help text required to show to the user:

```swift
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
```

This is only necessary when using the built-in `helpInfoOverlay`.

## Configuration

The `helpInfoSpotlightOverlay` view modifier requires three values, but it accepts addional, optional ones to customize the
behavior and appearance of the spotlite (defaults given in parentheses):

* `spotlightPadding` -- padding to the spotlight region to make it larger (positive) or smaller (negative). (8)
* `cornerRadius` -- a corner radius to apply to the spotlight area rectangle. (28)
* `animationDuration` -- the duration of the animations used by the views. (0.3)
* `blurRadius` -- the amount of blurring to apply to the edge of the spotlight. (6)
* `dimmingOpacity` -- how opaque the overlay is that covers the root view, minus the spotlight region. (0.8)
* `scrollToItem` -- when `true`, attempts to make visible the view to spotlight. (true)
* `windowedMode` -- if set to `.useCustomWindow`, installs the overlay in a custom UIWindow. Otherwise, installs the overlay in the
view hiearchy attached to the view modifier.

The `scrollToItem` is done by wrapping the main view in a `ScrollViewReader` and then calling `scrollTo` with the ID of the 
view to highlight. This seems to work OK, but it can be disabled if the use of the `ScrollViewReader` is causing issues with 
your SwiftUI code.

## Origins

The code in this package derived from code in the [TutorialSpotlight][ts]
package by Artem Mirzabekian. However, there were sufficient changes that I created my
own. (the demo page shown above is largely from his source with some adjustments to handle "dark" mode.)

## Alternatives

Besides the [TutorialSpotlight][ts] mentioned above, another nice alternative is [Beacon][beacon]. It offers a way to actually drive
a guided tour of your app's features without too much effort. I studied how it creates and manages a top-level UI window, and I 
implemented something similar.

[spi]: https://swiftpackageindex.com/bradhowes/HelpInfoSpotlightOverlay
[spiv]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbradhowes%2FHelpInfoSpotlightOverlay%2Fbadge%3Ftype%3Dswift-versions
[spip]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbradhowes%2FHelpInfoSpotlightOverlay%2Fbadge%3Ftype%3Dplatforms
[mit]: https://img.shields.io/badge/License-MIT-A31F34.svg
[license]: https://opensource.org/licenses/MIT
[ts]: https://github.com/Livsy90/TutorialSpotlight
[beacon]: https://github.com/mmellau/swift-beacon
[dav]: https://github.com/bradhowes/HelpInfoSpotlightOverlay/blob/c569fa3ec3e9f2ea6b4fc046d93128840114fb2e/Sources/HelpInfoSpotlightOverlay/HelpInfoOverlay.swift#L74
