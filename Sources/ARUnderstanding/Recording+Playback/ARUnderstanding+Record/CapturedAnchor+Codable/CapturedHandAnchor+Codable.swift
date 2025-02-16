//
//  CapturedHandAnchor+Codable.swift
//  HandCapture
//
//  Created by John Haney on 4/29/24.
//

#if canImport(ARKit)
import ARKit
#endif
import Foundation
import RealityKit

extension CapturedHandAnchor: Codable {
    enum CodingKeys: String, CodingKey {
        case VERSION
        case id
        case chirality
        case handSkeleton
        case isTracked
        case originFromAnchorTransform
        case timestamp
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(1, forKey: .VERSION)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.chirality, forKey: .chirality)
        if let handSkeleton {
            try container.encode(handSkeleton, forKey: .handSkeleton)
        }
        try container.encode(self.isTracked, forKey: .isTracked)
        try container.encode(self.originFromAnchorTransform, forKey: .originFromAnchorTransform)
        try container.encode(self.timestamp, forKey: .timestamp)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let chirality = try container.decode(HandAnchor.Chirality.self, forKey: .chirality)
        let handSkeleton = try container.decodeIfPresent(CapturedHandSkeleton.self, forKey: .handSkeleton)
        let isTracked = try container.decode(Bool.self, forKey: .isTracked)
        let originFromAnchorTransform = try container.decode(simd_float4x4.self, forKey: .originFromAnchorTransform)
        let timestamp = (try? container.decode(TimeInterval.self, forKey: .timestamp)) ?? 0
        self.init(id: id, chirality: chirality, handSkeleton: handSkeleton, isTracked: isTracked, originFromAnchorTransform: originFromAnchorTransform, timestamp: timestamp)
    }
}

extension HandAnchor.Chirality: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .right:
            try container.encode("right")
        case .left:
            try container.encode("left")
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "right":
            self = .right
        case "left":
            self = .left
        default:
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "should be left or right only")
        }
    }
}

extension CapturedHandSkeleton: Codable {
    enum CodingKeys: String, CodingKey {
        case allJoints
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.allJoints, forKey: .allJoints)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let allJoints = try container.decode([Joint].self, forKey: .allJoints)
        self.init(allJoints: allJoints)
    }
}

extension CapturedHandSkeleton.Joint: Codable {
    enum CodingKeys: String, CodingKey {
        case anchorFromJointTransform
        case isTracked
        case name
        case parentFromJointTransform
        case parentJointName
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.anchorFromJointTransform, forKey: .anchorFromJointTransform)
        try container.encode(self.isTracked, forKey: .isTracked)
        try container.encode(self.name.rawValue, forKey: .name)
        try container.encode(self.parentFromJointTransform, forKey: .parentFromJointTransform)
        if let parentJointName {
            try container.encode(parentJointName, forKey: .parentJointName)
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nameRawValue = try container.decode(String.self, forKey: .name)
        guard let name = HandSkeleton.JointName(rawValue: nameRawValue)
        else {
            throw DecodingError.dataCorruptedError(forKey: .name, in: container, debugDescription: "unknown JointName")
        }
        let parentJointName = try container.decodeIfPresent(String.self, forKey: .parentJointName)

        let anchorFromJointTransform = try container.decode(simd_float4x4.self, forKey: .anchorFromJointTransform)
        let isTracked = try container.decode(Bool.self, forKey: .isTracked)
        let parentFromJointTransform = try container.decode(simd_float4x4.self, forKey: .parentFromJointTransform)
        self.init(name: name, anchorFromJointTransform: anchorFromJointTransform, isTracked: isTracked, parentFromJointTransform: parentFromJointTransform, parentJointName: parentJointName)
    }
}

#if canImport(ARKit)
public extension HandSkeleton.JointName {
    init?(rawValue: String) {
        switch rawValue {
        case HandSkeleton.JointName.wrist.rawValue:
            self = .wrist
        case HandSkeleton.JointName.thumbKnuckle.rawValue:
            self = .thumbKnuckle
        case HandSkeleton.JointName.thumbIntermediateBase.rawValue:
            self = .thumbIntermediateBase
        case HandSkeleton.JointName.thumbIntermediateTip.rawValue:
            self = .thumbIntermediateTip
        case HandSkeleton.JointName.thumbTip.rawValue:
            self = .thumbTip
        case HandSkeleton.JointName.indexFingerMetacarpal.rawValue:
            self = .indexFingerMetacarpal
        case HandSkeleton.JointName.indexFingerKnuckle.rawValue:
            self = .indexFingerKnuckle
        case HandSkeleton.JointName.indexFingerIntermediateBase.rawValue:
            self = .indexFingerIntermediateBase
        case HandSkeleton.JointName.indexFingerIntermediateTip.rawValue:
            self = .indexFingerIntermediateTip
        case HandSkeleton.JointName.indexFingerTip.rawValue:
            self = .indexFingerTip
        case HandSkeleton.JointName.middleFingerMetacarpal.rawValue:
            self = .middleFingerMetacarpal
        case HandSkeleton.JointName.middleFingerKnuckle.rawValue:
            self = .middleFingerKnuckle
        case HandSkeleton.JointName.middleFingerIntermediateBase.rawValue:
            self = .middleFingerIntermediateBase
        case HandSkeleton.JointName.middleFingerIntermediateTip.rawValue:
            self = .middleFingerIntermediateTip
        case HandSkeleton.JointName.middleFingerTip.rawValue:
            self = .middleFingerTip
        case HandSkeleton.JointName.ringFingerMetacarpal.rawValue:
            self = .ringFingerMetacarpal
        case HandSkeleton.JointName.ringFingerKnuckle.rawValue:
            self = .ringFingerKnuckle
        case HandSkeleton.JointName.ringFingerIntermediateBase.rawValue:
            self = .ringFingerIntermediateBase
        case HandSkeleton.JointName.ringFingerIntermediateTip.rawValue :
            self = .ringFingerIntermediateTip
        case HandSkeleton.JointName.ringFingerTip.rawValue:
            self = .ringFingerTip
        case HandSkeleton.JointName.littleFingerMetacarpal.rawValue:
            self = .littleFingerMetacarpal
        case HandSkeleton.JointName.littleFingerKnuckle.rawValue:
            self = .littleFingerKnuckle
        case HandSkeleton.JointName.littleFingerIntermediateBase.rawValue:
            self = .littleFingerIntermediateBase
        case HandSkeleton.JointName.littleFingerIntermediateTip.rawValue:
            self = .littleFingerIntermediateTip
        case HandSkeleton.JointName.littleFingerTip.rawValue:
            self = .littleFingerTip
        case HandSkeleton.JointName.forearmWrist.rawValue:
            self = .forearmWrist
        case HandSkeleton.JointName.forearmArm.rawValue:
            self = .forearmArm
        default:
            return nil
        }
    }
}
#endif

extension simd_float4x4: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(columns.0)
        try container.encode(columns.1)
        try container.encode(columns.2)
        try container.encode(columns.3)
    }
    
    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let col0 = try container.decode(SIMD4<Float>.self)
        let col1 = try container.decode(SIMD4<Float>.self)
        let col2 = try container.decode(SIMD4<Float>.self)
        let col3 = try container.decode(SIMD4<Float>.self)
        self.init(col0, col1, col2, col3)
    }
}
