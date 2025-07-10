//
//  CapturedMeshAnchor+Visualizable.swift
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
extension CapturedMeshAnchor: Visualizable {
    @MainActor public func visualize(in rootEntity: Entity, with materials: [Material]) async {
        if await visualizeInPlace(in: rootEntity, with: materials) {
            return
        }
        
        // Create and visualize mesh under given root
        rootEntity.transform = Transform(matrix: self.originFromAnchorTransform)
        guard let mesh: MeshResource = await mesh(name: "Visualization")
        else { return }
        let model = ModelComponent(mesh: mesh, materials: materials)
        rootEntity.components.set(model)
    }
    
    @MainActor public func visualizeInPlace(in rootEntity: Entity, with materials: [Material]) async -> Bool {
        #if os(iOS)
        guard let _ = self.base as? ARMeshAnchor else { return false }
        // iOS and macOS the meshes are already added to the scene locally
        // so we will just decorate them with the visualization
        guard let scene = rootEntity.scene else { return false }
        
        let sceneUnderstandingQuery = EntityQuery(where: .has(SceneUnderstandingComponent.self) && .has(ModelComponent.self))
        let queryResult = scene.performQuery(sceneUnderstandingQuery)
        queryResult.forEach { entity in
            entity.components[ModelComponent.self]?.materials = materials
        }
        return true
        #else
        return false
        #endif
    }
}

@available(visionOS, introduced: 2.0)
@available(iOS, introduced: 18.0)
@available(tvOS, introduced: 26.0)
@available(macOS, introduced: 15.0)
extension MeshAnchorRepresentable {
    func mesh(name: String) async -> MeshResource? {
        await geometry.mesh.mesh(name: name)
    }
}
#endif
