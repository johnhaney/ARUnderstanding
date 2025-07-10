//
//  CapturedDeviceAnchor+Visualizable.swift
//
//
//  Created by John Haney on 4/14/24.
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
extension CapturedDeviceAnchor: Visualizable {
    @MainActor public func visualize(in rootEntity: Entity, with materials: [Material]) async {
        rootEntity.transform = Transform(matrix: self.originFromAnchorTransform)
        if !rootEntity.components.has(ModelComponent.self) {
            let mesh = MeshResource.generateBox(width: 0.14, height: 0.22, depth: 0.14, cornerRadius: 0.02)
            let model = ModelComponent(mesh: mesh, materials: materials)
            rootEntity.components.set(model)
        }
    }
}
#endif
