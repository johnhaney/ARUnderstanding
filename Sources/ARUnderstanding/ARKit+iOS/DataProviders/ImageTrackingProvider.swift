//
//  ImageTrackingProvider.swift
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
final public class ImageTrackingProvider: AnchorCapturingDataProvider {
    typealias AnchorType = ARImageAnchor
    
    let resourceGroupName: String
    
    var anchorCapabilities: Set<SpatialTrackingSession.Configuration.AnchorCapability> { [.image] }
    var sceneUnderstanding: Set<SpatialTrackingSession.Configuration.SceneUnderstandingCapability> { [] }

    var continuations: [UUID : AsyncStream<ARUnderstandingSession.Message>.Continuation] = [:]

    init(resourceGroupName: String) {
        self.resourceGroupName = resourceGroupName
    }
    
    func configure(_ configuration: inout ARWorldTrackingConfiguration) {
        if let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) {
            configuration.detectionImages = referenceImages
            configuration.maximumNumberOfTrackedImages = 3
        }
    }
    
    func configure(_ configuration: inout ARBodyTrackingConfiguration) {
        if let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) {
            configuration.detectionImages = referenceImages
            configuration.maximumNumberOfTrackedImages = 3
        }
    }

    public var state: DataProviderState = .initialized
    
    public static var requiredAuthorizations: [ARKitSession.AuthorizationType] { [] }
    
    public static var isSupported: Bool { true }
    
    public var description: String { "ImageTrackingProvider" }
    
    func capture(anchor: ARImageAnchor, timestamp: TimeInterval, event: CapturedAnchorEvent) -> CapturedAnchor? {
        anchor.captured(event, timestamp: timestamp)
    }
}
#endif
