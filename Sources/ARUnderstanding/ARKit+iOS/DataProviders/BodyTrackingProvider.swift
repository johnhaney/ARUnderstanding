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

@available(macCatalyst, unavailable)
@available(iOS, introduced: 18.0)
final public class BodyTrackingProvider: AnchorCapturingDataProvider {
    typealias AnchorType = ARBodyAnchor
    
    var anchorCapabilities: Set<SpatialTrackingSession.Configuration.AnchorCapability> { [.body] }
    var sceneUnderstanding: Set<SpatialTrackingSession.Configuration.SceneUnderstandingCapability> { [] }
    
    var continuations: [UUID : AsyncStream<ARUnderstandingSession.Message>.Continuation] = [:]
    
    func configure(_ configuration: inout ARBodyTrackingConfiguration) {
        configuration.worldAlignment = .gravity
        if configuration.frameSemantics.isEmpty {
            configuration.frameSemantics = [.bodyDetection]
        }
    }
    
    func configure(_ configuration: inout ARWorldTrackingConfiguration) {
        configuration.worldAlignment = .gravity
        if configuration.frameSemantics.isEmpty {
            configuration.frameSemantics = [.bodyDetection]
        }
    }
    
    public var state: DataProviderState = .initialized
    
    public static var requiredAuthorizations: [ARKitSession.AuthorizationType] { [] }
    
    public static var isSupported: Bool { ARBodyTrackingConfiguration.isSupported }
    
    public var description: String { "BodyTrackingProvider" }
    
    func capture(anchor: ARBodyAnchor, timestamp: TimeInterval, event: CapturedAnchorEvent) -> CapturedAnchor? {
        anchor.captured(event, timestamp: timestamp)
    }
}
#endif
