//
//  CapturedMeshAnchor.swift
//
//
//  Created by John Haney on 4/13/24.
//

import ARKit

public protocol MeshAnchorRepresentable: CapturableAnchor {
    associatedtype Geometry: MeshAnchorGeometryRepresentable
    var geometry: Geometry { get }
    var originFromAnchorTransform: simd_float4x4 { get }
    var id: UUID { get }
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
        public var vertices: GeometrySource
        public var normals: GeometrySource
        public var faces: GeometryElement
        public var classifications: GeometrySource?
        
        init(vertices: GeometrySource, normals: GeometrySource, faces: GeometryElement, classifications: GeometrySource? = nil) {
            self.vertices = vertices
            self.normals = normals
            self.faces = faces
            self.classifications = classifications
        }
    }
}

extension MeshAnchorRepresentable {
    public var captured: CapturedMeshAnchor {
        CapturedMeshAnchor(id: id, originFromAnchorTransform: originFromAnchorTransform, geometry: geometry.captured)
    }
}

public protocol MeshAnchorGeometryRepresentable {
    var vertices: GeometrySource { get }
    var normals: GeometrySource { get }
    var faces: GeometryElement { get }
    var classifications: GeometrySource? { get }
}

extension MeshAnchor.Geometry: MeshAnchorGeometryRepresentable {}

extension MeshAnchorGeometryRepresentable {
    var captured: CapturedMeshAnchor.Geometry {
        CapturedMeshAnchor.Geometry(vertices: vertices, normals: normals, faces: faces, classifications: classifications)
    }
}

