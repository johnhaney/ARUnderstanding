//
//  CapturedDeviceAnchor+Visualizable.swift
//
//
//  Created by John Haney on 4/14/24.
//

#if canImport(ARKit)
import ARKit
#endif
import RealityKit

extension CapturedDeviceAnchor: Visualizable {
    @MainActor public func visualize(with materials: [Material]) -> Entity {
        let entity = Entity()
        entity.transform = Transform(matrix: self.originFromAnchorTransform)
        let model = visualizationModel(materials: materials)
        model.transform = Transform(translation: SIMD3<Float>(x: 0, y: 0, z: -0.5))
        entity.addChild(model)
        let model2 = model.clone(recursive: true)
        model2.transform = Transform(scale: SIMD3<Float>(repeating: 30))
        entity.addChild(model2)
        return entity
    }
    
    @MainActor private func visualizationModel(materials: [Material]) -> Entity {
        let mesh = MeshResource.generateSphere(radius: 0.005)
        let model = ModelEntity(mesh: mesh, materials: materials)
        return model
    }

    public func update(visualization entity: Entity, with materials: () -> [any Material]) {
        entity.transform = Transform(matrix: self.originFromAnchorTransform)
    }
}
