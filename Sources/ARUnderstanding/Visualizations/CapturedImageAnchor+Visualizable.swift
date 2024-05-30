//
//  CapturedImageAnchor+Visualizable.swift
//
//
//  Created by John Haney on 4/14/24.
//

#if os(visionOS)
import ARKit
import RealityKit

extension CapturedImageAnchor: Visualizable {
    public func visualize(with materials: [Material]) -> Entity {
        let entity = Entity()
        entity.transform = Transform(matrix: self.originFromAnchorTransform)
        
        let model = visualizationModel(materials: materials)

        model.transform.scale = SIMD3<Float>(x: estimatedPhysicalWidth, y: estimatedPhysicalHeight, z: 1)
        entity.addChild(model)
        
        return entity
    }
    
    private func visualizationModel(materials: [Material]) -> Entity {
        let mesh = MeshResource.generatePlane(width: 1, height: 1)
        let model = ModelEntity(mesh: mesh, materials: materials)
        model.name = "Image"
        return model
    }

    public func update(visualization entity: Entity, with materials: () -> [Material]) {
        entity.transform = Transform(matrix: self.originFromAnchorTransform)
        guard let model = entity.findEntity(named: "Image") ?? entity.children.first
        else { return }
        model.transform.scale = SIMD3<Float>(x: estimatedPhysicalWidth, y: estimatedPhysicalHeight, z: 1)
    }
}
#endif
