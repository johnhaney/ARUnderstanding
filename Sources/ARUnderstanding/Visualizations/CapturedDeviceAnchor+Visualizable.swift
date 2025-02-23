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
        entity.addChild(model)
        return entity
    }
    
    @MainActor private func visualizationModel(materials: [Material]) -> Entity {
        let mesh = MeshResource.generateBox(width: 0.14, height: 0.22, depth: 0.14, cornerRadius: 0.02)
        let model = ModelEntity(mesh: mesh, materials: materials)
        return model
    }

    public func update(visualization entity: Entity, with materials: () -> [any Material]) {
        entity.transform = Transform(matrix: self.originFromAnchorTransform)
    }
}
