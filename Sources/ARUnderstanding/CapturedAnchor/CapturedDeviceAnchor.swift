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
    public var timestamp: TimeInterval
    public var description: String { "Device \(originFromAnchorTransform)" }
    
    public init(id: UUID, originFromAnchorTransform: simd_float4x4, isTracked: Bool, timestamp: TimeInterval) {
        self.id = id
        self.originFromAnchorTransform = originFromAnchorTransform
        self.isTracked = isTracked
        self.timestamp = timestamp
    }
}

extension DeviceAnchorRepresentable {
    public var captured: CapturedDeviceAnchor {
        CapturedDeviceAnchor(id: id, originFromAnchorTransform: originFromAnchorTransform, isTracked: isTracked, timestamp: timestamp)
    }
}

extension simd_float4x4: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(columns.0)
        hasher.combine(columns.1)
        hasher.combine(columns.2)
        hasher.combine(columns.3)
    }
}
