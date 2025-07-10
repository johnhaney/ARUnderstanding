//
//  PlaneDetectionProvider.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/4/25.
//

#if os(iOS)
import Foundation
import ARKit
import RealityKit

@available(macCatalyst, unavailable)
@available(iOS, introduced: 18.0)
final public class PlaneDetectionProvider: AnchorCapturingDataProvider {
    typealias AnchorType = ARPlaneAnchor
    
    var anchorCapabilities: Set<SpatialTrackingSession.Configuration.AnchorCapability> { [.plane] }
    var sceneUnderstanding: Set<SpatialTrackingSession.Configuration.SceneUnderstandingCapability> { [] }

    var continuations: [UUID : AsyncStream<ARUnderstandingSession.Message>.Continuation] = [:]
    
    var planeDetection: ARWorldTrackingConfiguration.PlaneDetection
    
    init(_ planeDetection: ARWorldTrackingConfiguration.PlaneDetection) {
        self.planeDetection = planeDetection
    }
    
    func configure(_ configuration: inout ARWorldTrackingConfiguration) {
        configuration.planeDetection = planeDetection
    }
    
    func configure(_ configuration: inout ARBodyTrackingConfiguration) {
        configuration.planeDetection = planeDetection
    }

    public var state: DataProviderState = .initialized
    
    public static var requiredAuthorizations: [ARKitSession.AuthorizationType] { [] }
    
    public static var isSupported: Bool { true }
    
    public var description: String { "PlaneDetectionProvider" }
    
    func capture(anchor: ARPlaneAnchor, timestamp: TimeInterval, event: CapturedAnchorEvent) -> CapturedAnchor? {
        anchor.captured(event, timestamp: timestamp)
    }
}
#endif
