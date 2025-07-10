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

public protocol WorldAnchorRepresentable: CapturableAnchor, TrackableAnchor {
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

//public struct AnyWorldAnchorRepresentable: WorldAnchorRepresentable {
//    init<T: WorldAnchorRepresentable>(_ anchor: T) {
//        base = anchor
//    }
//    
//    private let base: any WorldAnchorRepresentable
//    
//    public var originFromAnchorTransform: simd_float4x4 { base.originFromAnchorTransform }
//    public var isTracked: Bool { base.isTracked }
//    public var id: UUID { base.id }
//    public var description: String { base.description }
//}
//
//extension WorldAnchorRepresentable {
//    var eraseToAny: AnyWorldAnchorRepresentable {
//        AnyWorldAnchorRepresentable(self)
//    }
//}
//
//public struct SavedWorldAnchor: TrackableAnchor, WorldAnchorRepresentable, Sendable {
//    public var id: UUID
//    public var originFromAnchorTransform: simd_float4x4
//    public var isTracked: Bool
//    public var description: String { "World \(originFromAnchorTransform)" }
//
//    public init(id: UUID, originFromAnchorTransform: simd_float4x4, isTracked: Bool) {
//        self.id = id
//        self.originFromAnchorTransform = originFromAnchorTransform
//        self.isTracked = isTracked
//    }
//}
//
//extension WorldAnchorRepresentable {
//    public var captured: AnyWorldAnchorRepresentable { eraseToAny }
//    public var saved: AnyWorldAnchorRepresentable { eraseToAny }
//}
