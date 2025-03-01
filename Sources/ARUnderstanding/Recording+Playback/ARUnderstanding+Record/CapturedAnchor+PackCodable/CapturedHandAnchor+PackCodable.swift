//
//  CapturedHandAnchor+PackCodable.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/22/25.
//

import Foundation

import RealityKit
import simd
#if canImport(ARKit)
import ARKit
#endif

extension CapturedHandAnchor: PackEncodable {
    public func pack() throws -> Data {
        guard let handSkeleton
        else {
            throw PackError.failed
        }
        var output: Data = Data()
        output.append(try id.pack())
        output.append(contentsOf: [chirality == .left ? 1 : 2])
        output.append(try originFromAnchorTransform.pack())
        output.append(try handSkeleton.pack())
        return output
    }
}

extension CapturedHandSkeleton: PackEncodable {
    static var packJoints: [JointName] { [
        .forearmWrist,
        .forearmArm,
        .thumbKnuckle,
        .thumbIntermediateBase,
        .thumbIntermediateTip,
        .thumbTip,
        .indexFingerMetacarpal,
        .indexFingerKnuckle,
        .indexFingerIntermediateBase,
        .indexFingerIntermediateTip,
        .indexFingerTip,
        .middleFingerMetacarpal,
        .middleFingerKnuckle,
        .middleFingerIntermediateBase,
        .middleFingerIntermediateTip,
        .middleFingerTip,
        .ringFingerMetacarpal,
        .ringFingerKnuckle,
        .ringFingerIntermediateBase,
        .ringFingerIntermediateTip,
        .ringFingerTip,
        .littleFingerMetacarpal,
        .littleFingerKnuckle,
        .littleFingerIntermediateBase,
        .littleFingerIntermediateTip,
        .littleFingerTip
    ]
    }
    
    public func pack() throws -> Data {
        var output: Data = Data()
        let jointsByName: [JointName: CapturedHandSkeleton.Joint] = Dictionary(uniqueKeysWithValues: allJoints.map({ ($0.name, $0) }))
        for joint in Self.packJoints {
            if let jointData = jointsByName[joint] {
                output.append(try jointData.anchorFromJointTransform.pack())
            } else {
                throw PackError.failed
            }
        }
        return output
    }
}

extension CapturedHandSkeleton: PackDecodable {
    public static func unpack(data: Data) throws -> (CapturedHandSkeleton, Int) {
        let (jointTransforms, consumed) = try simd_float4x4.unpack(data: data, count: Self.packJoints.count)
        let joints = zip(Self.packJoints, jointTransforms).map { name, transform in
            CapturedHandSkeleton.Joint(name: name, anchorFromJointTransform: transform, isTracked: true, parentFromJointTransform: name.parentFromJointTransform(transform, jointTransforms), parentJointName: name.parentJointName)
        }
        let wrist = CapturedHandSkeleton.Joint(name: .wrist, anchorFromJointTransform: .init(1), isTracked: true, parentFromJointTransform: .init(1), parentJointName: nil)
        return (CapturedHandSkeleton(allJoints: [wrist] + joints), consumed)
    }
}

extension HandSkeleton.JointName {
    public static var allJointNames: [HandSkeleton.JointName] {
        [
            .wrist,
            .forearmWrist,
            .forearmArm,
            .thumbKnuckle,
            .thumbIntermediateBase,
            .thumbIntermediateTip,
            .thumbTip,
            .indexFingerMetacarpal,
            .indexFingerKnuckle,
            .indexFingerIntermediateBase,
            .indexFingerIntermediateTip,
            .indexFingerTip,
            .middleFingerMetacarpal,
            .middleFingerKnuckle,
            .middleFingerIntermediateBase,
            .middleFingerIntermediateTip,
            .middleFingerTip,
            .ringFingerMetacarpal,
            .ringFingerKnuckle,
            .ringFingerIntermediateBase,
            .ringFingerIntermediateTip,
            .ringFingerTip,
            .littleFingerMetacarpal,
            .littleFingerKnuckle,
            .littleFingerIntermediateBase,
            .littleFingerIntermediateTip,
            .littleFingerTip
        ]
    }
    
