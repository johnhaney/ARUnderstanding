//
//  BodyTrackingProvider.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/4/25.
//

#if os(iOS)
import Foundation
import ARKit
import RealityKit

final public class BodyTrackingProvider: AnchorCapturingDataProvider {
    typealias AnchorType = ARBodyAnchor
    
    var anchorCapabilities: Set<SpatialTrackingSession.Configuration.AnchorCapability> { [.body] }
    var sceneUnderstanding: Set<SpatialTrackingSession.Configuration.SceneUnderstandingCapability> { [] }
    
    var continuations: [UUID : AsyncStream<ARUnderstandingSession.Message>.Continuation] = [:]
    
    func configure(_ configuration: inout ARWorldTrackingConfiguration) {
        if configuration.frameSemantics.isEmpty {
            configuration.frameSemantics = [.bodyDetection]
        }
    }
    
    public var state: DataProviderState = .initialized
    
    public static var requiredAuthorizations: [ARKitSession.AuthorizationType] { [] }
    
    public static var isSupported: Bool { true }
    
    public var description: String { "BodyTrackingProvider" }
    
    func capture(anchor: ARBodyAnchor, timestamp: TimeInterval, event: CapturedAnchorEvent) -> CapturedAnchor? {
        anchor.captured(event, timestamp: timestamp)
    }
}
#endif
