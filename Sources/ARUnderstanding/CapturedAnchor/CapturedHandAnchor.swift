//
//  CapturedHandAnchor.swift
//  
//
//  Created by John Haney on 4/13/24.
//

import Foundation
#if canImport(ARKit)
import ARKit
#endif
#if canImport(RealityKit)
import RealityKit
#endif
import simd

public protocol HandAnchorRepresentable: CapturableAnchor, Hashable {
    associatedtype HandSkeletonType: HandSkeletonRepresentable
    var id: UUID { get }
    var chirality: HandAnchor.Chirality { get }
    var fidelity: HandAnchor.Fidelity { get }
    var handSkeleton: HandSkeletonType? { get }
    var isTracked: Bool { get }
    var originFromAnchorTransform: simd_float4x4 { get }
}

extension HandAnchorRepresentable {
    var capturedHandSkeleton: CapturedHandSkeleton? {
        handSkeleton?.captured
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    public func jointPosition(named jointName: JointName) -> SIMD3<Float>? {
        guard let joint = handSkeleton?.joint(jointName) else { return nil }
        return Transform(matrix: originFromAnchorTransform * joint.anchorFromJointTransform).translation
    }
}

#if os(visionOS)
public typealias JointName = ARKit.HandSkeleton.JointName
#else
public typealias JointName = HandSkeleton.JointName
#endif

public struct CapturedHandAnchor: CapturableAnchor, HandAnchorRepresentable, Sendable, Equatable {
    public func joint(named jointName: JointName) -> any HandSkeletonJointRepresentable {
        handSkeleton?.allJoints.first(where: { $0.name == jointName }) ?? handSkeleton!.allJoints.first!
    }
    
    public let id: UUID
    public let chirality: HandAnchor.Chirality
    public let fidelity: HandAnchor.Fidelity
    public var handSkeleton: CapturedHandSkeleton? { _handSkeleton() }
    private let _handSkeleton: @Sendable () -> CapturedHandSkeleton?
    public let isTracked: Bool
    public let originFromAnchorTransform: simd_float4x4
    public var description: String { "Hand \(originFromAnchorTransform)" }
    
    public init<T: HandAnchorRepresentable>(captured: T) {
        self.id = captured.id
        self.chirality = captured.chirality
        self.fidelity = captured.fidelity
        self._handSkeleton = {
            if let handSkeleton = captured.handSkeleton {
                handSkeleton.captured
            } else {
                nil
            }
        }
        self.isTracked = captured.isTracked
        self.originFromAnchorTransform = captured.originFromAnchorTransform
    }
    
    public init(id: UUID, chirality: HandAnchor.Chirality, fidelity: HandAnchor.Fidelity = .high, handSkeleton: CapturedHandSkeleton?, isTracked: Bool, originFromAnchorTransform: simd_float4x4) {
        self.id = id
        self.fidelity = fidelity
        self.chirality = chirality
        self._handSkeleton = { handSkeleton }
        self.isTracked = isTracked
        self.originFromAnchorTransform = originFromAnchorTransform
    }
    
    public var captured: Self { self }
}

extension CapturedHandAnchor {
    public static var neutralPose: CapturedHandAnchor {
        CapturedHandAnchor(id: UUID(), chirality: .left, handSkeleton: SavedHandSkeleton.neutralPose, isTracked: false, originFromAnchorTransform: simd_float4x4.init(diagonal: SIMD4<Float>(repeating: 1)))
    }
}

#if os(visionOS)
public struct LiveCapturedHandSkeleton: HandSkeletonRepresentable, Sendable, Equatable {
    private let base: HandSkeleton
    
    init(captured: HandSkeleton) {
        self.base = captured
    }

    public var allJoints: [HandSkeleton.Joint] {
        base.allJoints
    }
    
    public func joint(_ named: HandSkeleton.JointName) -> HandSkeleton.Joint {
        base.joint(named)
    }
}
#endif
public typealias CapturedHandSkeleton = SavedHandSkeleton

public struct SavedHandSkeleton: HandSkeletonRepresentable, Sendable, Equatable {
    public private(set) var allJoints: [Joint]
    
    public func joint(_ named: HandSkeleton.JointName) -> Joint {
        let jointByIndex = allJoints[named.allJointsIndex]
        if jointByIndex.name != named,
            let jointByName = allJoints.first(where: { $0.name == named }) {
            return jointByName
        }
        return jointByIndex
    }
    
    public init<Skeleton: HandSkeletonRepresentable>(captured: Skeleton) {
        allJoints = []
        allJoints = captured.allJoints.map({ $0.captured(self) })
    }
    
