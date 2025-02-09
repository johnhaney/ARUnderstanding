//
//  NonVisionOS.swift
//
//
//  Created by John Haney on 5/29/24.
//

#if os(visionOS)
import Foundation
import ARKit
import RealityKit

extension MeshAnchor: @retroactive Hashable {}
extension MeshAnchor: MeshAnchorRepresentable {
    public func shape() async throws -> ShapeResource {
        try await ShapeResource.generateStaticMesh(from: self)
    }
}

extension MeshAnchor.Geometry: MeshAnchorGeometryRepresentable {
    public var mesh: CapturedMeshGeometry { CapturedMeshGeometry(self) }
}

extension HandAnchor: @retroactive Hashable {}
extension HandAnchor: HandAnchorRepresentable {}

extension HandSkeleton: @retroactive Hashable {}
extension HandSkeleton: HandSkeletonRepresentable {}

extension HandSkeleton.Joint: @retroactive Hashable {}
extension HandSkeleton.Joint: HandSkeletonJointRepresentable {}

extension HandAnchor {
    public static var neutralPose: CapturedAnchor {
        .hand(CapturedHandAnchor(id: UUID(), chirality: .left, handSkeleton: .neutralPose, isTracked: false, originFromAnchorTransform: simd_float4x4(diagonal: SIMD4<Float>(repeating: 1)), timestamp: 0).updated(timestamp: 0))
    }
}

extension ImageAnchor: @retroactive Hashable {}
extension ImageAnchor: ImageAnchorRepresentable {
    public var referenceImageName: String? { referenceImage.name }
    public var estimatedPhysicalWidth: Float { estimatedScaleFactor * Float(referenceImage.physicalSize.width) }
    public var estimatedPhysicalHeight: Float { estimatedScaleFactor * Float(referenceImage.physicalSize.height) }
}

extension PlaneAnchor: @retroactive Hashable {}
extension PlaneAnchor: PlaneAnchorRepresentable {}

extension DeviceAnchor: @retroactive Hashable {}
extension DeviceAnchor: @retroactive Equatable {}
extension DeviceAnchor: DeviceAnchorRepresentable {}

extension WorldAnchor: @retroactive Hashable {}
extension WorldAnchor: WorldAnchorRepresentable {}

extension RoomAnchor: @retroactive Hashable {}
extension RoomAnchor: RoomAnchorRepresentable {}

extension PlaneAnchor.Geometry: PlaneAnchorGeometryRepresentable {
    public var mesh: CapturedPlaneMeshGeometry { CapturedPlaneMeshGeometry(self) }
    public var captured: CapturedPlaneAnchor.Geometry {
        CapturedPlaneAnchor.Geometry(extent: extent.captured, mesh: self.mesh)
    }
}

extension PlaneAnchor.Geometry.Extent: PlaneAnchorGeometryExtentRepresentable {}

#else

public typealias HandAnchor = CapturedHandAnchor
public typealias MeshAnchor = CapturedMeshAnchor
public typealias WorldAnchor = CapturedWorldAnchor
public typealias ImageAnchor = CapturedImageAnchor
public typealias PlaneAnchor = CapturedPlaneAnchor
public typealias HandSkeleton = CapturedHandSkeleton

public extension HandAnchor {
    enum Chirality: Sendable {
        case left
        case right
    }
}

extension HandSkeleton {
    public enum JointName: String, Sendable {
        case forearmArm
        case forearmWrist
        case wrist
        case thumbIntermediateBase
        case thumbIntermediateTip
        case thumbKnuckle
        case thumbTip
        case indexFingerIntermediateBase
        case indexFingerIntermediateTip
        case indexFingerKnuckle
        case indexFingerMetacarpal
        case indexFingerTip
        case middleFingerIntermediateBase
        case middleFingerIntermediateTip
        case middleFingerKnuckle
        case middleFingerMetacarpal
        case middleFingerTip
        case ringFingerIntermediateBase
        case ringFingerIntermediateTip
        case ringFingerKnuckle
        case ringFingerMetacarpal
        case ringFingerTip
        case littleFingerIntermediateBase
        case littleFingerIntermediateTip
        case littleFingerKnuckle
        case littleFingerMetacarpal
        case littleFingerTip
        
        public var description: String {
            switch self {
            case .forearmArm: "forearmArm"
            case .forearmWrist: "forearmWrist"
            case .wrist: "wrist"
            case .thumbIntermediateBase: "thumbIntermediateBase"
            case .thumbIntermediateTip: "thumbIntermediateTip"
            case .thumbKnuckle: "thumbKnuckle"
            case .thumbTip: "thumbTip"
            case .indexFingerIntermediateBase: "indexFingerIntermediateBase"
            case .indexFingerIntermediateTip: "indexFingerIntermediateTip"
            case .indexFingerKnuckle: "indexFingerKnuckle"
            case .indexFingerMetacarpal: "indexFingerMetacarpal"
            case .indexFingerTip: "indexFingerTip"
            case .middleFingerIntermediateBase: "middleFingerIntermediateBase"
            case .middleFingerIntermediateTip: "middleFingerIntermediateTip"
            case .middleFingerKnuckle: "middleFingerKnuckle"
            case .middleFingerMetacarpal: "middleFingerMetacarpal"
            case .middleFingerTip: "middleFingerTip"
            case .ringFingerIntermediateBase: "ringFingerIntermediateBase"
            case .ringFingerIntermediateTip: "ringFingerIntermediateTip"
            case .ringFingerKnuckle: "ringFingerKnuckle"
            case .ringFingerMetacarpal: "ringFingerMetacarpal"
            case .ringFingerTip: "ringFingerTip"
            case .littleFingerIntermediateBase: "littleFingerIntermediateBase"
            case .littleFingerIntermediateTip: "littleFingerIntermediateTip"
            case .littleFingerKnuckle: "littleFingerKnuckle"
            case .littleFingerMetacarpal: "littleFingerMetacarpal"
            case .littleFingerTip: "littleFingerTip"

            }
        }
    }
}
#endif
