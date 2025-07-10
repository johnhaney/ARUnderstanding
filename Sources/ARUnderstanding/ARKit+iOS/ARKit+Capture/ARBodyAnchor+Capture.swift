//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/5/25.
//

#if os(iOS)
import ARKit
import RealityKit

extension ARBodyAnchor: CapturableARAnchor {
    func capturedAnchor(_ event: CapturedAnchorEvent, timestamp: TimeInterval) -> CapturedAnchor {
        let anchor = SavedBodyAnchor(identifier: identifier, transform: transform, estimatedScaleFactor: Float(estimatedScaleFactor), skeleton: skeleton)
        let update = CapturedAnchorUpdate<CapturedBodyAnchor>(anchor: anchor.captured, timestamp: timestamp, event: event)
        return CapturedAnchor.body(update)
    }
}

extension ARSkeleton3D: BodySkeletonRepresentable {
    public func modelTransformForJointName(_ jointName: SkeletonJointName) -> simd_float4x4? {
        self.modelTransform(for: jointName)
    }
    
    public func localTransformForJointName(_ jointName: SkeletonJointName) -> simd_float4x4? {
        self.localTransform(for: jointName)
    }
}
#else
public typealias ARSkeleton = CapturedBodySkeleton
extension ARSkeleton {
    public enum JointName {
        case root
        case head
        case leftShoulder
        case rightShoulder
        case leftHand
        case rightHand
        case leftFoot
        case rightFoot
    }
}
#endif
