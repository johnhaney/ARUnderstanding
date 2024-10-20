//
//  NonVisionOS.swift
//
//
//  Created by John Haney on 5/29/24.
//

import Foundation
import ARKit
import RealityKit

#if os(visionOS)
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
        .hand(CapturedHandAnchor(id: UUID(), chirality: .left, handSkeleton: .neutralPose, isTracked: false, originFromAnchorTransform: simd_float4x4(diagonal: SIMD4<Float>(repeating: 1))).updated(timestamp: 0))
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

extension PlaneAnchor.Geometry: PlaneAnchorGeometryRepresentable {
    public var mesh: CapturedPlaneMeshGeometry { CapturedPlaneMeshGeometry(self) }
    public var captured: CapturedPlaneAnchor.Geometry {
        CapturedPlaneAnchor.Geometry(extent: extent.captured, mesh: self.mesh)
    }
}

extension PlaneAnchor.Geometry.Extent: PlaneAnchorGeometryExtentRepresentable {}
#endif
