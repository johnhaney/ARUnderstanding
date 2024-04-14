//
//  CapturedDeviceAnchor.swift
//
//
//  Created by John Haney on 4/14/24.
//

import ARKit

public protocol DeviceAnchorRepresentable: CapturableAnchor {
    var originFromAnchorTransform: simd_float4x4 { get }
    var isTracked: Bool { get }
    var id: UUID { get }
}

extension DeviceAnchor: DeviceAnchorRepresentable {}

public struct CapturedDeviceAnchor: TrackableAnchor, Sendable {
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
