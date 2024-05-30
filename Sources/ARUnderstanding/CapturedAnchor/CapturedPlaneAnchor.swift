//
//  CapturedPlaneAnchor.swift
//
//
//  Created by John Haney on 4/13/24.
//

#if os(visionOS)
import ARKit
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

extension PlaneAnchor: PlaneAnchorRepresentable {}

public struct CapturedPlaneAnchor: Anchor, PlaneAnchorRepresentable, Sendable {
    public var id: UUID
    public var originFromAnchorTransform: simd_float4x4
    public var geometry: Geometry
    public var classification: PlaneAnchor.Classification
    public var alignment: PlaneAnchor.Alignment
    public var description: String { "Plane \(originFromAnchorTransform) \(alignment) \(classification) \(geometry)" }

    public init(id: UUID, originFromAnchorTransform: simd_float4x4, geometry: Geometry, classification: PlaneAnchor.Classification, alignment: PlaneAnchor.Alignment) {
        self.id = id
        self.originFromAnchorTransform = originFromAnchorTransform
        self.geometry = geometry
        self.classification = classification
        self.alignment = alignment
    }
    
    public struct Geometry: PlaneAnchorGeometryRepresentable, Sendable {
        public var extent: Extent
        public var mesh: CapturedPlaneMeshGeometry {
            meshSource.mesh
        }
        private var meshSource: CapturedPlaneMeshGeometrySource
        
        public var captured: CapturedPlaneAnchor.Geometry { self }

        enum CapturedPlaneMeshGeometrySource {
            case captured(CapturedPlaneMeshGeometry)
            case mesh(PlaneAnchor.Geometry)
            
            var mesh: CapturedPlaneMeshGeometry {
                switch self {
                case .captured(let capturedPlaneMeshGeometry):
                    capturedPlaneMeshGeometry
                case .mesh(let geometry):
                    CapturedPlaneMeshGeometry(geometry)
                }
            }
        }

        public init(extent: Extent, mesh: CapturedPlaneMeshGeometry) {
            self.extent = extent
            self.meshSource = .captured(mesh)
        }
        
        public init(extent: Extent, mesh: PlaneAnchor.Geometry) {
            self.extent = extent
            self.meshSource = .mesh(mesh)
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
        CapturedPlaneAnchor(id: id, originFromAnchorTransform: originFromAnchorTransform, geometry: geometry.captured, classification: classification, alignment: alignment)
    }
}

public protocol PlaneAnchorGeometryRepresentable {
    associatedtype Extent: PlaneAnchorGeometryExtentRepresentable
    var extent: Extent { get }
    var mesh: CapturedPlaneMeshGeometry { get }
    var captured: CapturedPlaneAnchor.Geometry { get }
}

public struct CapturedPlaneMeshGeometry: Codable {
    var vertices: [SIMD3<Float>]
    var triangles: [[UInt32]]
    
    init(_ geometry: PlaneAnchor.Geometry) {
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

extension PlaneAnchor.Geometry: PlaneAnchorGeometryRepresentable {
    public var mesh: CapturedPlaneMeshGeometry { CapturedPlaneMeshGeometry(self) }
    public var captured: CapturedPlaneAnchor.Geometry {
        CapturedPlaneAnchor.Geometry(extent: extent.captured, mesh: self)
    }
}

public protocol PlaneAnchorGeometryExtentRepresentable {
    var anchorFromExtentTransform: simd_float4x4 { get }
    var width: Float { get }
    var height: Float { get }
}

extension PlaneAnchor.Geometry.Extent: PlaneAnchorGeometryExtentRepresentable {}

extension PlaneAnchorGeometryExtentRepresentable {
    var captured: CapturedPlaneAnchor.Geometry.Extent {
        CapturedPlaneAnchor.Geometry.Extent(anchorFromExtentTransform: anchorFromExtentTransform, width: width, height: height)
    }
}
#endif
