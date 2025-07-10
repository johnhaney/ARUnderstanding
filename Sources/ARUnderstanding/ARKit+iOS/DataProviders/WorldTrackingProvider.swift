//
//  WorldTrackingProvider.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/4/25.
//

#if os(iOS)
import Foundation
import ARKit
import RealityKit

final public class WorldTrackingProvider: AnchorCapturingDataProvider {
    typealias AnchorType = ARAnchor
    
    var anchorCapabilities: Set<SpatialTrackingSession.Configuration.AnchorCapability> { [.world] }
    var sceneUnderstanding: Set<SpatialTrackingSession.Configuration.SceneUnderstandingCapability> { [] }

    var continuations: [UUID : AsyncStream<ARUnderstandingSession.Message>.Continuation] = [:]
    
    public var state: DataProviderState = .initialized
    
    public static var requiredAuthorizations: [ARKitSession.AuthorizationType] { [] }
    
    public static var isSupported: Bool { true }
    
    public var description: String { "WorldTrackingProvider" }
    
    func capture(anchor: ARAnchor, timestamp: TimeInterval, event: CapturedAnchorEvent) -> CapturedAnchor? {
        guard type(of: anchor) == ARAnchor.self
        else { return nil }
        
        let captured = CapturedWorldAnchor(id: anchor.identifier, originFromAnchorTransform: anchor.transform, isTracked: true)
        return .world(CapturedAnchorUpdate(anchor: captured, timestamp: timestamp, event: event))
    }
}
#endif
