//
//  WorldAnchor+ARUnderstanding.swift
//  ARUnderstanding
//
//  Created by John Haney on 5/27/25.
//

#if os(visionOS)
import Foundation
import ARKit
import RealityKit

extension WorldAnchor: @retroactive Hashable {}
extension WorldAnchor: WorldAnchorRepresentable {}
#else
public typealias WorldAnchor = CapturedWorldAnchor
#endif
