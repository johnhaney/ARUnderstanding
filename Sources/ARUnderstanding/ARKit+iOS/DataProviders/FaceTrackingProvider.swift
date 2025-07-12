//
//  FaceTrackingProvider.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/1/25.
//

#if os(iOS)
import Foundation
import ARKit
import RealityKit

@available(macCatalyst, unavailable)
@available(iOS, introduced: 18.0)
final public class FaceTrackingProvider: AnchorCapturingDataProvider {
    typealias AnchorType = ARFaceAnchor
    
    var anchorCapabilities: Set<SpatialTrackingSession.Configuration.AnchorCapability> { [.face] }
    var sceneUnderstanding: Set<SpatialTrackingSession.Configuration.SceneUnderstandingCapability> { [] }

    var continuations: [UUID : AsyncStream<ARUnderstandingSession.Message>.Continuation] = [:]

    func configure(_ configuration: inout ARWorldTrackingConfiguration) {
        if ARWorldTrackingConfiguration.supportsUserFaceTracking {
            configuration.userFaceTrackingEnabled = true
        }
    }
    
    public var state: DataProviderState = .initialized
    
    public static var requiredAuthorizations: [ARKitSession.AuthorizationType] { [] }
    
    public static var isSupported: Bool { true }
    
    public var description: String { "FaceTrackingProvider" }
    
    func capture(anchor: ARFaceAnchor, timestamp: TimeInterval, event: CapturedAnchorEvent) -> CapturedAnchor? {
        anchor.captured(event, timestamp: timestamp)
    }
}
#endif
