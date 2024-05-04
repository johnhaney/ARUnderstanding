//
//  CapturedHandAnchor.swift
//  
//
//  Created by John Haney on 4/13/24.
//

import ARKit

public protocol HandAnchorRepresentable: CapturableAnchor, Hashable {
    associatedtype HandSkeleton: HandSkeletonRepresentable
    var id: UUID { get }
    var chirality: HandAnchor.Chirality { get }
    var handSkeleton: HandSkeleton? { get }
    var isTracked: Bool { get }
    var originFromAnchorTransform: simd_float4x4 { get }
}

extension HandAnchorRepresentable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension HandAnchor: HandAnchorRepresentable {}

public struct CapturedHandAnchor: CapturableAnchor, HandAnchorRepresentable, Sendable {
    public func joint(named jointName: ARKit.HandSkeleton.JointName) -> CapturedHandSkeleton.Joint {
        handSkeleton?.allJoints.first(where: { $0.name == jointName }) ?? CapturedHandSkeleton.Joint(name: jointName, anchorFromJointTransform: simd_float4x4(diagonal: SIMD4<Float>(repeating: 1)), isTracked: false, parentFromJointTransform: simd_float4x4(diagonal: SIMD4<Float>(repeating: 1)), parentJointName: nil)
    }
    
    public let id: UUID
    public let chirality: HandAnchor.Chirality
    public let handSkeleton: CapturedHandSkeleton?
    public let isTracked: Bool
    public let originFromAnchorTransform: simd_float4x4
    public var description: String { "Hand \(originFromAnchorTransform)" }

    public init(id: UUID, chirality: HandAnchor.Chirality, handSkeleton: CapturedHandSkeleton?, isTracked: Bool, originFromAnchorTransform: simd_float4x4) {
        self.id = id
        self.chirality = chirality
        self.handSkeleton = handSkeleton
        self.isTracked = isTracked
        self.originFromAnchorTransform = originFromAnchorTransform
    }
}

extension CapturedHandAnchor {
    public static var neutralPose: CapturedHandAnchor {
        CapturedHandAnchor(id: UUID(), chirality: .left, handSkeleton: CapturedHandSkeleton.neutralPose, isTracked: false, originFromAnchorTransform: simd_float4x4.init(diagonal: SIMD4<Float>(repeating: 1)))
    }
}

public struct CapturedHandSkeleton: HandSkeletonRepresentable, Sendable {
    public func joint(_ named: HandSkeleton.JointName) -> CapturedHandSkeleton.Joint {
        allJoints.first(where: { $0.name == named }) ?? Joint(name: named, anchorFromJointTransform: simd_float4x4(diagonal: SIMD4<Float>(repeating: 1)), isTracked: false, parentFromJointTransform: simd_float4x4(diagonal: SIMD4<Float>(repeating: 1)), parentJointName: nil)
    }
    
    public var allJoints: [Joint]
    public init(allJoints: [Joint]) {
        self.allJoints = allJoints
    }
    
    public struct Joint: HandSkeletonJointRepresentable, Sendable {
        public let name: HandSkeleton.JointName
        public let anchorFromJointTransform: simd_float4x4
        public let isTracked: Bool
        public let parentFromJointTransform: simd_float4x4
        public let parentJointName: String?
        public var parentJoint: Joint? { nil }
        
        public init(name: HandSkeleton.JointName, anchorFromJointTransform: simd_float4x4, isTracked: Bool, parentFromJointTransform: simd_float4x4, parentJointName: String?) {
            self.name = name
            self.anchorFromJointTransform = anchorFromJointTransform
            self.isTracked = isTracked
            self.parentFromJointTransform = parentFromJointTransform
            self.parentJointName = parentJointName
        }
    }
    
    public static var neutralPose: CapturedHandSkeleton {
        HandSkeleton.neutralPose.captured
    }
}

extension HandAnchorRepresentable {
    public var captured: CapturedHandAnchor {
        CapturedHandAnchor(id: id, chirality: chirality, handSkeleton: handSkeleton?.captured, isTracked: isTracked, originFromAnchorTransform: originFromAnchorTransform)
    }
}

public protocol HandSkeletonRepresentable: Hashable {
    associatedtype Joint: HandSkeletonJointRepresentable
    var allJoints: [Joint] { get }
    func joint(_ named: ARKit.HandSkeleton.JointName) -> Joint
}

extension HandSkeletonRepresentable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(allJoints)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.allJoints == rhs.allJoints
    }
}

extension HandSkeleton: HandSkeletonRepresentable {}

extension HandSkeletonRepresentable {
    public var captured: CapturedHandSkeleton {
        CapturedHandSkeleton(allJoints: allJoints.map(\.captured))
    }
}

public protocol HandSkeletonJointRepresentable: Hashable {
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

extension HandSkeleton.Joint: HandSkeletonJointRepresentable {}

extension HandSkeletonJointRepresentable {
    var captured: CapturedHandSkeleton.Joint {
        CapturedHandSkeleton.Joint(
            name: name,
            anchorFromJointTransform: anchorFromJointTransform,
            isTracked: isTracked,
            parentFromJointTransform: parentFromJointTransform,
            parentJointName: parentJoint?.name.description
        )
    }
}

extension HandAnchor {
    public static var neutralPose: CapturedAnchor {
        .hand(CapturedHandAnchor(id: UUID(), chirality: .left, handSkeleton: .neutralPose, isTracked: false, originFromAnchorTransform: simd_float4x4(diagonal: SIMD4<Float>(repeating: 1))).updated(timestamp: 0))
    }
}

