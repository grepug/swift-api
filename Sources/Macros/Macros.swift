//
//  Macros.swift
//  swift-api
//
//  Created by GitHub Copilot on 2025/7/29.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - Macro Implementations

/// Implementation of the `@Endpoint` macro, which automatically makes structs conform to Endpoint
public struct EndpointMacro: ExtensionMacro, MemberMacro {

    // MARK: - ExtensionMacro

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        // Create extension that adds Endpoint conformance
        let extensionDecl = ExtensionDeclSyntax(
            extendedType: type,
            inheritanceClause: InheritanceClauseSyntax {
                for conformance in protocols {
                    InheritedTypeSyntax(type: conformance)
                }
            }
        ) {}

        return [extensionDecl]
    }

    // MARK: - MemberMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        // Extract path and method from macro arguments
        let (rawPath, method) = try extractPathAndMethod(from: node)

        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroError.notAppliedToStruct
        }

        // Try to detect enclosing type and auto-prefix path if it conforms to EndpointGroup
        let finalPath = try resolveFinalPath(rawPath: rawPath, structDecl: structDecl, context: context)

        var members: [DeclSyntax] = []

        // Note: Nested types like Body, Query, ResponseContent should be manually annotated with @DTO
        // for automatic protocol conformance (Hashable, Codable, Sendable) and initializer generation

        // Add static path property
        let pathProperty = VariableDeclSyntax(
            modifiers: DeclModifierListSyntax([
                DeclModifierSyntax(name: .keyword(.public)),
                DeclModifierSyntax(name: .keyword(.static)),
            ]),
            bindingSpecifier: .keyword(.var)
        ) {
            PatternBindingSyntax(
                pattern: IdentifierPatternSyntax(identifier: .identifier("path")),
                typeAnnotation: TypeAnnotationSyntax(
                    type: IdentifierTypeSyntax(name: .identifier("String"))
                ),
                accessorBlock: AccessorBlockSyntax(
                    accessors: .getter([
                        CodeBlockItemSyntax(
                            item: .expr(ExprSyntax(StringLiteralExprSyntax(content: finalPath)))
                        )
                    ]))
            )
        }
        members.append(DeclSyntax(pathProperty))

        // Add static method property
        let methodProperty = VariableDeclSyntax(
            modifiers: DeclModifierListSyntax([
                DeclModifierSyntax(name: .keyword(.public)),
                DeclModifierSyntax(name: .keyword(.static)),
            ]),
            bindingSpecifier: .keyword(.var)
        ) {
            PatternBindingSyntax(
                pattern: IdentifierPatternSyntax(identifier: .identifier("method")),
                typeAnnotation: TypeAnnotationSyntax(
                    type: IdentifierTypeSyntax(name: .identifier("EndpointMethod"))
                ),
                accessorBlock: AccessorBlockSyntax(
                    accessors: .getter([
                        CodeBlockItemSyntax(
                            item: .expr(
                                ExprSyntax(
                                    MemberAccessExprSyntax(
                                        name: .identifier(method)
                                    )))
                        )
                    ]))
            )
        }
        members.append(DeclSyntax(methodProperty))

        // Check if Body type exists
        let hasRequestBody = structDecl.memberBlock.members.contains { member in
            if let typeDecl = member.decl.as(StructDeclSyntax.self) {
                return typeDecl.name.text == "Body"
            }
            return false
        }

        // Check if there's already a body property
        let hasBodyProperty = structDecl.memberBlock.members.contains { member in
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                return varDecl.bindings.contains { binding in
                    if let pattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                        return pattern.identifier.text == "body"
                    }
                    return false
                }
            }
            return false
        }

        // Check if there's already an initializer
        let hasInitializer = structDecl.memberBlock.members.contains { member in
            return member.decl.is(InitializerDeclSyntax.self)
        }

        // Check if Query type exists
        let hasRequestQuery = structDecl.memberBlock.members.contains { member in
            if let typeDecl = member.decl.as(StructDeclSyntax.self) {
                return typeDecl.name.text == "Query"
            }
            return false
        }

        // Add body property if Body exists but no body property
        if hasRequestBody && !hasBodyProperty {
            let bodyProperty = VariableDeclSyntax(
                modifiers: DeclModifierListSyntax([
                    DeclModifierSyntax(name: .keyword(.public))
                ]),
                bindingSpecifier: .keyword(.var)
            ) {
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(identifier: .identifier("body")),
                    typeAnnotation: TypeAnnotationSyntax(
                        type: IdentifierTypeSyntax(name: .identifier("Body"))
                    )
                )
            }
            members.append(DeclSyntax(bodyProperty))
        }

        // Generate comprehensive public initializer if no initializer exists
        if !hasInitializer {
            let initializer = try generateComprehensiveInitializer(for: structDecl, hasRequestBody: hasRequestBody, hasRequestQuery: hasRequestQuery)
            members.append(DeclSyntax(initializer))
        }

        // Check if there's already a query property
        let hasQueryProperty = structDecl.memberBlock.members.contains { member in
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                return varDecl.bindings.contains { binding in
                    if let pattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                        return pattern.identifier.text == "query"
                    }
                    return false
                }
            }
            return false
        }

        // Add query property if Query exists but no query property
        if hasRequestQuery && !hasQueryProperty {
            let queryProperty = VariableDeclSyntax(
                modifiers: DeclModifierListSyntax([
                    DeclModifierSyntax(name: .keyword(.public))
                ]),
                bindingSpecifier: .keyword(.var)
            ) {
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(identifier: .identifier("query")),
                    typeAnnotation: TypeAnnotationSyntax(
                        type: IdentifierTypeSyntax(name: .identifier("Query"))
                    ),
                    initializer: InitializerClauseSyntax(
                        value: FunctionCallExprSyntax(
                            calledExpression: DeclReferenceExprSyntax(baseName: .identifier("Query")),
                            leftParen: .leftParenToken(),
                            arguments: LabeledExprListSyntax([]),
                            rightParen: .rightParenToken()
                        )
                    )
                )
            }
            members.append(DeclSyntax(queryProperty))
        }

        return members
    }

    // MARK: - PeerMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            return []
        }

        var peerDeclarations: [DeclSyntax] = []

        // Get the parent struct name for creating extensions
        let parentStructName = structDecl.name.text

        // Scan for nested types that should get automatic DTO functionality
        for member in structDecl.memberBlock.members {
            // Handle nested struct declarations
            if let nestedStruct = member.decl.as(StructDeclSyntax.self),
                shouldApplyDTOToNestedType(nestedStruct.name.text)
            {

                // Generate DTO extension for the nested struct
                let dtoExtensions = try generateDTOExtensionsForNestedStruct(
                    parentName: parentStructName,
                    nestedStruct: nestedStruct,
                    in: context
                )
                peerDeclarations.append(contentsOf: dtoExtensions)
            }
            // Handle nested enum declarations
            else if let nestedEnum = member.decl.as(EnumDeclSyntax.self),
                shouldApplyDTOToNestedType(nestedEnum.name.text)
            {

                // Generate DTO extension for the nested enum
                let dtoExtensions = try generateDTOExtensionsForNestedEnum(
                    parentName: parentStructName,
                    nestedEnum: nestedEnum,
                    in: context
                )
                peerDeclarations.append(contentsOf: dtoExtensions)
            }
        }

        return peerDeclarations
    }

    // MARK: - Helper Methods

    private static func generateComprehensiveInitializer(
        for structDecl: StructDeclSyntax,
        hasRequestBody: Bool,
        hasRequestQuery: Bool
    ) throws -> InitializerDeclSyntax {

        // Collect all stored properties that need to be initialized
        var parameters: [FunctionParameterSyntax] = []
        var assignments: [String] = []

        // Scan for all var properties in the struct that need initialization
        for member in structDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self),
                shouldProcessVariable(varDecl)
            {

                for binding in varDecl.bindings {
                    if let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                        let typeAnnotation = binding.typeAnnotation
                    {

                        let propertyName = pattern.identifier.text
                        let typeName = typeAnnotation.type

                        // Skip properties that have default values
                        if binding.initializer != nil {
                            continue
                        }

                        // Include all properties without default values
                        if propertyName == "body" {
                            parameters.append(
                                FunctionParameterSyntax(
                                    firstName: .identifier(propertyName),
                                    type: typeName
                                )
                            )
                            assignments.append("self.\(propertyName) = \(propertyName)")
                        } else if propertyName == "query" {
                            // For query properties, make them required
                            parameters.append(
                                FunctionParameterSyntax(
                                    firstName: .identifier(propertyName),
                                    type: typeName
                                )
                            )
                            assignments.append("self.\(propertyName) = \(propertyName)")
                        }
                    }
                }
            }
        }

        // Create the parameter clause
        let parameterClause: FunctionParameterClauseSyntax
        if parameters.isEmpty {
            parameterClause = FunctionParameterClauseSyntax {
                // Empty parameter list
            }
        } else {
            parameterClause = FunctionParameterClauseSyntax {
                for parameter in parameters {
                    parameter
                }
            }
        }

        // Create the body with assignments
        let bodyStatements = assignments.map { assignment in
            CodeBlockItemSyntax(
                item: .expr(ExprSyntax(stringLiteral: assignment))
            )
        }

        return InitializerDeclSyntax(
            modifiers: DeclModifierListSyntax([
                DeclModifierSyntax(name: .keyword(.public))
            ]),
            signature: FunctionSignatureSyntax(
                parameterClause: parameterClause
            )
        ) {
            for statement in bodyStatements {
                statement
            }
        }
    }

    private static func extractPathAndMethod(from node: AttributeSyntax) throws -> (String, String) {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
            arguments.count >= 2
        else {
            throw MacroError.invalidArguments
        }

        // Extract path (first argument)
        guard let pathExpr = arguments.first?.expression.as(StringLiteralExprSyntax.self),
            let pathSegment = pathExpr.segments.first?.as(StringSegmentSyntax.self)
        else {
            throw MacroError.invalidPathArgument
        }
        let path = pathSegment.content.text

        // Extract method (second argument)
        guard let methodExpr = arguments.dropFirst().first?.expression.as(MemberAccessExprSyntax.self) else {
            throw MacroError.invalidMethodArgument
        }
        let method = methodExpr.declName.baseName.text

        return (path, method)
    }

    // MARK: - Path Resolution with EndpointGroup

    private static func resolveFinalPath(
        rawPath: String,
        structDecl: StructDeclSyntax,
        context: some MacroExpansionContext
    ) throws -> String {
        // If path already starts with "/", return as-is
        if rawPath.hasPrefix("/") {
            return rawPath
        }

        // Try to detect the group name from the enclosing context
        // Look for patterns like EP.User.StructName or similar
        if let groupName = extractGroupNameFromContext(context: context) {
            return "/\(groupName)/\(rawPath)"
        }

        // If no group detected, ensure path starts with "/"
        return "/\(rawPath)"
    }

    private static func extractGroupNameFromContext(context: some MacroExpansionContext) -> String? {
        // Try to extract group name from the lexical context
        // This is a best-effort approach since macro context is limited

        // Look through the lexical context for extension declarations
        for contextNode in context.lexicalContext {
            if let extensionDecl = contextNode.as(ExtensionDeclSyntax.self) {
                // Check if this is an extension of something like EP.User
                if let memberType = extensionDecl.extendedType.as(MemberTypeSyntax.self) {
                    // Pattern: EP.User -> extract "user"
                    if let baseType = memberType.baseType.as(IdentifierTypeSyntax.self),
                        baseType.name.text == "EP"
                    {
                        let groupType = memberType.name.text
                        return groupType.lowercased()  // Convert "User" to "user"
                    }
                }
            }
        }

        return nil
    }

    // MARK: - DTO Integration Helper Methods

    private static func shouldApplyDTOToNestedType(_ typeName: String) -> Bool {
        // Common nested type names that should automatically get DTO functionality
        let dtoTargetNames: Set<String> = [
            "Body", "Query", "ResponseContent", "ResponseChunk",
            "Feature", "Source", "FeatureLimitInfo", "StringBool",
        ]

        return dtoTargetNames.contains(typeName)
    }

    private static func generateDTOExtensionsForNestedStruct(
        parentName: String,
        nestedStruct: StructDeclSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        let nestedStructName = nestedStruct.name.text
        let fullTypeName = "\(parentName).\(nestedStructName)"

        var extensions: [DeclSyntax] = []

        // Create protocol conformance extension (equivalent to @DTO ExtensionMacro)
        let protocolExtension = ExtensionDeclSyntax(
            extendedType: IdentifierTypeSyntax(name: .identifier(fullTypeName)),
            inheritanceClause: InheritanceClauseSyntax {
                InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier("Hashable")))
                InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier("Codable")))
                InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier("Sendable")))
            }
        ) {}

        extensions.append(DeclSyntax(protocolExtension))

        // Generate initializer extension if needed (equivalent to @DTO MemberMacro)
        if let initializerExtension = try generateInitializerExtensionForNestedStruct(
            fullTypeName: fullTypeName,
            nestedStruct: nestedStruct,
            in: context
        ) {
            extensions.append(DeclSyntax(initializerExtension))
        }

        return extensions
    }

    private static func generateDTOExtensionsForNestedEnum(
        parentName: String,
        nestedEnum: EnumDeclSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        let nestedEnumName = nestedEnum.name.text
        let fullTypeName = "\(parentName).\(nestedEnumName)"

        // Create protocol conformance extension for enum (equivalent to @DTO ExtensionMacro)
        let protocolExtension = ExtensionDeclSyntax(
            extendedType: IdentifierTypeSyntax(name: .identifier(fullTypeName)),
            inheritanceClause: InheritanceClauseSyntax {
                InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier("Hashable")))
                InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier("Codable")))
                InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier("Sendable")))
            }
        ) {}

        return [DeclSyntax(protocolExtension)]
    }

    private static func generateInitializerExtensionForNestedStruct(
        fullTypeName: String,
        nestedStruct: StructDeclSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExtensionDeclSyntax? {

        // Check if there's already an initializer
        let hasInitializer = nestedStruct.memberBlock.members.contains { member in
            return member.decl.is(InitializerDeclSyntax.self)
        }

        if hasInitializer {
            return nil  // Don't generate if one already exists
        }

        // Generate the initializer using the same logic as DTOMacro
        guard let initializer = try generateDTOInitializer(for: nestedStruct) else {
            return nil  // No initializer needed (no parameters)
        }

        // Create extension with the initializer
        let initializerExtension = ExtensionDeclSyntax(
            extendedType: IdentifierTypeSyntax(name: .identifier(fullTypeName))
        ) {
            initializer
        }

        return initializerExtension
    }
}

