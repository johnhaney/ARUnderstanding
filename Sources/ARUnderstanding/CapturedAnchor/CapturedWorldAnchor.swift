//
//  CapturedWorldAnchor.swift
//
//
//  Created by John Haney on 4/13/24.
//

#if os(visionOS)
import ARKit

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

extension WorldAnchor: WorldAnchorRepresentable {}

public struct CapturedWorldAnchor: TrackableAnchor, WorldAnchorRepresentable, Sendable {
    public var id: UUID
    public var originFromAnchorTransform: simd_float4x4
    public var isTracked: Bool
    public var description: String { "World \(originFromAnchorTransform)" }

    public init(id: UUID, originFromAnchorTransform: simd_float4x4, isTracked: Bool) {
        self.id = id
        self.originFromAnchorTransform = originFromAnchorTransform
        self.isTracked = isTracked
    }
}

extension WorldAnchorRepresentable {
    public var captured: CapturedWorldAnchor {
        CapturedWorldAnchor(id: id, originFromAnchorTransform: originFromAnchorTransform, isTracked: isTracked)
    }
}
#endif
