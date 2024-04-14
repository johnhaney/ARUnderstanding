//
//  CapturedImageAnchor.swift
//
//
//  Created by John Haney on 4/13/24.
//

import ARKit

public protocol ImageAnchorRepresentable: CapturableAnchor {
    var originFromAnchorTransform: simd_float4x4 { get }
    var isTracked: Bool { get }
    var id: UUID { get }
    var referenceImageName: String? { get }
    var estimatedScaleFactor: Float { get }
    var estimatedPhysicalWidth: Float { get }
    var estimatedPhysicalHeight: Float { get }
}

extension ImageAnchor: ImageAnchorRepresentable {
    public var referenceImageName: String? { referenceImage.name }
    public var estimatedPhysicalWidth: Float { estimatedScaleFactor * Float(referenceImage.physicalSize.width) }
    public var estimatedPhysicalHeight: Float { estimatedScaleFactor * Float(referenceImage.physicalSize.height) }
}

public struct CapturedImageAnchor: TrackableAnchor, ImageAnchorRepresentable, Sendable {
    public var id: UUID
    public var originFromAnchorTransform: simd_float4x4
    public var isTracked: Bool
    public var referenceImageName: String?
    public var estimatedScaleFactor: Float
    public var estimatedPhysicalWidth: Float
    public var estimatedPhysicalHeight: Float
    public var description: String { "Image \(originFromAnchorTransform) \(referenceImageName ?? "n/a") \(estimatedPhysicalWidth)x\(estimatedPhysicalHeight)" }

    public init(id: UUID, originFromAnchorTransform: simd_float4x4, isTracked: Bool, referenceImageName: String?, estimatedScaleFactor: Float, estimatedPhysicalWidth: Float, estimatedPhysicalHeight: Float) {
        self.id = id
        self.originFromAnchorTransform = originFromAnchorTransform
        self.isTracked = isTracked
        self.referenceImageName = referenceImageName
        self.estimatedScaleFactor = estimatedScaleFactor
        self.estimatedPhysicalWidth = estimatedPhysicalWidth
        self.estimatedPhysicalHeight = estimatedPhysicalHeight
    }
}

extension ImageAnchorRepresentable {
    public var captured: CapturedImageAnchor {
        CapturedImageAnchor(id: id, originFromAnchorTransform: originFromAnchorTransform, isTracked: isTracked, referenceImageName: referenceImageName, estimatedScaleFactor: estimatedScaleFactor, estimatedPhysicalWidth: estimatedPhysicalWidth, estimatedPhysicalHeight: estimatedPhysicalHeight)
    }
}