/// Implementation of the `@DTO` macro, which automatically adds DTO conformances and initializers
public struct DTOMacro: ExtensionMacro, MemberMacro {

    // MARK: - ExtensionMacro

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        // Create extension that adds Hashable, Codable, Sendable conformance
        let extensionDecl = ExtensionDeclSyntax(
            extendedType: type,
            inheritanceClause: InheritanceClauseSyntax {
                for conformance in protocols {
                    InheritedTypeSyntax(type: conformance)
                }
            }
        ) {}

        return [extensionDecl]
    }

    // MARK: - MemberMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        var members: [DeclSyntax] = []

        // Handle struct declarations
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            // Check if there's already an initializer
            let hasInitializer = structDecl.memberBlock.members.contains { member in
                return member.decl.is(InitializerDeclSyntax.self)
            }

            // Generate public initializer if no initializer exists
            if !hasInitializer {
                let initializer = try generateDTOInitializer(for: structDecl)
                if let initializer = initializer {
                    members.append(DeclSyntax(initializer))
                }
            }
        }
        // Handle enum declarations - no initializer needed, just protocol conformance
        else if declaration.is(EnumDeclSyntax.self) {
            // For enums, we only add protocol conformance via the ExtensionMacro
            // No members need to be added here
        } else {
            throw MacroError.notAppliedToSupportedType
        }

        return members
    }
}

