//
//  CapturedAnchor.swift
//
//
//  Created by John Haney on 4/7/24.
//

import ARKit

public enum CapturedAnchor: Sendable {
    case hand(HandAnchor)
    case mesh(MeshAnchor)
    case plane(PlaneAnchor)
    case image(ImageAnchor)
    case world(WorldAnchor)
}
