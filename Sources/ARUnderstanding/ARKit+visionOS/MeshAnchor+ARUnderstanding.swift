//
//  MeshAnchor+ARUnderstanding.swift
//  ARUnderstanding
//
//  Created by John Haney on 5/27/25.
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
#else
public typealias MeshAnchor = CapturedMeshAnchor
#endif
