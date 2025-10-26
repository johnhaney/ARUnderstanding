//
//  CapturedAccessoryAnchor+Visualizable.swift
//  ARUnderstanding
//
//  Created by John Haney on 10/6/25.
//

#if canImport(ARKit)
import ARKit
#endif
#if canImport(RealityKit)
import RealityKit

@available(visionOS, introduced: 2.0)
@available(iOS, introduced: 18.0)
@available(tvOS, introduced: 26.0)
@available(macOS, introduced: 15.0)
extension CapturedAccessoryAnchor: Visualizable {
    @MainActor public func visualize(in rootEntity: Entity, with materials: [Material]) async {
        rootEntity.transform = Transform(matrix: self.originFromAnchorTransform)
        if !rootEntity.components.has(ModelComponent.self) {
            let mesh = MeshResource.generateCylinder(height: 0.005, radius: 0.025)
            let model = ModelComponent(mesh: mesh, materials: materials)
            rootEntity.components.set(model)
        }
    }
}
#endif
