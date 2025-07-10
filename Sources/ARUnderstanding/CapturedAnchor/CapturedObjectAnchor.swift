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
    public var description: String { "Object \(originFromAnchorTransform)" }

    public init(id: UUID, originFromAnchorTransform: simd_float4x4, referenceObjectName: String, isTracked: Bool) {
        self.id = id
        self.originFromAnchorTransform = originFromAnchorTransform
        self.isTracked = isTracked
        self.referenceObjectName = referenceObjectName
    }
}

extension ObjectAnchorRepresentable {
    public var captured: CapturedObjectAnchor {
        CapturedObjectAnchor(id: id, originFromAnchorTransform: originFromAnchorTransform, referenceObjectName: referenceObjectName, isTracked: isTracked)
    }
}

//public struct AnyObjectAnchorRepresentable: ObjectAnchorRepresentable {
//    init<T: ObjectAnchorRepresentable>(_ anchor: T) {
//        base = anchor
//    }
//    
//    private let base: any ObjectAnchorRepresentable
//    
//    public var originFromAnchorTransform: simd_float4x4 { base.originFromAnchorTransform }
//    public var isTracked: Bool { base.isTracked }
//    public var id: UUID { base.id }
//    public var referenceObjectName: String { base.referenceObjectName }
//    public var description: String { base.description }
//}
//
//extension ObjectAnchorRepresentable {
//    var eraseToAny: AnyObjectAnchorRepresentable {
//        AnyObjectAnchorRepresentable(self)
//    }
//}
//
//public struct SavedObjectAnchor: CapturableAnchor, ObjectAnchorRepresentable, Sendable {
//    public var id: UUID
//    public var originFromAnchorTransform: simd_float4x4
//    public var isTracked: Bool
//    public var referenceObjectName: String
//    public var description: String { "Object \(originFromAnchorTransform)" }
//
//    public init(id: UUID, originFromAnchorTransform: simd_float4x4, referenceObjectName: String, isTracked: Bool) {
//        self.id = id
//        self.originFromAnchorTransform = originFromAnchorTransform
//        self.isTracked = isTracked
//        self.referenceObjectName = referenceObjectName
//    }
//}
//
//extension ObjectAnchorRepresentable {
//    public var captured: AnyObjectAnchorRepresentable { eraseToAny }
//    public var saved: AnyObjectAnchorRepresentable { eraseToAny }
//}
