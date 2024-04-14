//
//  CapturedWorldAnchor+Visualizable.swift
//
//
//  Created by John Haney on 4/14/24.
//

import ARKit
import RealityKit

extension CapturedWorldAnchor: Visualizable {
    func visualize(with materials: [Material]) -> Entity {
        let entity = Entity()
        entity.transform = Transform(matrix: self.originFromAnchorTransform)
        let model = visualizationModel(materials: materials)
        entity.addChild(model)
        return entity
    }
    
    private func visualizationModel(materials: [Material]) -> Entity {
        let mesh = MeshResource.generateSphere(radius: 0.005)
        let model = ModelEntity(mesh: mesh, materials: materials)
        return model
    }

    func update(visualization entity: Entity, with materials: () -> [any Material]) {
        entity.transform = Transform(matrix: self.originFromAnchorTransform)
    }
}
