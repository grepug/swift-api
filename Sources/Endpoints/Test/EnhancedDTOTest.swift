import SwiftAPICore

// Test file to verify @DTO macro functionality with enums and structs

@DTO
public enum TestEnum {
    case option1
    case option2
    case option3
}

@DTO
public struct TestStruct {
    public var name: String
    public var enumValue: TestEnum
    public var optionalValue: String? = nil
}

// Usage test
func testEnhancedDTOUsage() {
    // Test enum conformances
    let enumValue = TestEnum.option1
    let _: any Hashable = enumValue
    let _: any Codable = enumValue
    let _: any Sendable = enumValue

    // Test struct with generated initializer with different parameter combinations
    let structValue1 = TestStruct(name: "Test", enumValue: .option2)
    let _ = TestStruct(name: "Test", enumValue: .option2, optionalValue: "custom")
    let _ = TestStruct(name: "Test", enumValue: .option2, optionalValue: nil)

    // Test struct conformances
    let _: any Hashable = structValue1
    let _: any Codable = structValue1
    let _: any Sendable = structValue1
}
