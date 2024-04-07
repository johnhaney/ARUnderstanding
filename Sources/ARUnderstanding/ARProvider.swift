//
//  File.swift
//  
//
//  Created by John Haney on 4/7/24.
//

import ARKit

@MainActor
public enum ARProvider {
    case hands(HandTrackingProvider)
    case meshes(SceneReconstructionProvider)
    case planes(PlaneDetectionProvider)
    case image(ImageTrackingProvider)
    case world(WorldTrackingProvider)
}

public enum ARPoviderDefinition {
    case hands
    case meshes
    case unclassifiedMeshes
    case planes
    case verticalPlanes
    case horizontalPlanes
    case image(resourceGroupName: String)
    case world
}

extension ARPoviderDefinition {
    var provider: ARProvider {
        switch self {
        case .hands:
            .hands(HandTrackingProvider())
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
            .world(WorldTrackingProvider())
        }
    }
}
