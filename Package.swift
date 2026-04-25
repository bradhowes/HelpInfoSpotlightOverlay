// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "HelpInfoSpotlightOverlay",
  platforms: [
    .iOS(.v18), .macOS(.v15)
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
  ]
)
