//
//  AccessoryAnchor+ARUnderstanding.swift
//  ARUnderstanding
//
//  Created by John Haney on 10/5/25.
//

#if os(visionOS)
import Foundation
import ARKit
import RealityKit

extension AccessoryAnchor: @retroactive Hashable {}
extension AccessoryAnchor: AccessoryAnchorRepresentable {
    public typealias Accessory = ARKit.Accessory
}
extension AccessoryAnchor.Accessory: AccessoryRepresentable {
    public var captured: CapturedAccessory {
        CapturedAccessory(accessory: self)
    }
}
#else
public typealias AccessoryAnchor = CapturedAccessoryAnchor
#endif
