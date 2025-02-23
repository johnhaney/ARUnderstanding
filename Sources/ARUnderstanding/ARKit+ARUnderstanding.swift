//
//  ARKit+ARUnderstanding.swift
//
//  matches definitions and capabilities available on visionOS to ARUnderstanding protocols
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

extension ObjectAnchor: @retroactive Hashable {}
extension ObjectAnchor: ObjectAnchorRepresentable {
    public var referenceObjectName: String {
        referenceObject.name
    }
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
public typealias ObjectAnchor = CapturedObjectAnchor
public typealias PlaneAnchor = CapturedPlaneAnchor
public typealias HandSkeleton = CapturedHandSkeleton
public typealias RoomAnchor = CapturedRoomAnchor

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

extension HandSkeleton.JointName {
    var parentJointName: String? {
        switch self {
        case .forearmArm: Self.forearmWrist.rawValue
        case .forearmWrist: Self.wrist.rawValue
        case .wrist: nil
            
        case .thumbKnuckle: Self.wrist.rawValue
        case .thumbIntermediateBase: Self.thumbKnuckle.rawValue
        case .thumbIntermediateTip: Self.thumbIntermediateBase.rawValue
        case .thumbTip: Self.thumbIntermediateTip.rawValue
            
        case .indexFingerMetacarpal: Self.wrist.rawValue
        case .indexFingerKnuckle: Self.indexFingerMetacarpal.rawValue
        case .indexFingerIntermediateBase: Self.indexFingerKnuckle.rawValue
        case .indexFingerIntermediateTip: Self.indexFingerIntermediateBase.rawValue
        case .indexFingerTip: Self.indexFingerIntermediateTip.rawValue
            
        case .middleFingerMetacarpal: Self.wrist.rawValue
        case .middleFingerKnuckle: Self.middleFingerMetacarpal.rawValue
        case .middleFingerIntermediateBase: Self.middleFingerKnuckle.rawValue
        case .middleFingerIntermediateTip: Self.middleFingerIntermediateBase.rawValue
        case .middleFingerTip: Self.middleFingerIntermediateTip.rawValue
            
        case .ringFingerMetacarpal: Self.wrist.rawValue
        case .ringFingerKnuckle: Self.ringFingerMetacarpal.rawValue
        case .ringFingerIntermediateBase: Self.ringFingerKnuckle.rawValue
        case .ringFingerIntermediateTip: Self.ringFingerIntermediateBase.rawValue
        case .ringFingerTip: Self.ringFingerIntermediateTip.rawValue
            
        case .littleFingerMetacarpal: Self.wrist.rawValue
        case .littleFingerKnuckle: Self.littleFingerMetacarpal.rawValue
        case .littleFingerIntermediateBase: Self.littleFingerKnuckle.rawValue
        case .littleFingerIntermediateTip: Self.littleFingerIntermediateBase.rawValue
        case .littleFingerTip: Self.littleFingerIntermediateTip.rawValue
        @unknown default: nil
        }
    }
    
    var code: UInt8 {
        switch self {
        case .forearmArm: UInt8(1)
        case .forearmWrist: UInt8(2)
        case .wrist: UInt8(3)
        case .thumbIntermediateBase: UInt8(4)
        case .thumbIntermediateTip: UInt8(5)
        case .thumbKnuckle: UInt8(6)
        case .thumbTip: UInt8(7)
        case .indexFingerIntermediateBase: UInt8(8)
        case .indexFingerIntermediateTip: UInt8(9)
        case .indexFingerKnuckle: UInt8(10)
        case .indexFingerMetacarpal: UInt8(11)
        case .indexFingerTip: UInt8(12)
        case .middleFingerIntermediateBase: UInt8(13)
        case .middleFingerIntermediateTip: UInt8(14)
        case .middleFingerKnuckle: UInt8(15)
        case .middleFingerMetacarpal: UInt8(16)
        case .middleFingerTip: UInt8(17)
        case .ringFingerIntermediateBase: UInt8(18)
        case .ringFingerIntermediateTip: UInt8(19)
        case .ringFingerKnuckle: UInt8(20)
        case .ringFingerMetacarpal: UInt8(21)
        case .ringFingerTip: UInt8(22)
        case .littleFingerIntermediateBase: UInt8(23)
        case .littleFingerIntermediateTip: UInt8(24)
        case .littleFingerKnuckle: UInt8(25)
        case .littleFingerMetacarpal: UInt8(26)
        case .littleFingerTip: UInt8(27)
        @unknown default: UInt8(0)
        }
    }
    
    init?(code: UInt8) {
        switch code {
        case UInt8(1): self = .forearmArm
        case UInt8(2): self = .forearmWrist
        case UInt8(3): self = .wrist
        case UInt8(4): self = .thumbIntermediateBase
        case UInt8(5): self = .thumbIntermediateTip
        case UInt8(6): self = .thumbKnuckle
        case UInt8(7): self = .thumbTip
        case UInt8(8): self = .indexFingerIntermediateBase
        case UInt8(9): self = .indexFingerIntermediateTip
        case UInt8(10): self = .indexFingerKnuckle
        case UInt8(11): self = .indexFingerMetacarpal
        case UInt8(12): self = .indexFingerTip
        case UInt8(13): self = .middleFingerIntermediateBase
        case UInt8(14): self = .middleFingerIntermediateTip
        case UInt8(15): self = .middleFingerKnuckle
        case UInt8(16): self = .middleFingerMetacarpal
        case UInt8(17): self = .middleFingerTip
        case UInt8(18): self = .ringFingerIntermediateBase
        case UInt8(19): self = .ringFingerIntermediateTip
        case UInt8(20): self = .ringFingerKnuckle
        case UInt8(21): self = .ringFingerMetacarpal
        case UInt8(22): self = .ringFingerTip
        case UInt8(23): self = .littleFingerIntermediateBase
        case UInt8(24): self = .littleFingerIntermediateTip
        case UInt8(25): self = .littleFingerKnuckle
        case UInt8(26): self = .littleFingerMetacarpal
        case UInt8(27): self = .littleFingerTip
        default: return nil
        }
    }
    
    #if os(visionOS)
    public init?(rawValue: String) {
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
    #endif
}
