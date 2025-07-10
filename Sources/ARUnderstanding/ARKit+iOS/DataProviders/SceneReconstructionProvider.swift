//
//  MeshTrackingProvider.swift
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
final public class SceneReconstructionProvider: AnchorCapturingDataProvider {
    typealias AnchorType = ARMeshAnchor
    
    var anchorCapabilities: Set<SpatialTrackingSession.Configuration.AnchorCapability> { [.world] }
    var sceneUnderstanding: Set<SpatialTrackingSession.Configuration.SceneUnderstandingCapability> { [.collision, .occlusion, .physics, .shadow] }

    var continuations: [UUID : AsyncStream<ARUnderstandingSession.Message>.Continuation] = [:]
    var reconstruction: ARConfiguration.SceneReconstruction
    
    init(_ reconstruction: ARConfiguration.SceneReconstruction) {
        self.reconstruction = reconstruction
    }
    
    func configure(_ configuration: inout ARWorldTrackingConfiguration) {
        configuration.sceneReconstruction = reconstruction
    }
    
    func configure(_ configuration: inout ARBodyTrackingConfiguration) {
        configuration.planeDetection = [.horizontal, .vertical]
    }
    
    public var state: DataProviderState = .initialized
    
    public static var requiredAuthorizations: [ARKitSession.AuthorizationType] { [] }
    
    public static var isSupported: Bool { true }
    
    public var description: String { "SceneReconstructionProvider" }
    
    func capture(anchor: ARMeshAnchor, timestamp: TimeInterval, event: CapturedAnchorEvent) -> CapturedAnchor? {
        anchor.captured(event, timestamp: timestamp)
    }
}
#endif
