//
//  CapturedMeshAnchor.swift
//
//
//  Created by John Haney on 4/13/24.
//

#if os(visionOS)
import ARKit
#else
import Foundation
#endif
import RealityKit

public protocol MeshAnchorRepresentable: CapturableAnchor {
    associatedtype Geometry: MeshAnchorGeometryRepresentable
    var geometry: Geometry { get }
    var originFromAnchorTransform: simd_float4x4 { get }
    var id: UUID { get }
    func shape() async throws -> ShapeResource
}

extension MeshAnchorRepresentable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

public struct CapturedMeshAnchor: Anchor, MeshAnchorRepresentable, Sendable {
    public var id: UUID
    public var originFromAnchorTransform: simd_float4x4
    public var geometry: Geometry
    public var description: String { "Mesh \(originFromAnchorTransform) \(geometry)" }
    public var timestamp: TimeInterval

    public init(id: UUID, originFromAnchorTransform: simd_float4x4, geometry: Geometry, timestamp: TimeInterval) {
        self.id = id
        self.originFromAnchorTransform = originFromAnchorTransform
        self.geometry = geometry
        self.timestamp = timestamp
    }
    
    public enum MeshClassification: Int {
        #warning("TODO: Make sure these match rawValue with actual API")
        case ceiling
        case door
        case floor
        case stairs
        case wall
        case window
        case bed
        case cabinet
        case homeAppliance
        case seat
        case table
        case plant
        case tv
        case none
    }
    
    public struct Geometry: MeshAnchorGeometryRepresentable, Sendable {
        public var mesh: CapturedMeshGeometry {
            meshSource.mesh
        }
        public var classifications: [UInt8?] {
            meshSource.classifications
        }
        private var meshSource: CapturedMeshGeometrySource
        
        public var captured: CapturedMeshAnchor.Geometry { self }

        enum CapturedMeshGeometrySource : Sendable {
            case captured(CapturedMeshGeometry)
#if os(visionOS)
            case mesh(MeshAnchor.Geometry)
#endif
            var mesh: CapturedMeshGeometry {
                switch self {
                case .captured(let capturedPlaneMeshGeometry):
                    capturedPlaneMeshGeometry
#if os(visionOS)
                case .mesh(let geometry):
                    CapturedMeshGeometry(geometry)
#endif
                }
            }
            
            var classifications: [UInt8?] {
                switch self {
                case .captured(let capturedPlaneMeshGeometry):
                    return capturedPlaneMeshGeometry.classifications
#if os(visionOS)
                case .mesh(let geometry):
                    let classifications: [UInt8?]
                    if let geometryClassifications = geometry.classifications {
                        classifications = (0 ..< geometryClassifications.count).map { index in
                            geometry.classification(at: index)
                        }
                    } else {
                        classifications = []
                    }
                    return classifications
#endif
                }
            }
        }

        public init(mesh: CapturedMeshGeometry) {
            self.meshSource = .captured(mesh)
        }

#if os(visionOS)
        public init(mesh: MeshAnchor.Geometry) {
            self.meshSource = .mesh(mesh)
        }
#endif
    }
    
    public func shape() async throws -> ShapeResource {
        try await geometry.mesh.shape()
    }
}

extension ShapeResource {
    static func generateStaticMesh(from: any MeshAnchorRepresentable) async throws -> ShapeResource {
        return try await from.shape()
    }
}

public struct CapturedMeshGeometry: Codable, Sendable {
    let vertices: [SIMD3<Float>]
    let normals: [SIMD3<Float>]
    let triangles: [[UInt32]]
    let classifications: [UInt8?]
    
    enum CodingKeys: CodingKey {
        case vertices
        case normals
        case triangles
        case classifications
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.vertices.map({ $0.x.isNaN ? nil : $0}), forKey: .vertices)
        try container.encode(self.normals.map({ $0.x.isNaN ? nil : $0}), forKey: .normals)
        try container.encode(self.triangles, forKey: .triangles)
        try container.encode(self.classifications, forKey: .classifications)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.vertices = (try container.decode([SIMD3<Float>?].self, forKey: .vertices)).map { $0 ?? [Float.nan, Float.nan, Float.nan] }
        self.normals = (try container.decode([SIMD3<Float>?].self, forKey: .normals)).map { $0 ?? [Float.nan, Float.nan, Float.nan] }
        self.triangles = try container.decode([[UInt32]].self, forKey: .triangles)
        self.classifications = try container.decode([UInt8?].self, forKey: .classifications)
    }
    
    #if os(visionOS)
    init(_ geometry: MeshAnchor.Geometry) {
        vertices = (0..<UInt32(geometry.vertices.count)).map { index in
            let vertex = geometry.vertex(at: index)
            return SIMD3<Float>(x: vertex.0, y: vertex.1, z: vertex.2)
        }
        
        triangles = (0 ..< geometry.faces.count).map { index in
            let face = geometry.vertexIndicesOf(faceWithIndex: index)
            return [face[0],face[1],face[2]]
        }
        
        normals = (0 ..< UInt32(geometry.normals.count)).map { index in
            let normal = geometry.normalsOf(at: index)
            return SIMD3<Float>(normal.0, normal.1, normal.2)
        }
        
        if let geometryClassifications = geometry.classifications {
            classifications = (0 ..< geometryClassifications.count).map { index in
                geometry.classification(at: index)
            }
        } else {
            classifications = []
        }
    }
    #endif
    
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
    
    func shape() async throws -> ShapeResource {
        try await ShapeResource.generateStaticMesh(
            positions: vertices,
            faceIndices: triangles.flatMap({ $0 }).map(UInt16.init)
        )
    }
}

extension MeshAnchorRepresentable {
    public var captured: CapturedMeshAnchor {
        CapturedMeshAnchor(id: id, originFromAnchorTransform: originFromAnchorTransform, geometry: geometry.captured, timestamp: timestamp)
    }
}

public protocol MeshAnchorGeometryRepresentable {
    var mesh: CapturedMeshGeometry { get }
}


extension MeshAnchorGeometryRepresentable {
    var captured: CapturedMeshAnchor.Geometry {
        CapturedMeshAnchor.Geometry(mesh: mesh)
    }
}


#if os(visionOS)
extension MeshAnchor.Geometry {
    func classification(at index: Int) -> UInt8? {
        guard let classifications else { return nil }
        assert(classifications.format == MTLVertexFormat.uchar, "Expected unsigned int per classification.")
        let classificationPointer = classifications.buffer.contents().advanced(by: classifications.offset + (classifications.stride * index))
        let classification = classificationPointer.assumingMemoryBound(to: UInt8.self).pointee
        return classification
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
