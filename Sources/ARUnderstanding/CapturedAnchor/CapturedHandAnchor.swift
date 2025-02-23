//
//  CapturedHandAnchor.swift
//  
//
//  Created by John Haney on 4/13/24.
//

#if canImport(ARKit)
import ARKit
#else
import Foundation
import RealityKit
#endif

public protocol HandAnchorRepresentable: CapturableAnchor, Hashable {
    associatedtype HandSkeletonType: HandSkeletonRepresentable
    var id: UUID { get }
    var chirality: HandAnchor.Chirality { get }
    var handSkeleton: HandSkeletonType? { get }
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

#if os(visionOS)
public typealias JointName = ARKit.HandSkeleton.JointName
#else
public typealias JointName = HandSkeleton.JointName
#endif

public struct CapturedHandAnchor: CapturableAnchor, HandAnchorRepresentable, Sendable, Equatable {
    public func joint(named jointName: JointName) -> CapturedHandSkeleton.Joint {
        handSkeleton?.allJoints.first(where: { $0.name == jointName }) ?? CapturedHandSkeleton.Joint(name: jointName, anchorFromJointTransform: simd_float4x4(diagonal: SIMD4<Float>(repeating: 1)), isTracked: false, parentFromJointTransform: simd_float4x4(diagonal: SIMD4<Float>(repeating: 1)), parentJointName: nil)
    }
    
    public let id: UUID
    public let chirality: HandAnchor.Chirality
    public let handSkeleton: CapturedHandSkeleton?
    public let isTracked: Bool
    public let originFromAnchorTransform: simd_float4x4
    public var description: String { "Hand \(originFromAnchorTransform)" }
    public var timestamp: TimeInterval
    
    public init(id: UUID, chirality: HandAnchor.Chirality, handSkeleton: CapturedHandSkeleton?, isTracked: Bool, originFromAnchorTransform: simd_float4x4, timestamp: TimeInterval) {
        self.id = id
        self.chirality = chirality
        self.handSkeleton = handSkeleton
        self.isTracked = isTracked
        self.originFromAnchorTransform = originFromAnchorTransform
        self.timestamp = timestamp
    }
}

extension CapturedHandAnchor {
    public static var neutralPose: CapturedHandAnchor {
        CapturedHandAnchor(id: UUID(), chirality: .left, handSkeleton: CapturedHandSkeleton.neutralPose, isTracked: false, originFromAnchorTransform: simd_float4x4.init(diagonal: SIMD4<Float>(repeating: 1)), timestamp: TimeInterval(0))
    }
}

public struct CapturedHandSkeleton: HandSkeletonRepresentable, Sendable, Equatable {
    public func joint(_ named: HandSkeleton.JointName) -> CapturedHandSkeleton.Joint {
        allJoints.first(where: { $0.name == named }) ?? Joint(name: named, anchorFromJointTransform: simd_float4x4(diagonal: SIMD4<Float>(repeating: 1)), isTracked: false, parentFromJointTransform: simd_float4x4(diagonal: SIMD4<Float>(repeating: 1)), parentJointName: nil)
    }
    
    public var allJoints: [Joint]
    public init(allJoints: [Joint]) {
        let jointByName = Dictionary(grouping: allJoints, by: \.name)
        self.allJoints = allJoints.map({ $0.with(parentFrom: jointByName) })
    }
    
    public struct Joint: HandSkeletonJointRepresentable, Sendable, Equatable {
        public let name: HandSkeleton.JointName
        public let anchorFromJointTransform: simd_float4x4
        public let isTracked: Bool
        public let parentFromJointTransform: simd_float4x4
        public let parentJointName: String?
        public var parentJoint: Joint? { parentJointSource?.first }
        var parentJointSource: [Joint]? = nil
        
        public init(name: HandSkeleton.JointName, anchorFromJointTransform: simd_float4x4, isTracked: Bool, parentFromJointTransform: simd_float4x4, parentJointName: String?) {
            self.name = name
            self.anchorFromJointTransform = anchorFromJointTransform
            self.isTracked = isTracked
            self.parentFromJointTransform = parentFromJointTransform
            self.parentJointName = parentJointName
        }
        
        init(name: HandSkeleton.JointName, anchorFromJointTransform: simd_float4x4, isTracked: Bool, parentFromJointTransform: simd_float4x4, parentJointName: String?, parentJointSource: [Joint]? = nil) {
            self.name = name
            self.anchorFromJointTransform = anchorFromJointTransform
            self.isTracked = isTracked
            self.parentFromJointTransform = parentFromJointTransform
            self.parentJointName = parentJointName
            self.parentJointSource = parentJointSource
        }
        
        func with(parentFrom from: [HandSkeleton.JointName: [Joint]]) -> Self {
            guard let parentJointName,
                  let jointName = HandSkeleton.JointName(rawValue: parentJointName),
                  let joint = from[jointName]?.first
            else { return self }
            
            return Joint(name: name,
                         anchorFromJointTransform: anchorFromJointTransform,
                         isTracked: isTracked,
                         parentFromJointTransform: parentFromJointTransform,
                         parentJointName: parentJointName,
                         parentJointSource: [joint])
        }
    }
    
    public static var neutralPose: CapturedHandSkeleton {
        if HandSkeleton.self == CapturedHandSkeleton.self {
            CapturedHandSkeleton(allJoints: [])
        } else {
            HandSkeleton.neutralPose.captured
        }
    }
}

extension HandAnchorRepresentable {
    public var captured: CapturedHandAnchor {
        CapturedHandAnchor(id: id, chirality: chirality, handSkeleton: handSkeleton?.captured, isTracked: isTracked, originFromAnchorTransform: originFromAnchorTransform, timestamp: timestamp)
    }
}

public protocol HandSkeletonRepresentable: Hashable {
    associatedtype Joint: HandSkeletonJointRepresentable
    var allJoints: [Joint] { get }
    #if os(visionOS)
    func joint(_ named: ARKit.HandSkeleton.JointName) -> Joint
    #else
    func joint(_ named: HandSkeleton.JointName) -> Joint
    #endif
}

extension HandSkeletonRepresentable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(allJoints)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.allJoints == rhs.allJoints
    }
}

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

