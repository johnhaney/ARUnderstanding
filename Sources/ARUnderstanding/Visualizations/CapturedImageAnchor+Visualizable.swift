//
//  CapturedImageAnchor+Visualizable.swift
//
//
//  Created by John Haney on 4/14/24.
//

#if canImport(ARKit)
import ARKit
#endif
import RealityKit

extension CapturedImageAnchor: Visualizable {
    @MainActor public func visualize(in rootEntity: Entity, with materials: [Material]) async {
        rootEntity.transform = Transform(matrix: self.originFromAnchorTransform)
        if !rootEntity.components.has(ModelComponent.self) {
            let mesh = MeshResource.generatePlane(width: 1, height: 1)
            let model = ModelComponent(mesh: mesh, materials: materials)
            rootEntity.components.set(model)
        }
        rootEntity.transform.scale = SIMD3<Float>(x: estimatedPhysicalWidth, y: estimatedPhysicalHeight, z: 1)
    }
}
