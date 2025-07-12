//
//  ObjectTrackingProvider.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/5/25.
//

#if os(iOS)
import Foundation
import ARKit
import RealityKit

@available(macCatalyst, unavailable)
@available(iOS, introduced: 18.0)
final public class ObjectTrackingProvider: AnchorCapturingDataProvider {
    typealias AnchorType = ARObjectAnchor
    
    var anchorCapabilities: Set<SpatialTrackingSession.Configuration.AnchorCapability> { [.object] }
    var sceneUnderstanding: Set<SpatialTrackingSession.Configuration.SceneUnderstandingCapability> { [] }

    var continuations: [UUID : AsyncStream<ARUnderstandingSession.Message>.Continuation] = [:]

    let referenceObjects: [ARReferenceObject]
    
    init(referenceObjects: [ARReferenceObject]) {
        self.referenceObjects = referenceObjects
    }
    
    func configure(_ configuration: inout ARWorldTrackingConfiguration) {
        configuration.detectionObjects = Set(referenceObjects)
    }
    
    func configure(_ configuration: inout ARBodyTrackingConfiguration) {}

    public var state: DataProviderState = .initialized
    
    public static var requiredAuthorizations: [ARKitSession.AuthorizationType] { [] }
    
    public static var isSupported: Bool { true }
    
    public var description: String { "ObjectTrackingProvider" }
    
    func capture(anchor: ARObjectAnchor, timestamp: TimeInterval, event: CapturedAnchorEvent) -> CapturedAnchor? {
        anchor.captured(event, timestamp: timestamp)
    }
}
#endif
