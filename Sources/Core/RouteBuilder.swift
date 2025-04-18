//
//  RouteBuilder.swift
//  swift-api
//
//  Created by Kai Shao on 2025/4/17.
//

@resultBuilder
public struct RouteBuilder {
    public static func buildBlock() -> [any RouteKind] {
        return []
    }

    public static func buildBlock(_ components: any RouteKind...) -> [any RouteKind] {
        components
    }

    public static func buildExpression(_ expression: any RouteKind) -> any RouteKind {
        expression
    }

    public static func buildBlock(_ components: [any RouteKind]...) -> [any RouteKind] {
        return components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [any RouteKind]?) -> [any RouteKind] {
        return component ?? []
    }
}

public typealias Routes = [any RouteKind]
