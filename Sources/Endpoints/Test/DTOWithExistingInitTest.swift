import SwiftAPICore

// Test file to verify @DTO macro does NOT generate initializer when one already exists

@DTO
public struct TestStructWithExistingInit {
    public var name: String
    public var value: Int

    // Custom initializer - @DTO should NOT generate another one
    public init(customName: String) {
        self.name = customName
        self.value = 42
    }
}

// Test that we can use the custom initializer
func testExistingInitBehavior() {
    let instance = TestStructWithExistingInit(customName: "Test")
    let _: any Hashable = instance
    let _: any Codable = instance
    let _: any Sendable = instance
}
