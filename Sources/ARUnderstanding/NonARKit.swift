//
//  NonARKit.swift
//  ARUnderstanding
//
//  Created by John Haney on 1/28/25.
//

#if !os(visionOS)
import Foundation
import RealityKit

public protocol Anchor: Sendable, Equatable, Identifiable, Hashable {
    var id: UUID { get }
    var timestamp: TimeInterval { get }
    var originFromAnchorTransform: simd_float4x4 { get }
}

public struct AnchorUpdate<AnchorType> where AnchorType : Anchor {
    public let anchor: AnchorType
    public let timestamp: TimeInterval
    public let event: AnchorUpdate<AnchorType>.Event
    public let description: String

    @frozen
    public enum Event {
        case added
        case updated
        case removed
    }
}

public protocol TrackableAnchor: Anchor {
    var isTracked: Bool { get }
}

extension CapturedAnchorUpdate {
    var captured: Self { self }
}

final public class HandTrackingProvider: DataProvider,  HandTrackingProviderRepresentable, Sendable {
    public static var isSupported: Bool { true }
    public static var requiredAuthorizations: [ARKitSession.AuthorizationType] { [] }
    public let state: DataProviderState = .running
    
    public var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedHandAnchor>> {
        AsyncStream { nil }
    }
    
    public let latestAnchors: ((any HandAnchorRepresentable)?, (any HandAnchorRepresentable)?) = (nil, nil)
    
    public var description: String { "HandTrackingProvider mock"}
}

final public class ImageTrackingProvider: DataProvider,  ImageTrackingProviderRepresentable, Sendable {
    public static var requiredAuthorizations: [ARKitSession.AuthorizationType] { [] }
    public static var isSupported: Bool { true }
    public var description: String { "ImageTrackingProvider mock" }
    public var isSupported: Bool { true }
    public init(referenceImages: [ReferenceImage]) {}
    public var state: DataProviderState { .running }
    public var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedImageAnchor>> {
        AsyncStream { nil }
    }
}

public struct ReferenceImage {
    static func loadReferenceImages(inGroupNamed: String) -> [ReferenceImage] { [] }
}

final public class PlaneDetectionProvider: DataProvider,  PlaneDetectionProviderRepresentable, Sendable {
    public static var requiredAuthorizations: [ARKitSession.AuthorizationType] { [] }
    public static var isSupported: Bool { true }
    public var description: String { "PlaneDetectionProvider" }
    public var state: DataProviderState { .running }
    public init(alignments: [PlaneAnchor.Alignment]) {}
    public var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedPlaneAnchor>> {
        AsyncStream { nil }
    }
}

final public class SceneReconstructionProvider: DataProvider,  SceneReconstructionProviderRepresentable, Sendable {
    public static var requiredAuthorizations: [ARKitSession.AuthorizationType] { [] }
    
    public static var isSupported: Bool { true }
    
    public var description: String { "SceneReconstructionProvider" }
    public var state: DataProviderState { .running }
    public enum Mode: Sendable {
        case classification
    }
    public init(modes: [Mode] = []) {}
    public var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedMeshAnchor>> {
        AsyncStream { nil }
    }
}

final public class WorldTrackingProvider: DataProvider, WorldTrackingProviderRepresentable, Sendable {
    public static var requiredAuthorizations: [ARKitSession.AuthorizationType] { [] }
    
    public static var isSupported: Bool { true }
    public var description: String { "WorldTrackingProvider" }
    public var state: DataProviderState { .running }
    public init() {}
    public var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedWorldAnchor>> {
        AsyncStream { nil }
    }
    
    public func queryDeviceAnchor(atTimestamp timestamp: TimeInterval) -> CapturedDeviceAnchor? {
        nil
    }
}

public enum DataProviderState: Sendable {
    case initialized
    case running
    case stopped
    case paused
}

public protocol DataProvider : AnyObject, CustomStringConvertible, Sendable {
    var state: DataProviderState { get }
    static var requiredAuthorizations: [ARKitSession.AuthorizationType] { get }
    static var isSupported: Bool { get }
}

public struct ARKitSession: Sendable {
    public enum AuthorizationType {
        
    }
    
    public enum AuthorizationStatus {
        
    }
    
    func run(_ providers: [DataProvider]) {}
    var events: Events { Events() }
    
    public struct Events {
    }
    public enum Event {
        case authorizationChanged(type: ARKitSession.AuthorizationType, status: ARKitSession.AuthorizationStatus)
        case dataProviderStateChanged(dataProviders: [any DataProvider], newState: DataProviderState, error: ARKitSession.Error?)
    }
    
    public enum Error: Swift.Error {
        
    }
}
#endif
