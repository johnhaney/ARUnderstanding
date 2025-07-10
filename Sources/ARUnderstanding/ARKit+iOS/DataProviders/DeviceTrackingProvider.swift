//
//  DeviceTrackingProvider.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/4/25.
//

#if os(iOS)
import Foundation
import ARKit
import RealityKit

final public class DeviceTrackingProvider: FrameCapturingDataProvider {
    func configure(_ configuration: inout ARWorldTrackingConfiguration) {
        configuration.planeDetection.insert(.horizontal)
        configuration.planeDetection.insert(.vertical)
        configuration.sceneReconstruction = .meshWithClassification
    }

    var emitted: Bool = false
    var floorHeight: Float?
    var identityTransform: Transform?
    let deviceID = UUID()
    
    var anchorCapabilities: Set<SpatialTrackingSession.Configuration.AnchorCapability> { [.camera] }
    var sceneUnderstanding: Set<SpatialTrackingSession.Configuration.SceneUnderstandingCapability> { [] }

    var continuations: [UUID : AsyncStream<ARUnderstandingSession.Message>.Continuation] = [:]
    
    public var state: DataProviderState = .initialized
    
    public static var requiredAuthorizations: [ARKitSession.AuthorizationType] { [] }
    
    public static var isSupported: Bool { true }
    
    public var description: String { "DeviceTrackingProvider" }
    
    func computeFloorHeight(_ anchors: [ARAnchor]) -> Float? {
        let heights: [Float] = anchors.compactMap({ $0 as? ARPlaneAnchor }).filter({ $0.classification == .floor }).map({ Transform(matrix: $0.transform).translation.y })
        guard !heights.isEmpty else { return nil }
        floorHeight = heights.reduce(0, +) / Float(heights.count)
        return floorHeight
    }
    
    func capture(session: ARSession, frame: ARFrame) -> [CapturedAnchor] {
        let event: CapturedAnchorEvent
        // make sure we have calculated a floor position so far
        if let floorHeight {
            event = .updated
        } else {
            // make sure we do calculate a floor position
            guard let floorHeight = computeFloorHeight(frame.anchors) else { return [] }
            // update the world reference to set the floor to be height zero
            session.setWorldOrigin(relativeTransform: Transform(translation: [0,floorHeight,0]).matrix)
            event = .added
        }
        
        return [CapturedAnchor.device(CapturedAnchorUpdate<CapturedDeviceAnchor>(anchor: CapturedDeviceAnchor(id: deviceID, originFromAnchorTransform: frame.camera.transform, isTracked: true), timestamp: frame.timestamp, event: event))]
    }
}
#endif
