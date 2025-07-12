//
//  CapturedMeshAnchor.swift
//
//
//  Created by John Haney on 4/13/24.
//

import Foundation
#if os(visionOS)
import ARKit
#endif
#if canImport(RealityKit)
import RealityKit
#endif
import simd

public protocol MeshAnchorRepresentable: CapturableAnchor {
    associatedtype Geometry: MeshAnchorGeometryRepresentable
    var geometry: Geometry { get }
    var originFromAnchorTransform: simd_float4x4 { get }
    var id: UUID { get }
}

@available(visionOS, introduced: 2.0)
@available(iOS, introduced: 18.0)
@available(tvOS, introduced: 26.0)
@available(macOS, introduced: 15.0)
@available(watchOS, unavailable)
public protocol MeshAnchorRKRepresentable: MeshAnchorRepresentable {
    #if os(visionOS) || os(iOS) || os(macOS) || os(tvOS)
    func shape() async throws -> ShapeResource
    #endif
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
    public var base: any MeshAnchorRepresentable
    public var originFromAnchorTransform: simd_float4x4
    public var geometry: Geometry { _geometry() }
    private var _geometry: @Sendable () -> Geometry
    public var description: String { "Mesh \(originFromAnchorTransform) \(geometry)" }
    
    public init<T: MeshAnchorRepresentable>(captured: T) {
        self.base = captured
        self.id = captured.id
        self.originFromAnchorTransform = captured.originFromAnchorTransform
        self._geometry = { captured.geometry.captured }
    }

    public enum MeshClassification: Int {
        case none = 0
        case wall = 1
        case floor = 2
        case ceiling = 3
        case table = 4
        case seat = 5
        case window = 6
        case door = 7
        case stairs = 8
        case bed = 9
        case cabinet = 10
        case homeAppliance = 11
        case tv = 12
        case plant = 13
    }
    
    public struct Geometry: MeshAnchorGeometryRepresentable, Sendable {
        public var mesh: CapturedMeshGeometry {
            meshSource.mesh
        }
        public var classifications: [UInt8]? {
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
                case .captured(let capturedMeshGeometry):
                    capturedMeshGeometry
#if os(visionOS)
                case .mesh(let geometry):
                    CapturedMeshGeometry(geometry)
#endif
                }
            }
            
            var classifications: [UInt8]? {
                switch self {
                case .captured(let capturedPlaneMeshGeometry):
                    return capturedPlaneMeshGeometry.classifications
#if os(visionOS)
                case .mesh(let geometry):
                    let classifications: [UInt8]?
                    if let geometryClassifications = geometry.classifications {
                        classifications = (0 ..< geometryClassifications.count).map { index in
                            geometry.classification(at: index) ?? UInt8.max
                        }
                    } else {
                        classifications = nil
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
}

@available(visionOS, introduced: 2.0)
@available(iOS, introduced: 18.0)
@available(tvOS, introduced: 26.0)
@available(macOS, introduced: 15.0)
@available(watchOS, unavailable)
extension CapturedMeshAnchor: MeshAnchorRKRepresentable {
    #if os(visionOS) || os(iOS) || os(macOS) || os(tvOS)
    public func shape() async throws -> ShapeResource {
        try await geometry.mesh.shape()
    }
    #endif
}

public struct SavedMeshAnchor: Anchor, MeshAnchorRepresentable, Sendable {
    public var id: UUID
    public var originFromAnchorTransform: simd_float4x4
    public var geometry: CapturedMeshAnchor.Geometry { _geometry() }
    public var description: String { _description() }
    private var _geometry: @Sendable () -> CapturedMeshAnchor.Geometry
    private let _description: @Sendable () -> String
    
    public init(id: UUID, originFromAnchorTransform: simd_float4x4, geometry: Geometry, description: String) {
        self.id = id
        self.originFromAnchorTransform = originFromAnchorTransform
        self._geometry = { geometry }
        self._description = { description }
    }
}

@available(visionOS, introduced: 2.0)
@available(iOS, introduced: 18.0)
@available(tvOS, introduced: 26.0)
@available(macOS, introduced: 15.0)
@available(watchOS, unavailable)
extension SavedMeshAnchor: MeshAnchorRKRepresentable {
    #if os(visionOS) || os(iOS) || os(macOS) || os(tvOS)
    public func shape() async throws -> ShapeResource {
        try await geometry.mesh.shape()
    }
    #endif
}

#if os(visionOS) || os(iOS) || os(macOS) || os(tvOS)
@available(visionOS, introduced: 2.0)
@available(iOS, introduced: 18.0)
@available(tvOS, introduced: 26.0)
@available(macOS, introduced: 15.0)
@available(watchOS, unavailable)
extension ShapeResource {
    static func generateStaticMesh(from: any MeshAnchorRKRepresentable) async throws -> ShapeResource {
        return try await from.shape()
    }
}
#endif

public struct CapturedMeshGeometry: Sendable {
    let vertices: [SIMD3<Float>]
    let normals: [SIMD3<Float>]
    let triangles: [[UInt32]]
    let classifications: [UInt8]?
        
    public init(vertices: [SIMD3<Float>], normals: [SIMD3<Float>], triangles: [[UInt32]], classifications: [UInt8]?) {
        self.vertices = vertices
        self.normals = normals
        self.triangles = triangles
        self.classifications = classifications
    }
    
    #if os(visionOS)
    init(_ geometry: any MeshAnchorGeometryRepresentable) {
        self = geometry.mesh
    }
    
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
                geometry.classification(at: index) ?? UInt8.max
            }
        } else {
            classifications = []
        }
    }
    #endif
    
