//
//  WordsEndpointPathTests.swift
//  swift-api
//
//  Created by GitHub Copilot on 2025/7/29.
//

import XCTest

@testable import ContextEndpoints
@testable import SwiftAPICore

final class WordsEndpointPathTests: XCTestCase {

    func testWordsEndpointGroupName() {
        XCTAssertEqual(EP.Words.name, "words", "Group name should be 'words'")
    }

    func testFetchSuggestedWordsPath() {
        let expectedPath = "/words/suggested"
        let actualPath = EP.Words.FetchSuggestedWords.path
        XCTAssertEqual(actualPath, expectedPath, "FetchSuggestedWords path should be prefixed with group name")
    }

    func testLookupWordPath() {
        let expectedPath = "/words/lookup"
        let actualPath = EP.Words.LookupWord.path
        XCTAssertEqual(actualPath, expectedPath, "LookupWord path should be prefixed with group name")
    }

    func testPathsAreGrouped() {
        // Verify that both endpoints use the group name
        let groupName = EP.Words.name

        XCTAssertTrue(
            EP.Words.FetchSuggestedWords.path.hasPrefix("/\(groupName)/"),
            "FetchSuggestedWords path should start with group name")

        XCTAssertTrue(
            EP.Words.LookupWord.path.hasPrefix("/\(groupName)/"),
            "LookupWord path should start with group name")
    }
}