    public init(allJointTransforms jointTransforms: [simd_float4x4]) {
        allJoints = []

        // Since we packed the joints in a particular order, we can decode the transforms for the parentFromJointTransform, but we don't map back to the parentJoint yet here. We will let the SavedHandSkeleton init do that last bit of work.
        let joints: [SavedHandSkeleton.Joint] =
        zip(HandSkeleton.packJoints, jointTransforms).map { name, transform in
            SavedHandSkeleton.Joint(name: name, isTracked: true, anchorFromJointTransform: transform, parentFromJointTransform: name.parentFromJointTransform(transform, jointTransforms), skeleton: self)
        }
        // keep parentJoint nil here, we'll resolve this later
        let wrist = SavedHandSkeleton.Joint(name: .wrist, isTracked: true, anchorFromJointTransform: .init(1), parentFromJointTransform: .init(1), skeleton: self)
        
        allJoints = [wrist] + joints
    }
}

extension HandSkeletonJointRepresentable {
    func captured(_ skeleton: SavedHandSkeleton) -> SavedHandSkeleton.Joint {
        SavedHandSkeleton.Joint(name: name, isTracked: isTracked, anchorFromJointTransform: anchorFromJointTransform, parentFromJointTransform: parentFromJointTransform, skeleton: skeleton)
    }
}

extension SavedHandSkeleton {
    public struct Joint: HandSkeletonJointRepresentable, Sendable, Equatable {
        public let name: HandSkeleton.JointName
        public let isTracked: Bool
        public let anchorFromJointTransform: simd_float4x4
        public let parentFromJointTransform: simd_float4x4
        public let skeleton: SavedHandSkeleton
        public var parentJoint: SavedHandSkeleton.Joint? {
            if let parentName = name.parentName {
                skeleton.joint(parentName)
            } else {
                nil
            }
        }
    }
}

extension HandSkeleton.JointName {
    var allJointsIndex: Int {
        switch self {
        case .wrist: 0
        case .forearmWrist: 25
        case .forearmArm: 26
        case .thumbKnuckle: 1
        case .thumbIntermediateBase: 2
        case .thumbIntermediateTip: 3
        case .thumbTip: 4
        case .indexFingerMetacarpal: 5
        case .indexFingerKnuckle: 6
        case .indexFingerIntermediateBase: 7
        case .indexFingerIntermediateTip: 8
        case .indexFingerTip: 9
        case .middleFingerMetacarpal: 10
        case .middleFingerKnuckle: 11
        case .middleFingerIntermediateBase: 12
        case .middleFingerIntermediateTip: 13
        case .middleFingerTip: 14
        case .ringFingerMetacarpal: 15
        case .ringFingerKnuckle: 16
        case .ringFingerIntermediateBase: 17
        case .ringFingerIntermediateTip: 18
        case .ringFingerTip: 19
        case .littleFingerMetacarpal: 20
        case .littleFingerKnuckle: 21
        case .littleFingerIntermediateBase: 22
        case .littleFingerIntermediateTip: 23
        case .littleFingerTip: 24
        @unknown default: 0
        }
    }
}

//public struct CapturedHandSkeletonJoint: HandSkeletonJointRepresentable, Sendable, Equatable {
//    public var name: HandSkeleton.JointName
//    public var anchorFromJointTransform: simd_float4x4
//    public var isTracked: Bool
//    public var parentFromJointTransform: simd_float4x4
//    public let skeleton: CapturedHandSkeleton
//    public var parentJoint: CapturedHandSkeleton.Joint? {
//        if let parentName = name.parentName {
//            skeleton.joint(parentName)
//        } else {
//            nil
//        }
//    }
//
//    func with(parentFrom from: [HandSkeleton.JointName: [CapturedHandSkeletonJoint]]) -> Self {
//        guard let jointName = HandSkeleton.JointName(rawValue: name.rawValue),
//              let parentJointName = jointName.parentName,
//              let parentJoint = from[parentJointName]?.first
//        else { return self }
//        
//        return CapturedHandSkeletonJoint(name: name,
//                                         anchorFromJointTransform: anchorFromJointTransform,
//                                         isTracked: isTracked,
//                                         parentFromJointTransform: parentFromJointTransform,
//                                         parentJoint: parentJoint)
//    }
//    
//    static var neutralPose: [CapturedHandSkeletonJoint] {
//        HandSkeleton.packJoints.map({
//            CapturedHandSkeletonJoint(
//                name: $0,
//                anchorFromJointTransform: .init(diagonal: [1,1,1,1]),
//                isTracked: false,
//                parentFromJointTransform: .init(diagonal: [1,1,1,1]),
//                parentJoint: nil
//            )
//        })
//    }
//}

extension HandSkeletonRepresentable {
    public static var neutralPose: CapturedHandSkeleton {
        #if os(visionOS)
        HandSkeleton.neutralPose.captured
        #else
        // Avoid infinite recursion
        CapturedHandSkeleton(allJointTransforms: .init(repeating: .init(diagonal: [1,1,1,1]), count: HandSkeleton.JointName.allJointNames.count))
        #endif
    }
    
    public var captured: CapturedHandSkeleton {
        #if os(visionOS)
        if let self = self as? HandSkeleton {
            return CapturedHandSkeleton(captured: self)
        }
        #endif
        if let self = self as? SavedHandSkeleton {
            return self
        } else {
            return SavedHandSkeleton(captured: self)
        }
    }
}

extension HandAnchorRepresentable {
    public var captured: CapturedHandAnchor {
        if let captured = self as? CapturedHandAnchor {
            captured
        } else {
            CapturedHandAnchor(captured: self)
        }
    }
}

public protocol HandSkeletonRepresentable: Hashable, Sendable {
    associatedtype Joint: HandSkeletonJointRepresentable
    var allJoints: [Joint] { get }
    func joint(_ named: HandSkeleton.JointName) -> Joint
}

extension HandSkeletonRepresentable {
    public func hash(into hasher: inout Hasher) {
        for joint in allJoints {
            hasher.combine(joint)
        }
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        zip(lhs.allJoints, rhs.allJoints).reduce(true, { $0 && ($1.0.hashValue == $1.1.hashValue) })
    }
}

public protocol HandSkeletonJointRepresentable: Hashable, Sendable {
    var name: HandSkeleton.JointName { get }
    var isTracked: Bool { get }
    var anchorFromJointTransform: simd_float4x4 { get }
    var parentFromJointTransform: simd_float4x4 { get }
    var parentJoint: Self? { get }
}

extension HandSkeletonJointRepresentable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(isTracked)
        hasher.combine(anchorFromJointTransform)
        hasher.combine(parentFromJointTransform)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name &&
        lhs.isTracked == rhs.isTracked &&
        lhs.anchorFromJointTransform == rhs.anchorFromJointTransform &&
        lhs.parentFromJointTransform == rhs.parentFromJointTransform
    }
}
