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
    var handSkeleton: HandSkeletonType? { get }
    var isTracked: Bool { get }
    var originFromAnchorTransform: simd_float4x4 { get }
}

@available(visionOS 26.0, *)
public protocol HandAnchor26Representable: HandAnchorRepresentable {
    var fidelity: HandAnchor.Fidelity { get }
}

@available(visionOS 26.0, *)
public extension HandAnchorRepresentable {
    var fidelity: HandAnchor.Fidelity {
        (self as? (any HandAnchor26Representable))?.fidelity ?? .high
    }
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
    internal let fidelity26: HandAnchor.Fidelity26
    public var handSkeleton: CapturedHandSkeleton? { _handSkeleton() }
    private let _handSkeleton: @Sendable () -> CapturedHandSkeleton?
    public let isTracked: Bool
    public let originFromAnchorTransform: simd_float4x4
    public var description: String { "Hand \(originFromAnchorTransform)" }
    
    public init<T: HandAnchorRepresentable>(captured: T) {
        self.id = captured.id
        self.chirality = captured.chirality
        if #available(visionOS 26.0, *) {
            if let captured = captured as? (any HandAnchor26Representable) {
                self.fidelity26 = captured.fidelity.fidelity26
            } else {
                self.fidelity26 = .high
            }
        } else {
            self.fidelity26 = .high
        }
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
    
    public init(id: UUID, chirality: HandAnchor.Chirality, fidelity26: HandAnchor.Fidelity26 = .high, handSkeleton: CapturedHandSkeleton?, isTracked: Bool, originFromAnchorTransform: simd_float4x4) {
        self.id = id
        self.fidelity26 = fidelity26
        self.chirality = chirality
        self._handSkeleton = { handSkeleton }
        self.isTracked = isTracked
        self.originFromAnchorTransform = originFromAnchorTransform
    }
    
    public var captured: Self { self }
}

@available(visionOS 26.0, *)
extension CapturedHandAnchor {
    public var fidelity: HandAnchor.Fidelity { fidelity26.fidelity }

    public init(id: UUID, chirality: HandAnchor.Chirality, fidelity: HandAnchor.Fidelity, handSkeleton: CapturedHandSkeleton?, isTracked: Bool, originFromAnchorTransform: simd_float4x4) {
        self.init(id: id, chirality: chirality, fidelity26: fidelity.fidelity26, handSkeleton: handSkeleton, isTracked: isTracked, originFromAnchorTransform: originFromAnchorTransform)
    }
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
        allJoints[named.allJointsIndex]
    }
    
    init<Skeleton: HandSkeletonRepresentable>(captured: Skeleton) {
        allJoints = []
        allJoints = captured.allJoints.map({ $0.captured(self) })
    }
    
    init(allJointTransforms jointTransforms: [simd_float4x4]) {
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
        case .forearmWrist: 1
        case .forearmArm: 2
        case .thumbKnuckle: 3
        case .thumbIntermediateBase: 4
        case .thumbIntermediateTip: 5
        case .thumbTip: 6
        case .indexFingerMetacarpal: 7
        case .indexFingerKnuckle: 8
        case .indexFingerIntermediateBase: 9
        case .indexFingerIntermediateTip: 10
        case .indexFingerTip: 11
        case .middleFingerMetacarpal: 12
        case .middleFingerKnuckle: 13
        case .middleFingerIntermediateBase: 14
        case .middleFingerIntermediateTip: 15
        case .middleFingerTip: 16
        case .ringFingerMetacarpal: 17
        case .ringFingerKnuckle: 18
        case .ringFingerIntermediateBase: 19
        case .ringFingerIntermediateTip: 20
        case .ringFingerTip: 21
        case .littleFingerMetacarpal: 22
        case .littleFingerKnuckle: 23
        case .littleFingerIntermediateBase: 24
        case .littleFingerIntermediateTip: 25
        case .littleFingerTip: 26
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
