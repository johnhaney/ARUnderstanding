//
//  CapturedDeviceAnchor.swift
//
//
//  Created by John Haney on 4/14/24.
//

#if canImport(ARKit)
import ARKit
#else
import Foundation
import RealityKit
#endif

public protocol DeviceAnchorRepresentable: CapturableAnchor, Hashable {
    var originFromAnchorTransform: simd_float4x4 { get }
    var isTracked: Bool { get }
    var id: UUID { get }
}

extension DeviceAnchorRepresentable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isTracked)
        hasher.combine(originFromAnchorTransform)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.isTracked == rhs.isTracked && lhs.originFromAnchorTransform == rhs.originFromAnchorTransform
    }
}

public struct CapturedDeviceAnchor: DeviceAnchorRepresentable, TrackableAnchor, Sendable {
    public var id: UUID
    public var originFromAnchorTransform: simd_float4x4
    public var isTracked: Bool
    public var description: String { "Device \(originFromAnchorTransform)" }
    
    public init(id: UUID, originFromAnchorTransform: simd_float4x4, isTracked: Bool) {
        self.id = id
        self.originFromAnchorTransform = originFromAnchorTransform
        self.isTracked = isTracked
    }
}

extension DeviceAnchorRepresentable {
    public var captured: CapturedDeviceAnchor {
        CapturedDeviceAnchor(id: id, originFromAnchorTransform: originFromAnchorTransform, isTracked: isTracked)
    }
}

//public struct AnyDeviceAnchorRepresentable: DeviceAnchorRepresentable {
//    init<T: DeviceAnchorRepresentable>(_ anchor: T) {
//        base = anchor
//    }
//    
//    private let base: any DeviceAnchorRepresentable
//    
//    public var originFromAnchorTransform: simd_float4x4 { base.originFromAnchorTransform }
//    public var isTracked: Bool { base.isTracked }
//    public var id: UUID { base.id }
//    public var description: String { base.description }
//}
//
//extension DeviceAnchorRepresentable {
//    var eraseToAny: AnyDeviceAnchorRepresentable {
//        AnyDeviceAnchorRepresentable(self)
//    }
//}
//
//public struct SavedDeviceAnchor: DeviceAnchorRepresentable, CapturableAnchor, TrackableAnchor, Sendable {
//    public var id: UUID
//    public var originFromAnchorTransform: simd_float4x4
//    public var isTracked: Bool
//    public var description: String { "Device \(originFromAnchorTransform)" }
//    
//    public init(id: UUID, originFromAnchorTransform: simd_float4x4, isTracked: Bool) {
//        self.id = id
//        self.originFromAnchorTransform = originFromAnchorTransform
//        self.isTracked = isTracked
//    }
//}
//
//extension DeviceAnchorRepresentable {
//    public var captured: AnyDeviceAnchorRepresentable { eraseToAny }
//    public var saved: AnyDeviceAnchorRepresentable { eraseToAny }
//}
