//
//  ARProvider.swift
//  
//
//  Created by John Haney on 4/7/24.
//

#if os(visionOS)
import ARKit
#endif
import Foundation
import RealityKit

public enum ARProvider {
    case hands(HandTrackingProvider)
    case meshes(SceneReconstructionProvider)
    case planes(PlaneDetectionProvider)
    case image(ImageTrackingProvider)
    case world(WorldTrackingProvider, QueryDeviceAnchor)
}

public enum ARProviderDefinition: Equatable {
    case hands
    case device
    case meshes
    case unclassifiedMeshes
    case planes
    case verticalPlanes
    case horizontalPlanes
    case image(resourceGroupName: String)
    case world
}

public enum QueryDeviceAnchor {
    case enabled
    case none
}

extension ARProviderDefinition {
    var provider: ARProvider {
        switch self {
        case .hands:
            .hands(HandTrackingProvider())
        case .device:
            .world(WorldTrackingProvider(), .enabled)
        case .meshes:
            .meshes(SceneReconstructionProvider(modes: [.classification]))
        case .unclassifiedMeshes:
            .meshes(SceneReconstructionProvider())
        case .planes:
            .planes(PlaneDetectionProvider(alignments: [.horizontal, .vertical]))
        case .verticalPlanes:
            .planes(PlaneDetectionProvider(alignments: [.vertical]))
        case .horizontalPlanes:
            .planes(PlaneDetectionProvider(alignments: [.horizontal]))
        case .image(let resourceGroupName):
            .image(ImageTrackingProvider(referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: resourceGroupName)))
        case .world:
            .world(WorldTrackingProvider(), .none)
        }
    }
}
