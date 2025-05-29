//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/3/25.
//

#if os(iOS)
import ARKit

extension ARMeshAnchor: MeshAnchorRepresentable {
    public var originFromAnchorTransform: simd_float4x4 { transform }
    public var id: UUID { identifier }
    public func shape() async throws -> ShapeResource {
        try await geometry.mesh.shape()
    }
}

extension ARMeshGeometry: MeshAnchorGeometryRepresentable {
    public var mesh: CapturedMeshGeometry {
        CapturedMeshGeometry(vertices: [], normals: [], triangles: [], classifications: [])
    }
}

extension ARMeshAnchor: CapturableARAnchor {
    func capturedAnchor(_ event: CapturedAnchorEvent, timestamp: TimeInterval) -> CapturedAnchor {
        let anchor = CapturedMeshAnchor(captured: self)
        let update = CapturedAnchorUpdate<CapturedMeshAnchor>(anchor: anchor, timestamp: timestamp, event: event)
        return CapturedAnchor.mesh(update)
    }
    
    var capturedGeometry: CapturedMeshAnchor.Geometry {
        let vertices = (0..<UInt32(geometry.vertices.count)).map { index in
            let vertex = geometry.vertex(at: index)
            return SIMD3<Float>(x: vertex.0, y: vertex.1, z: vertex.2)
        }
        
        let triangles = (0 ..< geometry.faces.count).map { index in
            let face = geometry.vertexIndicesOf(faceWithIndex: index)
            return [face[0],face[1],face[2]]
        }
        
        let normals = (0 ..< UInt32(geometry.normals.count)).map { index in
            let normal = geometry.normalsOf(at: index)
            return SIMD3<Float>(normal.0, normal.1, normal.2)
        }
        
        let classifications: [UInt8]
        if let geometryClassifications = geometry.classification {
            classifications = (0 ..< geometryClassifications.count).map { index in
                geometry.classification(at: index) ?? UInt8.max
            }
        } else {
            classifications = []
        }

        let mesh: CapturedMeshGeometry = CapturedMeshGeometry(vertices: vertices, normals: normals, triangles: triangles, classifications: classifications)
        return CapturedMeshAnchor.Geometry(mesh: mesh)
    }
}

extension ARMeshGeometry {
    func classification(at index: Int) -> UInt8? {
        guard let classification else { return nil }
        assert(classification.format == MTLVertexFormat.uchar, "Expected unsigned int per classification.")
        let classificationPointer = classification.buffer.contents().advanced(by: classification.offset + (classification.stride * index))
        let classificationValue = classificationPointer.assumingMemoryBound(to: UInt8.self).pointee
        return classificationValue
    }
    
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
#endif
