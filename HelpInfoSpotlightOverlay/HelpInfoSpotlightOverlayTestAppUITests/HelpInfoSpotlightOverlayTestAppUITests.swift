// Copyright © 2026 Brad Howes. All rights reserved.

import SnapshotTesting
import SwiftUI
import XCTest
import XCTestParametrizedMacro

final class HelpInfoSpotlightOverlayTestAppUITests: XCTestCase {
  let snapshot: Snapshotting<UIImage, UIImage> = .image(precision: 0.9, perceptualPrecision: 0.9)

  override func setUpWithError() throws {
    continueAfterFailure = false
    XCUIDevice.shared.orientation = .portrait
  }

  func app(appearance: XCUIDevice.Appearance) -> XCUIApplication {
    XCUIDevice.shared.appearance = appearance
    let app = XCUIApplication()
    app.launch()
    app.activate()
    app/*@START_MENU_TOKEN@*/.buttons["questionmark.circle"]/*[[".otherElements[\"questionmark.circle\"].buttons",".otherElements.buttons[\"questionmark.circle\"]",".buttons[\"questionmark.circle\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
    // Make sure that the view is up and available
    XCTAssertTrue(app.buttons["xmark"].isHittable)
    // Wait for animations to be done -- TODO: use custom config to disable animations and get rid of `delay` calls.
    delay(for: 1.0)
    return app
  }

  func delay(for timeInterval: TimeInterval) {
    let delayExpectation = XCTestExpectation()
    delayExpectation.isInverted = true
    wait(for: [delayExpectation], timeout: timeInterval)
  }

  @Parametrize(input: [XCUIDevice.Appearance.light, .dark], labels: ["light", "dark"])
  @MainActor
  func testShowHelpInfo(input appearance: XCUIDevice.Appearance) throws {
    let image = app(appearance: appearance).windows.firstMatch.screenshot().image
    withSnapshotTesting(record: .failed) {
      assertSnapshot(of: image.sansStatusBar, as: snapshot)
    }
  }

  @Parametrize(input: [XCUIDevice.Appearance.light, .dark], labels: ["light", "dark"])
  @MainActor
  func testCloseHelpInfo(input appearance: XCUIDevice.Appearance) throws {
    let app = app(appearance: appearance)
    app.buttons["xmark"].firstMatch.tap()
    XCTAssertFalse(app/*@START_MENU_TOKEN@*/.buttons["xmark"]/*[[".otherElements",".buttons[\"exit\"]",".buttons[\"xmark\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.isHittable)

    delay(for: 1.0)
    let image = app.windows.firstMatch.screenshot().image
    withSnapshotTesting(record: .failed) {
      assertSnapshot(of: image.sansStatusBar, as: snapshot)
    }
  }

  @Parametrize(input: [XCUIDevice.Appearance.light, .dark], labels: ["light", "dark"])
  @MainActor
  func testTapClosesHelpInfo(input appearance: XCUIDevice.Appearance) throws {
    let app = app(appearance: appearance)
    app.windows.firstMatch.tap(withNumberOfTaps: 1, numberOfTouches: 1)
    XCTAssertFalse(app/*@START_MENU_TOKEN@*/.buttons["xmark"]/*[[".otherElements",".buttons[\"exit\"]",".buttons[\"xmark\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.isHittable)

    delay(for: 1.0)
    let image = app.windows.firstMatch.screenshot().image
    withSnapshotTesting(record: .failed) {
      assertSnapshot(of: image.sansStatusBar, as: snapshot)
    }
  }

  @Parametrize(input: [XCUIDevice.Appearance.light, .dark], labels: ["light", "dark"])
  @MainActor
  func testGotoNextHelpInfo(input appearance: XCUIDevice.Appearance) throws {
    let app = app(appearance: appearance)
    app/*@START_MENU_TOKEN@*/.buttons["arrowshape.right.fill"]/*[[".otherElements",".buttons[\"next\"]",".buttons[\"arrowshape.right.fill\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()

    delay(for: 1.0)
    let image = app.windows.firstMatch.screenshot().image
    withSnapshotTesting(record: .failed) {
      assertSnapshot(of: image.sansStatusBar, as: snapshot)
    }
  }

  @Parametrize(input: [XCUIDevice.Appearance.light, .dark], labels: ["light", "dark"])
  @MainActor
  func testGotoPreviousHelpInfo(input appearance: XCUIDevice.Appearance) throws {
    let app = app(appearance: appearance)
    app.buttons["arrowshape.left.fill"].firstMatch.tap()

    delay(for: 1.0)
    let image = app.windows.firstMatch.screenshot().image
    withSnapshotTesting(record: .failed) {
      assertSnapshot(of: image.sansStatusBar, as: snapshot)
    }
  }

  @MainActor
  func testLaunchPerformance() throws {
    // This measures how long it takes to launch your application.
    measure(metrics: [XCTApplicationLaunchMetric()]) {
      XCUIApplication().launch()
    }
  }
}

// Source - https://stackoverflow.com/a/48110726
// Posted by Mark Leonard, modified by community. See post 'Timeline' for change history
// Retrieved 2026-06-02, License - CC BY-SA 4.0

public extension UIImage {
  func croppedImage(inRect rect: CGRect) -> UIImage {
    let rad: (Double) -> CGFloat = { deg in
      return CGFloat(deg / 180.0 * .pi)
    }
    var rectTransform: CGAffineTransform
    switch imageOrientation {
    case .left:
      let rotation = CGAffineTransform(rotationAngle: rad(90))
      rectTransform = rotation.translatedBy(x: 0, y: -size.height)
    case .right:
      let rotation = CGAffineTransform(rotationAngle: rad(-90))
      rectTransform = rotation.translatedBy(x: -size.width, y: 0)
    case .down:
      let rotation = CGAffineTransform(rotationAngle: rad(-180))
      rectTransform = rotation.translatedBy(x: -size.width, y: -size.height)
    default:
      rectTransform = .identity
    }
    rectTransform = rectTransform.scaledBy(x: scale, y: scale)
    let transformedRect = rect.applying(rectTransform)
    let imageRef = cgImage!.cropping(to: transformedRect)!
    let result = UIImage(cgImage: imageRef, scale: scale, orientation: imageOrientation)
    return result
  }

  var sansStatusBar: UIImage {
    let height: CGFloat = 32.0
    return croppedImage(inRect: .init(x: 0, y: height, width: self.size.width, height: self.size.height - height))
  }
}
