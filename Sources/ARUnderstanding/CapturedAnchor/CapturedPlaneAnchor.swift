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

extension PlaneAnchorRepresentable {
    public var corners: [SIMD3<Float>] {
        let extent = geometry.extent
        let halfWidth = extent.width / 2
        let halfHeight = extent.height / 2

        // Plane-local corners (in extent space)
        let localCorners: [SIMD4<Float>] = [
            SIMD4(-halfWidth, 0, -halfHeight, 1), // bottom-left
            SIMD4( halfWidth, 0, -halfHeight, 1), // bottom-right
            SIMD4( halfWidth, 0,  halfHeight, 1), // top-right
            SIMD4(-halfWidth, 0,  halfHeight, 1)  // top-left
        ]

        // Compose the transform from extent space to world space
        let transform = originFromAnchorTransform * extent.anchorFromExtentTransform

        // Apply the transform and drop to SIMD3
        return localCorners.map { corner in
            let world = transform * corner
            return SIMD3<Float>(world.x, world.y, world.z)
        }
    }
}

public struct CapturedPlaneAnchor: Anchor, PlaneAnchorRepresentable, Sendable {
    public var id: UUID
    public var originFromAnchorTransform: simd_float4x4
    public var geometry: Geometry { _geometry() }
    private var _geometry: @Sendable () -> Geometry
    public var classification: PlaneAnchor.Classification
    public var alignment: PlaneAnchor.Alignment
    public var description: String { "Plane \(originFromAnchorTransform) \(alignment) \(classification) \(geometry)" }
    
    public init<T: PlaneAnchorRepresentable>(captured: T) {
        self.id = captured.id
        self.originFromAnchorTransform = captured.originFromAnchorTransform
        self._geometry = { captured.geometry.captured }
        self.classification = captured.classification
        self.alignment = captured.alignment
    }
    
