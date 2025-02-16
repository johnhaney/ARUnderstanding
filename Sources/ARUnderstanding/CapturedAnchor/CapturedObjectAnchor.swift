//
//  CapturedObjectAnchor.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/10/25.
//

#if canImport(ARKit)
import ARKit
#else
import Foundation
import RealityKit
#endif

public protocol ObjectAnchorRepresentable: CapturableAnchor {
    var originFromAnchorTransform: simd_float4x4 { get }
    var isTracked: Bool { get }
    var referenceObjectName: String { get }
    var id: UUID { get }
}

extension ObjectAnchorRepresentable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

public struct CapturedObjectAnchor: TrackableAnchor, ObjectAnchorRepresentable, Sendable {
    public var id: UUID
    public var originFromAnchorTransform: simd_float4x4
    public var isTracked: Bool
    public var referenceObjectName: String
    public var timestamp: TimeInterval
    public var description: String { "Object \(originFromAnchorTransform)" }

    public init(id: UUID, originFromAnchorTransform: simd_float4x4, referenceObjectName: String, isTracked: Bool, timestamp: TimeInterval) {
        self.id = id
        self.originFromAnchorTransform = originFromAnchorTransform
        self.isTracked = isTracked
        self.referenceObjectName = referenceObjectName
        self.timestamp = timestamp
    }
}

extension ObjectAnchorRepresentable {
    public var captured: CapturedObjectAnchor {
        CapturedObjectAnchor(id: id, originFromAnchorTransform: originFromAnchorTransform, referenceObjectName: referenceObjectName, isTracked: isTracked, timestamp: timestamp)
    }
}