    func parentFromJointTransform(_ anchorFromJointTransform: simd_float4x4, _ jointTransforms: [simd_float4x4]) -> simd_float4x4 {
        switch self {
        case .wrist: anchorFromJointTransform
        case .forearmWrist: anchorFromJointTransform
        case .forearmArm: anchorFromJointTransform * jointTransforms[0].inverse
        case .thumbKnuckle: anchorFromJointTransform
        case .thumbIntermediateBase: anchorFromJointTransform * jointTransforms[2].inverse
        case .thumbIntermediateTip: anchorFromJointTransform * jointTransforms[3].inverse
        case .thumbTip: anchorFromJointTransform * jointTransforms[4].inverse
        case .indexFingerMetacarpal: anchorFromJointTransform
        case .indexFingerKnuckle: anchorFromJointTransform * jointTransforms[6].inverse
        case .indexFingerIntermediateBase: anchorFromJointTransform * jointTransforms[7].inverse
        case .indexFingerIntermediateTip: anchorFromJointTransform * jointTransforms[8].inverse
        case .indexFingerTip: anchorFromJointTransform * jointTransforms[9].inverse
        case .middleFingerMetacarpal: anchorFromJointTransform
        case .middleFingerKnuckle: anchorFromJointTransform * jointTransforms[11].inverse
        case .middleFingerIntermediateBase: anchorFromJointTransform * jointTransforms[12].inverse
        case .middleFingerIntermediateTip: anchorFromJointTransform * jointTransforms[13].inverse
        case .middleFingerTip: anchorFromJointTransform * jointTransforms[14].inverse
        case .ringFingerMetacarpal: anchorFromJointTransform
        case .ringFingerKnuckle: anchorFromJointTransform * jointTransforms[16].inverse
        case .ringFingerIntermediateBase: anchorFromJointTransform * jointTransforms[17].inverse
        case .ringFingerIntermediateTip: anchorFromJointTransform * jointTransforms[18].inverse
        case .ringFingerTip: anchorFromJointTransform * jointTransforms[19].inverse
        case .littleFingerMetacarpal: anchorFromJointTransform
        case .littleFingerKnuckle: anchorFromJointTransform * jointTransforms[21].inverse
        case .littleFingerIntermediateBase: anchorFromJointTransform * jointTransforms[22].inverse
        case .littleFingerIntermediateTip: anchorFromJointTransform * jointTransforms[23].inverse
        case .littleFingerTip: anchorFromJointTransform * jointTransforms[24].inverse
        @unknown default: anchorFromJointTransform
        }
    }
}

protocol AnchorPackDecodable {
    static func unpack(data: Data, timestamp: TimeInterval) throws -> (Self, Int)
}

extension CapturedHandAnchor: AnchorPackDecodable {
    static func unpack(data: Data, timestamp: TimeInterval) throws -> (Self, Int) {
        guard data.count >= 16 + 1 + 16 + 26 * 16
        else {
            throw UnpackError.needsMoreData(16 + 1 + 16 + 26 * 16)
        }
        let (id, consumed) = try UUID.unpack(data: data)
        var offset = consumed
        let chirality: HandAnchor.Chirality = data[data.startIndex + offset] == 1 ? .left : .right
        offset += 1
        let originFromAnchorTransform: simd_float4x4
        do {
            let (transform, consumed) = try simd_float4x4.unpack(data: data[(data.startIndex + offset)...])
            originFromAnchorTransform = transform
            offset += consumed
        }
        let skeleton: CapturedHandSkeleton
        do {
            let (capturedSkeleton, consumed) = try CapturedHandSkeleton.unpack(data: data[(data.startIndex + offset)...])
            skeleton = capturedSkeleton
            offset += consumed
            
        }
        return (
            CapturedHandAnchor(
                id: id,
                chirality: chirality,
                handSkeleton: skeleton,
                isTracked: true,
                originFromAnchorTransform: originFromAnchorTransform,
                timestamp: timestamp
            ),
            offset
        )
    }
}
