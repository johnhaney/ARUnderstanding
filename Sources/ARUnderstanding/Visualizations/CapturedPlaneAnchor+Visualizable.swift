//
//  CapturedPlaneAnchor+Visualizable.swift
//
//
//  Created by John Haney on 4/14/24.
//

import ARKit
import RealityKit

extension CapturedPlaneAnchor: Visualizable {
    func visualize(with materials: [Material]) -> Entity {
        let entity = Entity()
        entity.transform = Transform(matrix: self.originFromAnchorTransform)
        Task {
            if let model = await visualizationModel(materials: materials) {
                await entity.addChild(model)
            }
        }

        return entity
    }
    
    private func visualizationModel(materials: [Material]) async -> Entity? {
        guard let mesh: MeshResource = await mesh(name: "Visualization")
        else { return nil }
        let model = await ModelEntity(mesh: mesh, materials: materials)
        return model
    }
    
    func update(visualization entity: Entity, with materials: () -> [Material]) {
        let transform = Transform(matrix: self.originFromAnchorTransform)
        entity.transform = transform
        // Remove the previous mesh and we will start over each time
        for child in entity.children {
            child.removeFromParent()
        }
        let materials = materials()
        Task {
            if let model = await visualizationModel(materials: materials) {
                await update(visualization: entity, with: model, transform: transform)
            }
        }
    }
    
    @MainActor
    private func update(visualization entity: Entity, with model: Entity, transform: Transform) {
        entity.addChild(model)
    }
}

extension PlaneAnchorRepresentable {
    func mesh(name: String) async -> MeshResource? {
        var vertices: [SIMD3<Float>] = []
        var triangles: [[UInt32]] = []
        
        for index in 0 ..< geometry.meshVertices.count {
            let vertex = geometry.vertex(at: UInt32(index))
            let vertexPos = SIMD3<Float>(x: vertex.0, y: vertex.1, z: vertex.2)
            vertices.append(vertexPos)
        }
        
        for index in 0 ..< geometry.meshFaces.count {
            let face = geometry.vertexIndicesOf(faceWithIndex: Int(index))
            triangles.append([face[0],face[1],face[2]])
        }

        var mesh = MeshDescriptor(name: name)
        let faces = triangles.flatMap({ $0 })
        let positions = MeshBuffers.Positions(vertices)
        do {
            let triangles = MeshDescriptor.Primitives.triangles(faces)
            mesh.positions = positions
            mesh.primitives = triangles
        }
        
        do {
            let resource = try await MeshResource(from: [mesh])
            return resource
        } catch {
            print("Error creating mesh resource: \(error.localizedDescription)")
            return nil
        }
    }
}

extension PlaneAnchorGeometryRepresentable {
    func vertex(at index: UInt32) -> (Float, Float, Float) {
        assert(meshVertices.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per vertex.")
        let vertexPointer = meshVertices.buffer.contents().advanced(by: meshVertices.offset + (meshVertices.stride * Int(index)))
        let vertex = vertexPointer.assumingMemoryBound(to: (Float, Float, Float).self).pointee
        return vertex
    }
    
    func vertexIndicesOf(faceWithIndex faceIndex: Int) -> [UInt32] {
        assert(meshFaces.bytesPerIndex == MemoryLayout<UInt32>.size, "Expected one UInt32 (four bytes) per vertex index")
        let vertexCountPerFace = 3 // assume triangles
        let vertexIndicesPointer = meshFaces.buffer.contents()
        var vertexIndices = [UInt32]()
        vertexIndices.reserveCapacity(vertexCountPerFace)
        for vertexOffset in 0..<vertexCountPerFace {
            let vertexIndexPointer = vertexIndicesPointer.advanced(by: (faceIndex * vertexCountPerFace + vertexOffset) * MemoryLayout<UInt32>.size)
            vertexIndices.append(vertexIndexPointer.assumingMemoryBound(to: UInt32.self).pointee)
        }
        return vertexIndices
    }
}
