//
//  RoomAnchor+ARUnderstanding.swift
//  ARUnderstanding
//
//  Created by John Haney on 5/27/25.
//

#if os(visionOS)
import Foundation
import ARKit
import RealityKit

extension RoomAnchor: @retroactive Hashable {}
extension RoomAnchor: RoomAnchorRepresentable {}
#else
public typealias RoomAnchor = CapturedRoomAnchor
#endif
