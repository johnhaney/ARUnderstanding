//
//  ImageAnchor+ARUnderstanding.swift
//  ARUnderstanding
//
//  Created by John Haney on 5/27/25.
//

#if os(visionOS)
import Foundation
import ARKit
import RealityKit

extension ImageAnchor: @retroactive Hashable {}
extension ImageAnchor: ImageAnchorRepresentable {
    public var referenceImageName: String? { referenceImage.name }
    public var estimatedPhysicalWidth: Float { estimatedScaleFactor * Float(referenceImage.physicalSize.width) }
    public var estimatedPhysicalHeight: Float { estimatedScaleFactor * Float(referenceImage.physicalSize.height) }
}
#else
public typealias ImageAnchor = CapturedImageAnchor
#endif
