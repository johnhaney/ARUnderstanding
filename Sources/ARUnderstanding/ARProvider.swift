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
