//
//  CapturedBodyAnchor+PackCodable.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/5/25.
//

import Foundation

#if canImport(RealityKit)
import RealityKit
#endif
import simd
#if canImport(ARKit)
import ARKit
#endif

extension CapturedBodyAnchor: PackEncodable {
    public func pack() throws -> Data {
        var output: Data = Data()
        output.append(try id.pack())
        output.append(try originFromAnchorTransform.pack())
        output.append(try estimatedScaleFactor.pack())
        output.append(try skeleton.pack())
        return output
    }
}

extension CapturedBodyAnchor: PackDecodable {
    public static func unpack(data: Data) throws -> (CapturedBodyAnchor, Int) {
        guard data.count >= 16 + 16 + 1 + 8 * 16
        else {
            throw UnpackError.needsMoreData(16 + 16 + 1 + 16 * 16)
        }
        let (id, consumed) = try UUID.unpack(data: data)
        var offset = consumed
        let originFromAnchorTransform: simd_float4x4
        do {
            let (transform, consumed) = try simd_float4x4.unpack(data: data[(data.startIndex + offset)...])
            originFromAnchorTransform = transform
            offset += consumed
        }
        let estimatedScaleFactor: Float
        do {
            let (value, consumed) = try Float.unpack(data: data[(data.startIndex + offset)...])
            estimatedScaleFactor = value
            offset += consumed
        }

        let skeleton: CapturedBodySkeleton
        do {
            let (value, consumed) = try CapturedBodySkeleton.unpack(data: data[(data.startIndex + offset)...])
            skeleton = value
            offset += consumed
        }

        return (
            SavedBodyAnchor(
                identifier: id,
                transform: originFromAnchorTransform,
                estimatedScaleFactor: estimatedScaleFactor,
                skeleton: skeleton
            ).captured,
            offset
        )
    }
}

extension ARSkeleton.JointName {
    static var packJoints: [ARSkeleton.JointName] {
        [
            .root,
            .head,
            .leftHand,
            .rightHand,
            .leftFoot,
            .rightFoot,
            .leftShoulder,
            .rightShoulder,
        ]
    }
}

extension CapturedBodySkeleton: PackEncodable {
    public func pack() throws -> Data {
        var output: Data = Data()
        for jointName in ARSkeleton.JointName.packJoints {
            do {
                let joint = self.localTransformForJointName(jointName) ?? simd_float4x4(diagonal: [1,1,1,1])
                let data = try joint.pack()
                output.append(contentsOf: data)
            }
            do {
                let joint = self.modelTransformForJointName(jointName) ?? simd_float4x4(diagonal: [1,1,1,1])
                let data = try joint.pack()
                output.append(contentsOf: data)
            }
        }
        return output
    }
}

extension CapturedBodySkeleton: PackDecodable {
    public static func unpack(data: Data) throws -> (CapturedBodySkeleton, Int) {
        let (jointTransforms, consumed) = try simd_float4x4.unpack(data: data, count: ARSkeleton.JointName.packJoints.count * 2)
        var localTransforms: [simd_float4x4] = Array(repeating: simd_float4x4(diagonal: [1,1,1,1]), count: ARSkeleton.JointName.packJoints.count)
        var modelTransforms: [simd_float4x4] = Array(repeating: simd_float4x4(diagonal: [1,1,1,1]), count: ARSkeleton.JointName.packJoints.count)
        var index = 0
        for _ in ARSkeleton.JointName.packJoints {
            localTransforms.append(jointTransforms[index])
            modelTransforms.append(jointTransforms[index+1])
            index += 2
        }
        
        return (
            SavedBodySkeleton(jointLocalTransforms: localTransforms, jointModelTransforms: modelTransforms).captured,
            consumed
        )
    }
}
