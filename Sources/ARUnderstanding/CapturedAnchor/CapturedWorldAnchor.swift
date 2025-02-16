//
//  CapturedWorldAnchor.swift
//
//
//  Created by John Haney on 4/13/24.
//

#if canImport(ARKit)
import ARKit
#endif
import Foundation
import RealityKit

public protocol WorldAnchorRepresentable: CapturableAnchor {
    var originFromAnchorTransform: simd_float4x4 { get }
    var isTracked: Bool { get }
    var id: UUID { get }
}

extension WorldAnchorRepresentable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

public struct CapturedWorldAnchor: TrackableAnchor, WorldAnchorRepresentable, Sendable {
    public var id: UUID
    public var originFromAnchorTransform: simd_float4x4
    public var isTracked: Bool
    public var description: String { "World \(originFromAnchorTransform)" }
    public var timestamp: TimeInterval

    public init(id: UUID, originFromAnchorTransform: simd_float4x4, isTracked: Bool, timestamp: TimeInterval) {
        self.id = id
        self.originFromAnchorTransform = originFromAnchorTransform
        self.isTracked = isTracked
        self.timestamp = timestamp
    }
}

extension WorldAnchorRepresentable {
    public var captured: CapturedWorldAnchor {
        CapturedWorldAnchor(id: id, originFromAnchorTransform: originFromAnchorTransform, isTracked: isTracked, timestamp: timestamp)
    }
}
