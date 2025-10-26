//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 10/5/25.
//

#if canImport(ARKit)
import ARKit
#endif
import Foundation
#if canImport(RealityKit)
import RealityKit
#endif
import simd
import GameController

public protocol AccessoryAnchorRepresentable: CapturableAnchor, TrackableAnchor {
    associatedtype Accessory: AccessoryRepresentable
    var originFromAnchorTransform: simd_float4x4 { get }
    var isTracked: Bool { get }
    var trackingState: AccessoryAnchor.TrackingState { get }
    var accessory: Accessory { get }
    var heldChirality: ARKit.Accessory.Chirality? { get }
    var velocity: SIMD3<Float> { get }
    var angularVelocity: SIMD3<Float> { get }
    var description: String { get }
    var id: UUID { get }
}

public protocol AccessoryRepresentable {
    var id: UUID { get }
    var inherentChirality: Accessory.Chirality { get }
    var name: String { get }
    var locations: [Accessory.LocationName] { get }
    var source: Accessory.Source { get }
    var usdzFile: URL? { get }
    var description: String { get }
    
    var captured: CapturedAccessory { get }
}

extension AccessoryAnchorRepresentable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension AccessoryAnchor.TrackingState: @unchecked Sendable {}
extension Accessory.Chirality: @unchecked Sendable {}

public struct CapturedAccessory: AccessoryRepresentable, Sendable {
    public var id: UUID
    public var inherentChirality: Accessory.Chirality { original?.inherentChirality ?? .unspecified }
    public var name: String { original?.name ?? "CapturedAccessory" }
    public var locations: [Accessory.LocationName] { original?.locations ?? [] }
    public var source: Accessory.Source { original?.source ?? .device(CapturedGCDevice()) }
    public var usdzFile: URL? { original?.usdzFile }
    public var description: String { original?.description ?? "CapturedAccessory" }
    private var original: Accessory?
    init(accessory: Accessory) {
        id = original?.id ?? UUID()
        original = accessory
    }
    
    init() {
        id = UUID()
        original = nil
    }
    
    public var captured: CapturedAccessory { self }
}

public class CapturedGCDevice: NSObject, GCDevice {
    public var handlerQueue: dispatch_queue_t
    public var vendorName: String?
    public var productCategory: String
    public var physicalInputProfile: GCPhysicalInputProfile
    
    init(_ device: GCDevice) {
        handlerQueue = device.handlerQueue
        vendorName = device.vendorName
        productCategory = device.productCategory
        physicalInputProfile = device.physicalInputProfile
    }
    
    override init() {
        handlerQueue = dispatch_queue_t(label: "CapturedGCDevice")
        productCategory = GCProductCategorySpatialStylus
        physicalInputProfile = GCPhysicalInputProfile()
        super.init()
    }
}

public struct CapturedAccessoryAnchor: TrackableAnchor, AccessoryAnchorRepresentable, Sendable {
    public typealias Accessory = CapturedAccessory
    public var id: UUID
    public var originFromAnchorTransform: simd_float4x4
    public var isTracked: Bool
    public var trackingState: AccessoryAnchor.TrackingState
    public var accessory: Accessory
    public var heldChirality: ARKit.Accessory.Chirality?
    public var velocity: SIMD3<Float>
    public var angularVelocity: SIMD3<Float>
    public var description: String { "Accessory \(originFromAnchorTransform)" }

    public init(id: UUID, originFromAnchorTransform: simd_float4x4, isTracked: Bool, trackingState: AccessoryAnchor.TrackingState, accessory: Accessory, heldChirality: ARKit.Accessory.Chirality?, velocity: SIMD3<Float>, angularVelocity: SIMD3<Float>) {
        self.id = id
        self.originFromAnchorTransform = originFromAnchorTransform
        self.isTracked = isTracked
        self.trackingState = trackingState
        self.accessory = accessory
        self.heldChirality = heldChirality
        self.velocity = velocity
        self.angularVelocity = angularVelocity
    }
}

extension AccessoryAnchorRepresentable {
    public var captured: CapturedAccessoryAnchor {
        CapturedAccessoryAnchor(id: id, originFromAnchorTransform: originFromAnchorTransform, isTracked: isTracked, trackingState: trackingState, accessory: accessory.captured, heldChirality: heldChirality, velocity: velocity, angularVelocity: angularVelocity)
    }
}
