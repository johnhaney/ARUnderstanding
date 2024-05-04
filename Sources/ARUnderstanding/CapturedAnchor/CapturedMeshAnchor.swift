//
//  CapturedMeshAnchor.swift
//
//
//  Created by John Haney on 4/13/24.
//

import ARKit
import RealityKit

public protocol MeshAnchorRepresentable: CapturableAnchor {
    associatedtype Geometry: MeshAnchorGeometryRepresentable
    var geometry: Geometry { get }
    var originFromAnchorTransform: simd_float4x4 { get }
    var id: UUID { get }
}

extension MeshAnchorRepresentable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension MeshAnchor: MeshAnchorRepresentable {}

public struct CapturedMeshAnchor: Anchor, MeshAnchorRepresentable, Sendable {
    public var id: UUID
    public var originFromAnchorTransform: simd_float4x4
    public var geometry: Geometry
    public var description: String { "Mesh \(originFromAnchorTransform) \(geometry)" }

    public init(id: UUID, originFromAnchorTransform: simd_float4x4, geometry: Geometry) {
        self.id = id
        self.originFromAnchorTransform = originFromAnchorTransform
        self.geometry = geometry
    }
    
    public struct Geometry: MeshAnchorGeometryRepresentable, Sendable {
        public var mesh: CapturedMeshGeometry {
            meshSource.mesh
        }
        private var meshSource: CapturedMeshGeometrySource
        
        public var captured: CapturedMeshAnchor.Geometry { self }

        enum CapturedMeshGeometrySource {
            case captured(CapturedMeshGeometry)
            case mesh(MeshAnchor.Geometry)
            
            var mesh: CapturedMeshGeometry {
                switch self {
                case .captured(let capturedPlaneMeshGeometry):
                    capturedPlaneMeshGeometry
                case .mesh(let geometry):
                    CapturedMeshGeometry(geometry)
                }
            }
        }

        public init(mesh: CapturedMeshGeometry) {
            self.meshSource = .captured(mesh)
        }

        public init(mesh: MeshAnchor.Geometry) {
            self.meshSource = .mesh(mesh)
        }
    }
}

public struct CapturedMeshGeometry: Codable {
    var vertices: [SIMD3<Float>]
    var normals: [SIMD3<Float>]
    var triangles: [[UInt32]]
    var classifications: [Int?]
    
    init(_ geometry: MeshAnchor.Geometry) {
        vertices = []
        triangles = []
        normals = []
        classifications = []
        
        for index in 0 ..< geometry.vertices.count {
            let vertex = geometry.vertex(at: UInt32(index))
            let vertexPos = SIMD3<Float>(x: vertex.0, y: vertex.1, z: vertex.2)
            vertices.append(vertexPos)
        }
        
        for index in 0 ..< geometry.faces.count {
            let face = geometry.vertexIndicesOf(faceWithIndex: Int(index))
            triangles.append([face[0],face[1],face[2]])
        }
        
        for index in 0 ..< geometry.normals.count {
            let normal = geometry.normalsOf(at: UInt32(index))
            normals.append(SIMD3<Float>(normal.0, normal.1, normal.2))
        }
    }
    
    func mesh(name: String) async -> MeshResource? {
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

extension MeshAnchorRepresentable {
    public var captured: CapturedMeshAnchor {
        CapturedMeshAnchor(id: id, originFromAnchorTransform: originFromAnchorTransform, geometry: geometry.captured)
    }
}

public protocol MeshAnchorGeometryRepresentable {
    var mesh: CapturedMeshGeometry { get }
}

extension MeshAnchor.Geometry: MeshAnchorGeometryRepresentable {
    public var mesh: CapturedMeshGeometry { CapturedMeshGeometry(self) }
}

extension MeshAnchorGeometryRepresentable {
    var captured: CapturedMeshAnchor.Geometry {
        CapturedMeshAnchor.Geometry(mesh: mesh)
    }
}


extension MeshAnchor.Geometry {
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
