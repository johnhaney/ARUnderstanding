//
//  CapturedBodyAnchor.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/5/25.
//

import Foundation
#if canImport(ARKit)
import ARKit
#endif
#if canImport(RealityKit)
import RealityKit
#endif
import simd

protocol ARAnchorRepresentable {
    var identifier: UUID { get }
    var transform: simd_float4x4 { get }
}

protocol BodyAnchorRepresentable: ARAnchorRepresentable, Sendable {
    associatedtype BodySkeleton: BodySkeletonRepresentable
    var estimatedScaleFactor: Float { get }
    var skeleton: BodySkeleton { get }
}

public typealias SkeletonJointName = ARSkeleton.JointName

public protocol BodySkeletonRepresentable: Hashable, Equatable, Sendable {
    var jointModelTransforms: [simd_float4x4] { get }
    var jointLocalTransforms: [simd_float4x4] { get }
    
    func modelTransformForJointName(_ jointName: SkeletonJointName) -> simd_float4x4?
    func localTransformForJointName(_ jointName: SkeletonJointName) -> simd_float4x4?
}

extension BodySkeletonRepresentable {
    var captured: CapturedBodySkeleton {
        CapturedBodySkeleton(captured: self)
    }
}

public struct CapturedBodyAnchor: CapturableAnchor, BodyAnchorRepresentable, Sendable, Equatable {
    typealias BodySkeleton = CapturedBodySkeleton
    
    var estimatedScaleFactor: Float
    public var id: UUID
    public var originFromAnchorTransform: simd_float4x4
    var identifier: UUID { id }
    var transform: simd_float4x4 { originFromAnchorTransform }
    var skeleton: CapturedBodySkeleton { _skeleton() }
    var _skeleton: @Sendable() -> CapturedBodySkeleton
    public var description: String { "Body \(originFromAnchorTransform)" }
    
    public static func == (lhs: CapturedBodyAnchor, rhs: CapturedBodyAnchor) -> Bool {
        lhs.identifier == rhs.identifier &&
        lhs.transform == rhs.transform &&
        lhs.estimatedScaleFactor == rhs.estimatedScaleFactor &&
        lhs.skeleton == rhs.skeleton
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(transform)
        hasher.combine(estimatedScaleFactor)
        hasher.combine(skeleton)
    }

    init<T: BodyAnchorRepresentable>(captured: T) {
        self.id = captured.identifier
        self.originFromAnchorTransform = captured.transform
        self.estimatedScaleFactor = captured.estimatedScaleFactor
        self._skeleton = { captured.skeleton.captured }
    }
}

public struct SavedBodyAnchor: CapturableAnchor, BodyAnchorRepresentable, Sendable, Equatable {
    public typealias BodySkeleton = CapturedBodySkeleton
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(transform)
        hasher.combine(estimatedScaleFactor)
        hasher.combine(skeleton)
    }
    
    var estimatedScaleFactor: Float
    public var id: UUID
    public var originFromAnchorTransform: simd_float4x4
    var identifier: UUID { id }
    var transform: simd_float4x4 { originFromAnchorTransform }
    var skeleton: CapturedBodySkeleton
    public var description: String { "Body \(originFromAnchorTransform)" }

    init<T: BodySkeletonRepresentable>(identifier: UUID, transform: simd_float4x4, estimatedScaleFactor: Float, skeleton: T) {
        self.id = identifier
        self.originFromAnchorTransform = transform
        self.estimatedScaleFactor = estimatedScaleFactor
        self.skeleton = skeleton.captured
    }

//    public enum SkeletonJointName: UInt8 {
//        case root = 1
//        case head = 2
//        case leftHand = 3
//        case rightHand = 4
//        case leftFoot = 5
//        case rightFoot = 6
//        case leftShoulder = 7
//        case rightShoulder = 8
//    }
    
    public var captured: Self { self }
}

extension BodyAnchorRepresentable {
    public var captured: CapturedBodyAnchor {
        if let captured = self as? CapturedBodyAnchor {
            captured
        } else {
            CapturedBodyAnchor(captured: self)
        }
    }
}


extension SkeletonJointName {
    static var allJointNames: [SkeletonJointName] {
        [ .root, .leftShoulder, .rightShoulder, .head, .leftHand, .rightHand, .leftFoot, .rightFoot ]
    }
    var index: Int { Self.allJointNames.firstIndex(of: self) ?? 0 }
    var description: String {
        switch self {
        case .root: "root"
        case .head: "head"
        case .leftHand: "leftHand"
        case .rightHand: "rightHand"
        case .leftFoot: "leftFoot"
        case .rightFoot: "rightFoot"
        case .leftShoulder: "leftShoulder"
        case .rightShoulder: "rightShoulder"
        default: "unknown"
        }
    }
    var parentName: SkeletonJointName? {
        switch self {
        case .root: nil
        case .head: .root
        case .leftHand: .leftShoulder
        case .rightHand: .rightShoulder
        case .leftFoot: .root
        case .rightFoot: .root
        case .leftShoulder: .root
        case .rightShoulder: .root
        default: .root
        }
    }
}

public struct CapturedBodySkeleton: BodySkeletonRepresentable, Sendable, Equatable, Hashable {
    public var jointLocalTransforms: [simd_float4x4]
    public var jointModelTransforms: [simd_float4x4]
    
    init(captured: any BodySkeletonRepresentable) {
        jointLocalTransforms = captured.jointLocalTransforms
        jointModelTransforms = captured.jointModelTransforms
    }
    
    public func modelTransformForJointName(_ jointName: SkeletonJointName) -> simd_float4x4? {
        jointModelTransforms[jointName.index]
    }
    
    public func localTransformForJointName(_ jointName: SkeletonJointName) -> simd_float4x4? {
        jointLocalTransforms[jointName.index]
    }
}

public struct SavedBodySkeleton: BodySkeletonRepresentable, Sendable, Equatable, Hashable {
    public var jointLocalTransforms: [simd_float4x4]
    public var jointModelTransforms: [simd_float4x4]
    
    public func modelTransformForJointName(_ jointName: SkeletonJointName) -> simd_float4x4? {
        jointModelTransforms[jointName.index]
    }
    
    public func localTransformForJointName(_ jointName: SkeletonJointName) -> simd_float4x4? {
        jointLocalTransforms[jointName.index]
    }
}
