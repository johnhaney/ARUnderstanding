//
//  DeviceAnchor+ARUnderstanding.swift
//  ARUnderstanding
//
//  Created by John Haney on 5/27/25.
//

#if os(visionOS)
import Foundation
import ARKit
import RealityKit

extension DeviceAnchor: @retroactive Hashable {}
extension DeviceAnchor: @retroactive Equatable {}
extension DeviceAnchor: DeviceAnchorRepresentable {}
#else
public typealias DeviceAnchor = CapturedDeviceAnchor

#endif
