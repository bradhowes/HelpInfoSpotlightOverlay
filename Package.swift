// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "HelpInfoSpotlightOverlay",
  platforms: [
    .iOS(.v18)
  ],
  products: [
    .library(
      name: "HelpInfoSpotlightOverlay",
      targets: ["HelpInfoSpotlightOverlay"]
    )
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "HelpInfoSpotlightOverlay"
    ),
    .testTarget(
      name: "HelpInfoSpotlightOverlayTests",
      dependencies: ["HelpInfoSpotlightOverlay"]
    )
  ],
  swiftLanguageModes: [.v6]
)
