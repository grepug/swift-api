//
//  EndpointGrouping.swift
//  swift-api
//
//  Created by GitHub Copilot on 2025/7/29.
//

import Foundation

/// A protocol for endpoint groups that have a name
public protocol EndpointGroupNaming {
    static var groupName: String { get }
}

/// A utility for creating grouped endpoint paths
public struct EndpointPathGrouping {
    /// Creates a grouped path by prepending the group name
    /// - Parameters:
    ///   - groupName: The name of the group to prepend
    ///   - endpointPath: The original endpoint path
    /// - Returns: The grouped path
    public static func groupedPath(groupName: String, endpointPath: String) -> String {
        // Ensure we don't double-add group names
        if endpointPath.hasPrefix("/\(groupName)/") {
            return endpointPath
        }

        // Handle root path
        if endpointPath == "/" {
            return "/\(groupName)"
        }

        // Handle paths that start with /
        if endpointPath.hasPrefix("/") {
            return "/\(groupName)\(endpointPath)"
        }

        // Handle paths that don't start with /
        return "/\(groupName)/\(endpointPath)"
    }
}

/// Convenience function for creating grouped paths
public func groupedPath(_ groupName: String, _ endpointPath: String) -> String {
    return EndpointPathGrouping.groupedPath(groupName: groupName, endpointPath: endpointPath)
}