    public init(id: UUID, originFromAnchorTransform: simd_float4x4, geometry: Geometry, classification: PlaneAnchor.Classification, alignment: PlaneAnchor.Alignment) {
        self.id = id
        self.originFromAnchorTransform = originFromAnchorTransform
        self._geometry = { geometry }
        self.classification = classification
        self.alignment = alignment
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
        
        public init(extent: PlaneAnchorGeometryExtentRepresentable, mesh: CapturedPlaneMeshGeometry) {
            self.extent = Extent(anchorFromExtentTransform: extent.anchorFromExtentTransform, width: extent.width, height: extent.height)
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
        if let captured = self as? CapturedPlaneAnchor {
            captured
        } else {
            CapturedPlaneAnchor(captured: self)
        }
    }
}

public protocol PlaneAnchorGeometryRepresentable {
    associatedtype Extent: PlaneAnchorGeometryExtentRepresentable
    var extent: Extent { get }
    var mesh: CapturedPlaneMeshGeometry { get }
}

extension PlaneAnchorGeometryRepresentable {
    var captured: CapturedPlaneAnchor.Geometry {
        CapturedPlaneAnchor.Geometry(
            extent: extent,
            mesh: mesh
        )
    }
}

public struct CapturedPlaneMeshGeometry: Sendable {
    public var vertices: [SIMD3<Float>]
    public var triangles: [[UInt32]]
    
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

//public struct AnyPlaneAnchorRepresentable: PlaneAnchorRepresentable {
//    init<T: PlaneAnchorRepresentable>(_ anchor: T) {
//        base = anchor
//    }
//    
//    private let base: any PlaneAnchorRepresentable
//    
//    public var originFromAnchorTransform: simd_float4x4 { base.originFromAnchorTransform }
//    public var id: UUID { base.id }
//    public var geometry: AnyPlaneAnchorGeometryRepresentable { base.geometry }
//    public var classification: PlaneAnchor.Classification { base.classification }
//    public var alignment: PlaneAnchor.Alignment { base.alignment }
//    public var description: String { base.description }
//}
//
//extension PlaneAnchorRepresentable {
//    var eraseToAny: AnyPlaneAnchorRepresentable {
//        AnyPlaneAnchorRepresentable(self)
//    }
//}
//
//public struct AnyPlaneAnchorGeometryRepresentable: PlaneAnchorGeometryRepresentable {
//    init<T: PlaneAnchorGeometryRepresentable>(_ anchor: T) {
//        base = anchor
//    }
//    
//    private let base: any PlaneAnchorGeometryRepresentable
//    
////    public var meshVertices: GeometrySource { base.meshVertices }
////    public var meshFaces: GeometryElement { base.meshFaces }
//    public var extent: any PlaneAnchorGeometryExtentRepresentable { base.extent }
//    public var description: String { base.description }
//    public func mesh(name: String) async -> MeshResource? { await base.mesh(name: name) }
//}
//
//extension PlaneAnchorGeometryRepresentable {
//    var eraseToAny: AnyPlaneAnchorGeometryRepresentable {
//        AnyPlaneAnchorGeometryRepresentable(self)
//    }
//}
//
//public struct SavedPlaneAnchor: PlaneAnchorRepresentable, Sendable, Equatable {
//    public var originFromAnchorTransform: simd_float4x4
//    public var id: UUID
//    public var geometry: AnyPlaneAnchorGeometryRepresentable
//    public var classification: PlaneAnchor.Classification
//    public var alignment: PlaneAnchor.Alignment
//    public var description: String { "Plane \(originFromAnchorTransform) \(alignment) \(classification) \(geometry)" }
//}
////
////    public init(id: UUID, originFromAnchorTransform: simd_float4x4, geometry: Geometry, classification: PlaneAnchor.Classification, alignment: PlaneAnchor.Alignment) {
////        self.id = id
////        self.originFromAnchorTransform = originFromAnchorTransform
////        self.geometry = geometry
////        self.classification = classification
////        self.alignment = alignment
////    }
////    
////#if !os(visionOS)
////    public enum Classification: String, Sendable, Hashable, Equatable {
////        case ceiling
////        case door
////        case floor
////        case seat
////        case table
////        case wall
////        case window
////        case notAvailable
////        case undetermined
////        case unknown
////        
////        var description: String { rawValue }
////    }
////    
////    public enum Alignment: String, Sendable, Hashable, Equatable {
////        case horizontal
////        case vertical
////        case slanted
////        
////        var description: String { rawValue }
////    }
////#endif
////    
////    public struct Geometry: PlaneAnchorGeometryRepresentable, Sendable, Equatable {
////        public var extent: Extent
////        public var mesh: SavedPlaneMeshGeometry
////        public var saved: Self { self }
////        
////        public init(extent: Extent, mesh: SavedPlaneMeshGeometry) {
////            self.extent = extent
////            self.mesh = mesh
////        }
////        
////        public struct Extent: PlaneAnchorGeometryExtentRepresentable, Sendable, Equatable {
////            public var anchorFromExtentTransform: simd_float4x4
////            public var width: Float
////            public var height: Float
////            
////            public init(anchorFromExtentTransform: simd_float4x4, width: Float, height: Float) {
////                self.anchorFromExtentTransform = anchorFromExtentTransform
////                self.width = width
////                self.height = height
////            }
////        }
////    }
////}
//
//extension PlaneAnchorRepresentable {
//    public var captured: AnyPlaneAnchorRepresentable { eraseToAny }
//    public var saved: AnyPlaneAnchorRepresentable { eraseToAny }
//}
//
//public protocol PlaneAnchorGeometryRepresentable: Sendable {
//    func mesh(name: String) async -> MeshResource?
//    var extent: any PlaneAnchorGeometryExtentRepresentable { get }
//    var description: String { get }
//}
//
//public protocol PlaneAnchorGeometryExtentRepresentable: Sendable, Equatable {
//    var width: Float { get }
//    var height: Float { get }
//    var anchorFromExtentTransform: simd_float4x4 { get }
//    var description: String { get }
//}
//
//public struct AnyPlaneAnchorGeometryExtentRepresentable: PlaneAnchorGeometryExtentRepresentable, Equatable {
//    public static func == (lhs: AnyPlaneAnchorGeometryExtentRepresentable, rhs: AnyPlaneAnchorGeometryExtentRepresentable) -> Bool {
//        lhs.width == rhs.width &&
//        lhs.height == rhs.height &&
//        lhs.anchorFromExtentTransform == rhs.anchorFromExtentTransform
//    }
//    
//    init<T: PlaneAnchorGeometryExtentRepresentable>(_ anchor: T) {
//        base = anchor
//    }
//    
//    private let base: any PlaneAnchorGeometryExtentRepresentable
//    
//    public var width: Float { base.width }
//    public var height: Float { base.height }
//    public var anchorFromExtentTransform: simd_float4x4 { base.anchorFromExtentTransform }
//    public var description: String { base.description }
//}
//
//extension PlaneAnchorGeometryExtentRepresentable {
//    var eraseToAny: AnyPlaneAnchorGeometryExtentRepresentable {
//        AnyPlaneAnchorGeometryExtentRepresentable(self)
//    }
//}
//
//public struct SavedPlaneMeshGeometryExtent: PlaneAnchorGeometryExtentRepresentable, Sendable, Equatable {
//    public var width: Float
//    public var height: Float
//    public var anchorFromExtentTransform: simd_float4x4
//    public var description: String
//    
//    init(width: Float, height: Float, anchorFromExtentTransform: simd_float4x4, description: String) {
//        self.width = width
//        self.height = height
//        self.anchorFromExtentTransform = anchorFromExtentTransform
//        self.description = description
//    }
//    
//    init(_ extent: PlaneAnchor.Geometry.Extent) {
//        width = extent.width
//        height = extent.height
//        anchorFromExtentTransform = extent.anchorFromExtentTransform
//        description = "SavedPlaneMeshGeometryExtent"
//    }
//}
//
//public struct SavedPlaneMeshGeometry: PlaneAnchorGeometryRepresentable, Sendable, Equatable {
//    public var extent: any PlaneAnchorGeometryExtentRepresentable
//    
//    public static func == (lhs: SavedPlaneMeshGeometry, rhs: SavedPlaneMeshGeometry) -> Bool {
//        lhs.extent.eraseToAny == rhs.extent.eraseToAny &&
//        lhs.triangles == rhs.triangles &&
//        lhs.vertices == rhs.vertices
//    }
//    
//    var vertices: [SIMD3<Float>]
//    var triangles: [[UInt32]]
//    public var description: String { "PlaneMesh Geometry (\(vertices.count),\(triangles.count))" }
//
//    init(vertices: [SIMD3<Float>], triangles: [[UInt32]], extent: any PlaneAnchorGeometryExtentRepresentable) {
//        self.vertices = vertices
//        self.triangles = triangles
//        self.extent = extent.eraseToAny
//    }
//    
//    init(_ geometry: PlaneAnchor.Geometry) {
//        #if !os(visionOS)
//        vertices = geometry.mesh.vertices
//        triangles = geometry.mesh.triangles
//        #else
//        vertices = []
//        triangles = []
//        
//        for index in 0 ..< geometry.meshVertices.count {
//            let vertex = geometry.vertex(at: UInt32(index))
//            let vertexPos = SIMD3<Float>(x: vertex.0, y: vertex.1, z: vertex.2)
//            vertices.append(vertexPos)
//        }
//        
//        for index in 0 ..< geometry.meshFaces.count {
//            let face = geometry.vertexIndicesOf(faceWithIndex: Int(index))
//            triangles.append([face[0],face[1],face[2]])
//        }
//        #endif
//        extent = SavedPlaneMeshGeometryExtent(geometry.extent).eraseToAny
//    }
//    
//    public func mesh(name: String) async -> MeshResource? {
//        var mesh = MeshDescriptor(name: "")
//        let faces = triangles.flatMap({ $0 })
//        let positions = MeshBuffers.Positions(vertices)
//        do {
//            let triangles = MeshDescriptor.Primitives.triangles(faces)
//            mesh.positions = positions
//            mesh.primitives = triangles
//        }
//        
//        do {
//            let resource = try await MeshResource(from: [mesh])
//            return resource
//        } catch {
//            print("Error creating mesh resource: \(error.localizedDescription)")
//            return nil
//        }
//    }
//}
//
//#if os(visionOS)
//extension PlaneAnchor.Geometry {
//    func vertex(at index: UInt32) -> (Float, Float, Float) {
//        assert(meshVertices.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per vertex.")
//        let vertexPointer = meshVertices.buffer.contents().advanced(by: meshVertices.offset + (meshVertices.stride * Int(index)))
//        let vertex = vertexPointer.assumingMemoryBound(to: (Float, Float, Float).self).pointee
//        return vertex
//    }
//    
//    func vertexIndicesOf(faceWithIndex faceIndex: Int) -> [UInt32] {
//        assert(meshFaces.bytesPerIndex == MemoryLayout<UInt32>.size, "Expected one UInt32 (four bytes) per vertex index")
//        let vertexCountPerFace = 3 // assume triangles
//        let vertexIndicesPointer = meshFaces.buffer.contents()
//        var vertexIndices = [UInt32]()
//        vertexIndices.reserveCapacity(vertexCountPerFace)
//        for vertexOffset in 0..<vertexCountPerFace {
//            let vertexIndexPointer = vertexIndicesPointer.advanced(by: (faceIndex * vertexCountPerFace + vertexOffset) * MemoryLayout<UInt32>.size)
//            vertexIndices.append(vertexIndexPointer.assumingMemoryBound(to: UInt32.self).pointee)
//        }
//        return vertexIndices
//    }
//}
//#endif
