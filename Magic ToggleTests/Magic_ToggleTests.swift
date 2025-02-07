//
//  Magic_ToggleTests.swift
//  Magic ToggleTests
//
//  Created by Ruslan Butov on 1/19/25.
//

import Testing
import AppKit
@testable import Magic_Toggle

struct Magic_ToggleTests {

    @Test func testDisplayManagerExternalDisplays() async throws {
        let displayManager = DisplayManager.shared
        let displays = displayManager.getExternalDisplays()
        
        // Initially there should be no external displays in test environment
        #expect(displays.isEmpty)
    }
}
