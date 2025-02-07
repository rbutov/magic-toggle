//
//  Magic_ToggleUITestsLaunchTests.swift
//  Magic ToggleUITests
//
//  Created by Ruslan Butov on 1/19/25.
//

import XCTest

final class Magic_ToggleUITestsLaunchTests: XCTestCase {
    
    var app: XCUIApplication!

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testLaunch() throws {
        // Take launch screenshot
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testStatusBarIconVisibility() throws {
        // Verify status bar icon exists
        let statusItem = app.statusItems.firstMatch
        XCTAssertTrue(statusItem.exists)
    }
    
    @MainActor
    func testMenuItemsExist() throws {
        // Open menu
        let statusItem = app.statusItems.firstMatch
        statusItem.click()
        
        // Verify menu items exist
        XCTAssertTrue(app.menuItems["About Magic Toggle"].exists)
        XCTAssertTrue(app.menuItems["Quit"].exists)
    }
    
    @MainActor
    func testAboutWindowContents() throws {
        // Open About window
        let statusItem = app.statusItems.firstMatch
        statusItem.click()
        
        app.menuItems.matching(identifier: "showAbout").element.click()
        
        // Verify About window appears and has correct content
        let aboutWindow = app.windows["About Magic Toggle"]
        XCTAssertTrue(aboutWindow.exists)
        
        // Verify window dimensions match expected values from unit tests
        let windowFrame = aboutWindow.frame
        XCTAssertEqual(Int(round(windowFrame.width)), 332)
        XCTAssertEqual(Int(round(windowFrame.height)), 310)
        
        // Verify window has expected controls
        XCTAssertTrue(aboutWindow.staticTexts["Magic Toggle"].exists)
        
        // Close the window using window close button
        aboutWindow.buttons[XCUIIdentifierCloseWindow].click()
        XCTAssertFalse(aboutWindow.exists)
    }
}
