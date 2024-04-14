//
//  CapturedMeshAnchor+Visualizable.swift
//
//
//  Created by John Haney on 4/14/24.
//

import ARKit
import RealityKit

extension CapturedMeshAnchor: Visualizable {
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

extension MeshAnchorRepresentable {
    func mesh(name: String) async -> MeshResource? {
        var vertices: [SIMD3<Float>] = []
        var triangles: [[UInt32]] = []
        var normals: [SIMD3<Float>] = []
        
        /// Extract the vertices using the Extension from Apple (VisualizingSceneSemantics)
        for index in 0 ..< geometry.vertices.count {
            let vertex = geometry.vertex(at: UInt32(index))
            let vertexPos = SIMD3<Float>(x: vertex.0, y: vertex.1, z: vertex.2)
            vertices.append(vertexPos)
        }
        /// Extract the faces
        for index in 0 ..< geometry.faces.count {
            let face = geometry.vertexIndicesOf(faceWithIndex: Int(index))
            triangles.append([face[0],face[1],face[2]])
        }
        /// Extract the normals. Normals uses an additional extension "normalsOf()"
        for index in 0 ..< geometry.normals.count {
            let normal = geometry.normalsOf(at: UInt32(index))
            normals.append(SIMD3<Float>(normal.0, normal.1, normal.2))
        }
        
        var mesh = MeshDescriptor(name: name)
        let faces = triangles.flatMap({ $0 })
        let positions = MeshBuffers.Positions(vertices)
        do {
            let triangles = MeshDescriptor.Primitives.triangles(faces)
            let normals = MeshBuffers.Normals(normals)
            
            mesh.positions = positions
            mesh.primitives = triangles
            mesh.normals = normals
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

extension MeshAnchorGeometryRepresentable {
    func vertex(at index: UInt32) -> (Float, Float, Float) {
        assert(vertices.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per vertex.")
        let vertexPointer = vertices.buffer.contents().advanced(by: vertices.offset + (vertices.stride * Int(index)))
        let vertex = vertexPointer.assumingMemoryBound(to: (Float, Float, Float).self).pointee
        return vertex
    }
    
    func vertexIndicesOf(faceWithIndex faceIndex: Int) -> [UInt32] {
        assert(faces.bytesPerIndex == MemoryLayout<UInt32>.size, "Expected one UInt32 (four bytes) per vertex index")
        let vertexCountPerFace = 3 // assume triangles
        let vertexIndicesPointer = faces.buffer.contents()
        var vertexIndices = [UInt32]()
        vertexIndices.reserveCapacity(vertexCountPerFace)
        for vertexOffset in 0..<vertexCountPerFace {
            let vertexIndexPointer = vertexIndicesPointer.advanced(by: (faceIndex * vertexCountPerFace + vertexOffset) * MemoryLayout<UInt32>.size)
            vertexIndices.append(vertexIndexPointer.assumingMemoryBound(to: UInt32.self).pointee)
        }
        return vertexIndices
    }
    
    func verticesOf(faceWithIndex index: Int) -> [(Float, Float, Float)] {
        let vertexIndices = vertexIndicesOf(faceWithIndex: index)
        let vertices = vertexIndices.map { vertex(at: $0) }
        return vertices
    }
    
    func centerOf(faceWithIndex index: Int) -> (Float, Float, Float) {
        let vertices = verticesOf(faceWithIndex: index)
        let sum = vertices.reduce((0, 0, 0)) { ($0.0 + $1.0, $0.1 + $1.1, $0.2 + $1.2) }
        let geometricCenter = (sum.0 / 3, sum.1 / 3, sum.2 / 3)
        return geometricCenter
    }
    
    func normalsOf(at index: UInt32) -> (Float, Float, Float) {
        assert(normals.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per vertex.")
        
        let normalPointer = normals.buffer.contents().advanced(by: normals.offset + (normals.stride * Int(index)))
        
        let normal = normalPointer.assumingMemoryBound(to: (Float, Float, Float).self).pointee
        return normal
    }
}
