//
//  ObjectAnchor+ARUnderstanding.swift
//  ARUnderstanding
//
//  Created by John Haney on 5/27/25.
//

#if os(visionOS)
import Foundation
import ARKit
import RealityKit

extension ObjectAnchor: @retroactive Hashable {}
extension ObjectAnchor: ObjectAnchorRepresentable {
    public var referenceObjectName: String {
        referenceObject.name
    }
}
#else
public typealias ObjectAnchor = CapturedObjectAnchor
#endif