// MARK: - Helper Functions

/// Checks if a variable declaration should be processed by our macros
/// (either has no access modifier or is public, but not private/internal/etc.)
private func shouldProcessVariable(_ varDecl: VariableDeclSyntax) -> Bool {
    // Check if there are any access modifiers
    let hasAccessModifier = varDecl.modifiers.contains { modifier in
        switch modifier.name.tokenKind {
        case .keyword(.public), .keyword(.private), .keyword(.internal), .keyword(.fileprivate):
            return true
        default:
            return false
        }
    }

    // If no access modifier, we should process it (it will be made public)
    if !hasAccessModifier {
        return true
    }

    // If has access modifier, only process if it's public
    return varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.public) })
}

/// Generates a DTO-style initializer for a struct declaration
/// (shared between DTOMacro and EndpointMacro for nested type processing)
private func generateDTOInitializer(for structDecl: StructDeclSyntax) throws -> InitializerDeclSyntax? {

    // Collect all stored properties that need to be initialized
    var parameters: [FunctionParameterSyntax] = []
    var assignments: [String] = []

    // Scan for all var properties in the struct that need initialization
    for member in structDecl.memberBlock.members {
        if let varDecl = member.decl.as(VariableDeclSyntax.self),
            shouldProcessVariable(varDecl)
        {

            for binding in varDecl.bindings {
                if let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                    let typeAnnotation = binding.typeAnnotation
                {

                    let propertyName = pattern.identifier.text
                    let typeName = typeAnnotation.type

                    // Create parameter with or without default value
                    if let initializer = binding.initializer {
                        // Property has default value - add it as default parameter
                        parameters.append(
                            FunctionParameterSyntax(
                                firstName: .identifier(propertyName),
                                type: typeName,
                                defaultValue: InitializerClauseSyntax(
                                    value: initializer.value
                                )
                            )
                        )
                    } else {
                        // Property has no default value - required parameter
                        parameters.append(
                            FunctionParameterSyntax(
                                firstName: .identifier(propertyName),
                                type: typeName
                            )
                        )
                    }

                    assignments.append("self.\(propertyName) = \(propertyName)")
                }
            }
        }
    }

    // Don't generate initializer if no parameters are needed
    if parameters.isEmpty {
        return nil
    }

    // Create the parameter clause
    let parameterClause = FunctionParameterClauseSyntax {
        for parameter in parameters {
            parameter
        }
    }

    // Create the body with assignments
    let bodyStatements = assignments.map { assignment in
        CodeBlockItemSyntax(
            item: .expr(ExprSyntax(stringLiteral: assignment))
        )
    }

    return InitializerDeclSyntax(
        modifiers: DeclModifierListSyntax([
            DeclModifierSyntax(name: .keyword(.public))
        ]),
        signature: FunctionSignatureSyntax(
            parameterClause: parameterClause
        )
    ) {
        for statement in bodyStatements {
            statement
        }
    }
}

// MARK: - Macro Error

enum MacroError: Error, CustomStringConvertible {
    case notAppliedToStruct
    case notAppliedToSupportedType
    case invalidArguments
    case invalidPathArgument
    case invalidMethodArgument

    var description: String {
        switch self {
        case .notAppliedToStruct:
            return "@Endpoint macro can only be applied to struct declarations"
        case .notAppliedToSupportedType:
            return "@DTO macro can only be applied to struct or enum declarations"
        case .invalidArguments:
            return "@Endpoint macro requires path and method arguments"
        case .invalidPathArgument:
            return "@Endpoint macro requires a valid string literal for the path argument"
        case .invalidMethodArgument:
            return "@Endpoint macro requires a valid EndpointMethod for the method argument"
        }
    }
}
