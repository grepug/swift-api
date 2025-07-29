//
//  Plugin.swift
//  swift-api
//
//  Created by GitHub Copilot on 2025/7/29.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EndpointMacro.self,
        EndpointGroupMacro.self,
    ]
}
