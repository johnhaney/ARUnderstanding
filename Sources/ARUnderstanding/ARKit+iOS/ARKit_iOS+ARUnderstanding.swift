//
//  ARKit+ARUnderstanding.swift
//  ARUnderstanding
//
//  matches definitions and capabilities available on iOS to ARUnderstanding protocols
//
//  Created by John Haney on 3/1/25.
//

#if os(iOS)
import ARKit
import RealityKit

extension ARFaceAnchor: FaceAnchorRepresentable {
    public var id: UUID { identifier }
    public var originFromAnchorTransform: simd_float4x4 { transform }
    
    public typealias BlendShapeLocation = ARFaceAnchor.BlendShapeLocation
}
extension ARFaceAnchor.BlendShapeLocation: BlendShapeLocationRepresentable {}

protocol CapturableARAnchor {
    func capturedAnchor(_ event: CapturedAnchorEvent, timestamp: TimeInterval) -> CapturedAnchor
}

#endif
