//
//  CapturedPlaneAnchor.swift
//
//
//  Created by John Haney on 4/13/24.
//

#if canImport(ARKit)
import ARKit
#endif
import Foundation
import RealityKit

public protocol PlaneAnchorRepresentable: CapturableAnchor {
    associatedtype Geometry: PlaneAnchorGeometryRepresentable
    var originFromAnchorTransform: simd_float4x4 { get }
    var id: UUID { get }
    var geometry: Geometry { get }
    var classification: PlaneAnchor.Classification { get }
    var alignment: PlaneAnchor.Alignment { get }
}

extension PlaneAnchorRepresentable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

public struct CapturedPlaneAnchor: Anchor, PlaneAnchorRepresentable, Sendable {
    public var id: UUID
    public var originFromAnchorTransform: simd_float4x4
    public var geometry: Geometry
    public var classification: PlaneAnchor.Classification
    public var alignment: PlaneAnchor.Alignment
    public var description: String { "Plane \(originFromAnchorTransform) \(alignment) \(classification) \(geometry)" }
    public var timestamp: TimeInterval
    
    public init(id: UUID, originFromAnchorTransform: simd_float4x4, geometry: Geometry, classification: PlaneAnchor.Classification, alignment: PlaneAnchor.Alignment, timestamp: TimeInterval) {
        self.id = id
        self.originFromAnchorTransform = originFromAnchorTransform
        self.geometry = geometry
        self.classification = classification
        self.alignment = alignment
        self.timestamp = timestamp
    }
    
#if !os(visionOS)
    public enum Classification: String, Sendable, Hashable {
        case ceiling
        case door
        case floor
        case seat
        case table
        case wall
        case window
        case notAvailable
        case undetermined
        case unknown
        
        var description: String { rawValue }
    }
    
    public enum Alignment: String, Sendable, Hashable {
        case horizontal
        case vertical
        case slanted
        
        var description: String { rawValue }
    }
#endif
    
    public struct Geometry: PlaneAnchorGeometryRepresentable, Sendable {
        public var extent: Extent
        public var mesh: CapturedPlaneMeshGeometry
        public var captured: Self { self }
        
        public init(extent: Extent, mesh: CapturedPlaneMeshGeometry) {
            self.extent = extent
            self.mesh = mesh
        }
        
        public struct Extent: PlaneAnchorGeometryExtentRepresentable, Sendable {
            public var anchorFromExtentTransform: simd_float4x4
            public var width: Float
            public var height: Float
            
            public init(anchorFromExtentTransform: simd_float4x4, width: Float, height: Float) {
                self.anchorFromExtentTransform = anchorFromExtentTransform
                self.width = width
                self.height = height
            }
        }
    }
}

extension PlaneAnchorRepresentable {
    public var captured: CapturedPlaneAnchor {
        CapturedPlaneAnchor(id: id, originFromAnchorTransform: originFromAnchorTransform, geometry: geometry.captured, classification: classification, alignment: alignment, timestamp: timestamp)
    }
}

public protocol PlaneAnchorGeometryRepresentable {
    associatedtype Extent: PlaneAnchorGeometryExtentRepresentable
    var extent: Extent { get }
    var mesh: CapturedPlaneMeshGeometry { get }
    var captured: CapturedPlaneAnchor.Geometry { get }
}

public struct CapturedPlaneMeshGeometry: Sendable {
    var vertices: [SIMD3<Float>]
    var triangles: [[UInt32]]
    
    init(vertices: [SIMD3<Float>], triangles: [[UInt32]]) {
        self.vertices = vertices
        self.triangles = triangles
    }
    
    init(_ geometry: PlaneAnchor.Geometry) {
        #if !os(visionOS)
        vertices = geometry.mesh.vertices
        triangles = geometry.mesh.triangles
        #else
        vertices = []
        triangles = []
        
        for index in 0 ..< geometry.meshVertices.count {
            let vertex = geometry.vertex(at: UInt32(index))
            let vertexPos = SIMD3<Float>(x: vertex.0, y: vertex.1, z: vertex.2)
            vertices.append(vertexPos)
        }
        
        for index in 0 ..< geometry.meshFaces.count {
            let face = geometry.vertexIndicesOf(faceWithIndex: Int(index))
            triangles.append([face[0],face[1],face[2]])
        }
        #endif
    }
    
    func mesh(name: String) async -> MeshResource? {
        var mesh = MeshDescriptor(name: "")
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

#if os(visionOS)
extension PlaneAnchor.Geometry {
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
#endif

public protocol PlaneAnchorGeometryExtentRepresentable {
    var anchorFromExtentTransform: simd_float4x4 { get }
    var width: Float { get }
    var height: Float { get }
}

extension PlaneAnchorGeometryExtentRepresentable {
    var captured: CapturedPlaneAnchor.Geometry.Extent {
        CapturedPlaneAnchor.Geometry.Extent(anchorFromExtentTransform: anchorFromExtentTransform, width: width, height: height)
    }
}