    #if os(visionOS) || os(iOS) || os(macOS) || os(tvOS)
    @available(visionOS, introduced: 2.0)
    @available(iOS, introduced: 18.0)
    @available(tvOS, introduced: 26.0)
    @available(macOS, introduced: 15.0)
    @available(watchOS, unavailable)
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
    #endif

    #if os(visionOS) || os(iOS) || os(macOS) || os(tvOS)
    @available(visionOS, introduced: 2.0)
    @available(iOS, introduced: 18.0)
    @available(tvOS, introduced: 26.0)
    @available(macOS, introduced: 15.0)
    @available(watchOS, unavailable)
    func shape() async throws -> ShapeResource {
        try await ShapeResource.generateStaticMesh(
            positions: vertices,
            faceIndices: triangles.flatMap({ $0 }).map(UInt16.init)
        )
    }
    #endif
}

extension MeshAnchorRepresentable {
    public var captured: CapturedMeshAnchor {
        if let captured = self as? CapturedMeshAnchor {
            captured
        } else {
            CapturedMeshAnchor(captured: self)
        }
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

//public protocol MeshAnchorRepresentable: CapturableAnchor, Sendable {
//    var geometry: AnyMeshAnchorGeometryRepresentable { get }
//    var originFromAnchorTransform: simd_float4x4 { get }
//    var id: UUID { get }
//    func shape() async throws -> ShapeResource
//}
//
//extension MeshAnchorRepresentable {
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
//    
//    public static func == (lhs: Self, rhs: Self) -> Bool {
//        lhs.id == rhs.id
//    }
//    
////    public func mesh(name: String) async -> MeshResource? {
////        await geometry.mesh(name: name)
////    }
//}
//
//public struct AnyMeshAnchorRepresentable: MeshAnchorRepresentable {
//    private let _originFromAnchorTransform: @Sendable () -> simd_float4x4
//    private let _id: @Sendable () -> UUID
//    private let _geometry: @Sendable () -> AnyMeshAnchorGeometryRepresentable
//    private let _shape: @Sendable () async throws -> ShapeResource
//    private let _description: @Sendable () -> String
//
//    public init<T: MeshAnchorRepresentable>(_ base: T) {
//        _originFromAnchorTransform = { base.originFromAnchorTransform }
//        _id = { base.id }
//        _shape = { try await base.shape() }
//        _geometry = { base.geometry.eraseToAny }
//        _description = { base.description }
//    }
//
//    public var originFromAnchorTransform: simd_float4x4 { _originFromAnchorTransform() }
//    public var id: UUID { _id() }
//    public func shape() async throws -> ShapeResource { try await _shape() }
//    public var geometry: AnyMeshAnchorGeometryRepresentable { _geometry() }
//    public var description: String { _description() }
//}
//
//extension MeshAnchorRepresentable {
//    var eraseToAny: AnyMeshAnchorRepresentable {
//        AnyMeshAnchorRepresentable(self)
//    }
//}
//
//public enum CapturedMeshAnchor: Anchor, Sendable, Equatable, Hashable, Identifiable {
//    case live(MeshAnchor)
//    case saved(SavedMeshAnchor)
//    
//    public var anchor: any MeshAnchorRepresentable {
//        switch self {
//        case .live(let meshAnchor):
//            meshAnchor
//        case .saved(let savedMeshAnchor):
//            savedMeshAnchor
//        }
//    }
//    public var originFromAnchorTransform: simd_float4x4 { anchor.originFromAnchorTransform }
//    public var description: String { anchor.description }
//    public var id: UUID { anchor.id }
//}
//
//public struct SavedMeshAnchor: Anchor, MeshAnchorRepresentable, Sendable, Equatable {
//    public func shape() async throws -> ShapeResource {
//        #warning("TODO: make shape from geometry")
//        return await ShapeResource.generateBox(size: .one)
//    }
//    
//    public var id: UUID
//    public var originFromAnchorTransform: simd_float4x4
//    public var geometry: AnyMeshAnchorGeometryRepresentable
//    public var description: String { "Mesh \(originFromAnchorTransform) \(geometry)" }
//
//    public init(id: UUID, originFromAnchorTransform: simd_float4x4, geometry: any MeshAnchorGeometryRepresentable) {
//        self.id = id
//        self.originFromAnchorTransform = originFromAnchorTransform
//        self.geometry = geometry.eraseToAny
//    }
//    
//    public enum MeshClassification: Int, CaseIterable, Equatable {
//        case none = 0
//        case wall = 1
//        case floor = 2
//        case ceiling = 3
//        case table = 4
//        case seat = 5
//        case window = 6
//        case door = 7
//        case stairs = 8
//        case bed = 9
//        case cabinet = 10
//        case homeAppliance = 11
//        case tv = 12
//        case plant = 13
//    }
//    
////    public struct Geometry: MeshAnchorGeometryRepresentable, Sendable, Equatable {
////        public var mesh: SavedMeshGeometry {
////            meshSource.mesh
////        }
////        public var classifications: [UInt8]? {
////            meshSource.classifications
////        }
////        private var meshSource: SavedMeshGeometrySource
////        
////        public var saved: SavedMeshAnchor.Geometry { self }
////        
////        enum SavedMeshGeometrySource : Sendable, Equatable {
////            case saved(SavedMeshGeometry)
////#if os(visionOS)
////            case mesh(MeshAnchor.Geometry)
////#endif
////            var mesh: SavedMeshGeometry {
////                switch self {
////                case .saved(let savedMeshGeometry):
////                    savedMeshGeometry
////#if os(visionOS)
////                case .mesh(let geometry):
////                    SavedMeshGeometry(geometry)
////#endif
////                }
////            }
////            
////            var classifications: [UInt8]? {
////                switch self {
////                case .saved(let savedPlaneMeshGeometry):
////                    return savedPlaneMeshGeometry.classifications
////#if os(visionOS)
////                case .mesh(let geometry):
////                    let classifications: [UInt8]?
////                    if let geometryClassifications = geometry.classifications {
////                        classifications = (0 ..< geometryClassifications.count).map { index in
////                            geometry.classification(at: index) ?? UInt8.max
////                        }
////                    } else {
////                        classifications = nil
////                    }
////                    return classifications
////#endif
////                }
////            }
////        }
////
////        public init(mesh: SavedMeshGeometry) {
////            self.meshSource = .saved(mesh)
////        }
////
////#if os(visionOS)
////        public init(mesh: MeshAnchor.Geometry) {
////            self.meshSource = .mesh(mesh)
////        }
////#endif
////    }
//    
////    public func shape() async throws -> ShapeResource {
////        try await geometry.mesh.shape()
////    }
//}
//
//extension ShapeResource {
//    static func generateStaticMesh(from: any MeshAnchorRepresentable) async throws -> ShapeResource {
//        return try await from.shape()
//    }
//}
//
////public struct SavedMeshGeometry: Sendable, Equatable {
////    public let vertices: [SIMD3<Float>]
////    public let normals: [SIMD3<Float>]
////    public let triangles: [[UInt32]]
////    public let classifications: [UInt8]?
////        
////    public init(vertices: [SIMD3<Float>], normals: [SIMD3<Float>], triangles: [[UInt32]], classifications: [UInt8]?) {
////        self.vertices = vertices
////        self.normals = normals
////        self.triangles = triangles
////        self.classifications = classifications
////    }
////    
////    #if os(visionOS)
////    init(_ geometry: any MeshAnchorGeometryRepresentable) {
////        self = geometry.mesh
////    }
////    
////    init(_ geometry: MeshAnchor.Geometry) {
////        vertices = (0..<UInt32(geometry.vertices.count)).map { index in
////            let vertex = geometry.vertex(at: index)
////            return SIMD3<Float>(x: vertex.0, y: vertex.1, z: vertex.2)
////        }
////        
////        triangles = (0 ..< geometry.faces.count).map { index in
////            let face = geometry.vertexIndicesOf(faceWithIndex: index)
////            return [face[0],face[1],face[2]]
////        }
////        
////        normals = (0 ..< UInt32(geometry.normals.count)).map { index in
////            let normal = geometry.normalsOf(at: index)
////            return SIMD3<Float>(normal.0, normal.1, normal.2)
////        }
////        
////        if let geometryClassifications = geometry.classifications {
////            classifications = (0 ..< geometryClassifications.count).map { index in
////                geometry.classification(at: index) ?? UInt8.max
////            }
////        } else {
////            classifications = []
////        }
////    }
////    #endif
////    
////    func mesh(name: String) async -> MeshResource? {
////        var mesh = MeshDescriptor(name: name)
////        let faces = triangles.flatMap({ $0 })
////        let positions = MeshBuffers.Positions(vertices)
////        do {
////            let triangles = MeshDescriptor.Primitives.triangles(faces)
////            let normals = MeshBuffers.Normals(normals)
////
////            mesh.positions = positions
////            mesh.primitives = triangles
////            mesh.normals = normals
////        }
////        
////        do {
////            let resource = try await MeshResource(from: [mesh])
////            return resource
////        } catch {
////            print("Error creating mesh resource: \(error.localizedDescription)")
////            return nil
////        }
////    }
////    
////    func shape() async throws -> ShapeResource {
////        try await ShapeResource.generateStaticMesh(
////            positions: vertices,
////            faceIndices: triangles.flatMap({ $0 }).map(UInt16.init)
////        )
////    }
////}
//
//extension MeshAnchorRepresentable {
//    public var captured: AnyMeshAnchorRepresentable { eraseToAny }
//    public var saved: AnyMeshAnchorRepresentable { eraseToAny }
//}
//
//public protocol MeshAnchorGeometryRepresentable: Sendable {
//    var verticesArray: [SIMD3<Float>] { get }
//    var normalsArray: [SIMD3<Float>] { get }
//    var facesArray: [SIMD3<Float>] { get }
//    var classificationsArray: [UInt8]? { get }
//    var description: String { get }
//}
//
//extension MeshAnchorGeometryRepresentable {
//    public func mesh(name: String) async -> MeshResource? {
//        var mesh = MeshDescriptor(name: name)
//        let faces = verticesArray.flatMap({ [UInt32($0.x), UInt32($0.y), UInt32($0.z)] })
//        let positions = MeshBuffers.Positions(verticesArray)
//        do {
//            let triangles = MeshDescriptor.Primitives.triangles(faces)
//            let normals = MeshBuffers.Normals(normalsArray)
//
//            mesh.positions = positions
//            mesh.primitives = triangles
//            mesh.normals = normals
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
//public struct AnyMeshAnchorGeometryRepresentable: MeshAnchorGeometryRepresentable {
//    private let _verticesArray: @Sendable () -> [SIMD3<Float>]
//    private let _normalsArray: @Sendable () -> [SIMD3<Float>]
//    private let _facesArray: @Sendable () -> [SIMD3<Float>]
//    private let _classificationsArray: @Sendable () -> [UInt8]?
//    private let _description: @Sendable () -> String
//
//    public init<T: MeshAnchorGeometryRepresentable>(_ base: T) {
//        _verticesArray = { base.verticesArray }
//        _normalsArray = { base.normalsArray }
//        _facesArray = { base.facesArray }
//        _classificationsArray = { base.classificationsArray }
//        _description = { base.description }
//    }
//    
//    public var verticesArray: [SIMD3<Float>] { _verticesArray() }
//    public var normalsArray: [SIMD3<Float>] { _normalsArray() }
//    public var facesArray: [SIMD3<Float>] { _facesArray() }
//    public var classificationsArray: [UInt8]? { _classificationsArray() }
//    public var description: String { _description() }
//}
//
//struct SavedMeshAnchorGeometry: MeshAnchorGeometryRepresentable {
//    public var verticesArray: [SIMD3<Float>]
//    public var normalsArray: [SIMD3<Float>]
//    public var facesArray: [SIMD3<Float>]
//    public var classificationsArray: [UInt8]?
//    public var description: String { "MeshAnchor \(verticesArray.count),\(normalsArray.count),\(facesArray.count)" }
//    
//    init(vertices: [SIMD3<Float>], normals: [SIMD3<Float>], faces: [SIMD3<Float>], classifications: [UInt8]? = nil) {
//        self.verticesArray = vertices
//        self.normalsArray = normals
//        self.facesArray = faces
//        self.classificationsArray = classifications
//    }
//}
//
//extension MeshAnchorGeometryRepresentable {
//    var eraseToAny: AnyMeshAnchorGeometryRepresentable {
//        AnyMeshAnchorGeometryRepresentable(self)
//    }
//}
//
//extension MeshAnchorGeometryRepresentable {
//    var saved: AnyMeshAnchorGeometryRepresentable { eraseToAny }
//}
//
//
//#if os(visionOS)
//extension MeshAnchor.Geometry: Sendable, Equatable {
//    func classification(at index: Int) -> UInt8? {
//        guard let classifications else { return nil }
//        assert(classifications.format == MTLVertexFormat.uchar, "Expected unsigned int per classification.")
//        let classificationPointer = classifications.buffer.contents().advanced(by: classifications.offset + (classifications.stride * index))
//        let classification = classificationPointer.assumingMemoryBound(to: UInt8.self).pointee
//        return classification
//    }
//    
//    func vertex(at index: UInt32) -> (Float, Float, Float) {
//        assert(vertices.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per vertex.")
//        let vertexPointer = vertices.buffer.contents().advanced(by: vertices.offset + (vertices.stride * Int(index)))
//        let vertex = vertexPointer.assumingMemoryBound(to: (Float, Float, Float).self).pointee
//        return vertex
//    }
//    
//    func vertexIndicesOf(faceWithIndex faceIndex: Int) -> [UInt32] {
//        assert(faces.bytesPerIndex == MemoryLayout<UInt32>.size, "Expected one UInt32 (four bytes) per vertex index")
//        let vertexCountPerFace = 3 // assume triangles
//        let vertexIndicesPointer = faces.buffer.contents()
//        var vertexIndices = [UInt32]()
//        vertexIndices.reserveCapacity(vertexCountPerFace)
//        for vertexOffset in 0..<vertexCountPerFace {
//            let vertexIndexPointer = vertexIndicesPointer.advanced(by: (faceIndex * vertexCountPerFace + vertexOffset) * MemoryLayout<UInt32>.size)
//            vertexIndices.append(vertexIndexPointer.assumingMemoryBound(to: UInt32.self).pointee)
//        }
//        return vertexIndices
//    }
//    
//    func verticesOf(faceWithIndex index: Int) -> [(Float, Float, Float)] {
//        let vertexIndices = vertexIndicesOf(faceWithIndex: index)
//        let vertices = vertexIndices.map { vertex(at: $0) }
//        return vertices
//    }
//    
//    func centerOf(faceWithIndex index: Int) -> (Float, Float, Float) {
//        let vertices = verticesOf(faceWithIndex: index)
//        let sum = vertices.reduce((0, 0, 0)) { ($0.0 + $1.0, $0.1 + $1.1, $0.2 + $1.2) }
//        let geometricCenter = (sum.0 / 3, sum.1 / 3, sum.2 / 3)
//        return geometricCenter
//    }
//    
//    func normalsOf(at index: UInt32) -> (Float, Float, Float) {
//        assert(normals.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per vertex.")
//        
//        let normalPointer = normals.buffer.contents().advanced(by: normals.offset + (normals.stride * Int(index)))
//        
//        let normal = normalPointer.assumingMemoryBound(to: (Float, Float, Float).self).pointee
//        return normal
//    }
//}
//#endif
