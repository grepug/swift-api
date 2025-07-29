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
        let (path, method) = try extractPathAndMethod(from: node)

        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroError.notAppliedToStruct
        }

        var members: [DeclSyntax] = []

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
                            item: .expr(ExprSyntax(StringLiteralExprSyntax(content: path)))
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

        // Check if RequestBody type exists
        let hasRequestBody = structDecl.memberBlock.members.contains { member in
            if let typeDecl = member.decl.as(StructDeclSyntax.self) {
                return typeDecl.name.text == "RequestBody"
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

        // Add body property if RequestBody exists but no body property
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
                        type: IdentifierTypeSyntax(name: .identifier("RequestBody"))
                    )
                )
            }
            members.append(DeclSyntax(bodyProperty))
        }

        // Add initializer if RequestBody exists but no initializer
        if hasRequestBody && !hasInitializer {
            let initializer = InitializerDeclSyntax(
                modifiers: DeclModifierListSyntax([
                    DeclModifierSyntax(name: .keyword(.public))
                ]),
                signature: FunctionSignatureSyntax(
                    parameterClause: FunctionParameterClauseSyntax {
                        FunctionParameterSyntax(
                            firstName: .identifier("body"),
                            type: IdentifierTypeSyntax(name: .identifier("RequestBody"))
                        )
                    }
                )
            ) {
                ExprSyntax("self.body = body")
            }
            members.append(DeclSyntax(initializer))
        }

        // Check if RequestQuery type exists
        let hasRequestQuery = structDecl.memberBlock.members.contains { member in
            if let typeDecl = member.decl.as(StructDeclSyntax.self) {
                return typeDecl.name.text == "RequestQuery"
            }
            return false
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

        // Add query property if RequestQuery exists but no query property
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
                        type: IdentifierTypeSyntax(name: .identifier("RequestQuery"))
                    ),
                    initializer: InitializerClauseSyntax(
                        value: FunctionCallExprSyntax(
                            calledExpression: DeclReferenceExprSyntax(baseName: .identifier("RequestQuery")),
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

    // MARK: - Helper Methods

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
}

/// Implementation of the `@EndpointGroup` macro, which modifies endpoint paths
/// by prepending a group name to all Endpoint types in an extension.
public struct EndpointGroupMacro: PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        // Extract the group name from the macro arguments
        guard let groupName = extractGroupName(from: node) else {
            throw MacroError.missingGroupName
        }

        // For enum declarations, add a static groupName property
        if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            let enumName = enumDecl.name.text

            // Create an extension that adds the groupName property
            let groupNameExtension = ExtensionDeclSyntax(
                extendedType: IdentifierTypeSyntax(name: .identifier("EP.\(enumName)"))
            ) {
                VariableDeclSyntax(
                    modifiers: DeclModifierListSyntax([
                        DeclModifierSyntax(name: .keyword(.public)),
                        DeclModifierSyntax(name: .keyword(.static)),
                    ]),
                    bindingSpecifier: .keyword(.var)
                ) {
                    PatternBindingSyntax(
                        pattern: IdentifierPatternSyntax(identifier: .identifier("groupName")),
                        typeAnnotation: TypeAnnotationSyntax(
                            type: IdentifierTypeSyntax(name: .identifier("String"))
                        ),
                        initializer: InitializerClauseSyntax(
                            value: StringLiteralExprSyntax(content: groupName)
                        )
                    )
                }
            }

            return [DeclSyntax(groupNameExtension)]
        }

        // For extension declarations, we'll generate the path modifications
        if let extensionDecl = declaration.as(ExtensionDeclSyntax.self) {
            var peerDeclarations: [DeclSyntax] = []

            // Find all struct declarations that conform to Endpoint and create path modifications
            for member in extensionDecl.memberBlock.members {
                if let structDecl = member.decl.as(StructDeclSyntax.self),
                    structConformsToEndpoint(structDecl)
                {

                    let structName = structDecl.name.text

                    // Find the original path value from the struct
                    let originalPath = extractOriginalPath(from: structDecl) ?? "/unknown"
                    let modifiedPath = buildGroupedPath(originalPath: originalPath, groupName: groupName)

                    // Get the full type name for the extension
                    let fullTypeName: String
                    if let memberAccess = extensionDecl.extendedType.as(MemberTypeSyntax.self) {
                        // Handle EP.Words format
                        fullTypeName = "\(memberAccess.baseType).\(memberAccess.name).\(structName)"
                    } else if let identifier = extensionDecl.extendedType.as(IdentifierTypeSyntax.self) {
                        // Handle simple identifier format
                        fullTypeName = "\(identifier.name).\(structName)"
                    } else {
                        fullTypeName = "EP.Words.\(structName)"  // fallback
                    }

                    // Create an extension that overrides the path property
                    let pathExtension = ExtensionDeclSyntax(
                        extendedType: IdentifierTypeSyntax(name: .identifier(fullTypeName))
                    ) {
                        // Override the static path property
                        VariableDeclSyntax(
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
                                            item: .expr(ExprSyntax(StringLiteralExprSyntax(content: modifiedPath)))
                                        )
                                    ]))
                            )
                        }
                    }

                    peerDeclarations.append(DeclSyntax(pathExtension))
                }
            }

            return peerDeclarations
        }

        return []
    }

    // MARK: - Helper Methods

    private static func extractGroupName(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
            let firstArg = arguments.first?.expression.as(StringLiteralExprSyntax.self)
        else {
            return nil
        }

        return firstArg.segments.first?.as(StringSegmentSyntax.self)?.content.text
    }

    private static func structConformsToEndpoint(_ structDecl: StructDeclSyntax) -> Bool {
        return structDecl.inheritanceClause?.inheritedTypes.contains { inherited in
            inherited.type.as(IdentifierTypeSyntax.self)?.name.text == "Endpoint"
        } ?? false
    }

    private static func extractOriginalPath(from structDecl: StructDeclSyntax) -> String? {
        // Look for the static var path property
        for member in structDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.first,
                let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                pattern.identifier.text == "path"
            {

                // Extract the string literal value
                if let initializer = binding.initializer,
                    let stringLiteral = initializer.value.as(StringLiteralExprSyntax.self),
                    let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self)
                {
                    return segment.content.text
                }

                // Handle getter syntax
                if let accessorBlock = binding.accessorBlock,
                    case .getter(let getterItems) = accessorBlock.accessors
                {
                    for item in getterItems {
                        if let expr = item.item.as(ExprSyntax.self),
                            let stringLiteral = expr.as(StringLiteralExprSyntax.self),
                            let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self)
                        {
                            return segment.content.text
                        }
                    }
                }
            }
        }
        return nil
    }

    private static func buildGroupedPath(originalPath: String, groupName: String) -> String {
        // Ensure we don't double-add group names
        if originalPath.hasPrefix("/\(groupName)/") {
            return originalPath
        }

        // Handle root path
        if originalPath == "/" {
            return "/\(groupName)"
        }

        // Handle paths that start with /
        if originalPath.hasPrefix("/") {
            return "/\(groupName)\(originalPath)"
        }

        // Handle paths that don't start with /
        return "/\(groupName)/\(originalPath)"
    }
}

// MARK: - Macro Error

enum MacroError: Error, CustomStringConvertible {
    case missingGroupName
    case notAppliedToStruct
    case invalidArguments
    case invalidPathArgument
    case invalidMethodArgument

    var description: String {
        switch self {
        case .missingGroupName:
            return "@EndpointGroup macro requires a 'name' parameter"
        case .notAppliedToStruct:
            return "@Endpoint macro can only be applied to struct declarations"
        case .invalidArguments:
            return "@Endpoint macro requires path and method arguments"
        case .invalidPathArgument:
            return "@Endpoint macro requires a valid string literal for the path argument"
        case .invalidMethodArgument:
            return "@Endpoint macro requires a valid EndpointMethod for the method argument"
        }
    }
}
