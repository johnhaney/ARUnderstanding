//
//  CapturedPlaneAnchor.swift
//
//
//  Created by John Haney on 4/13/24.
//

import ARKit

public protocol PlaneAnchorRepresentable: CapturableAnchor {
    associatedtype Geometry: PlaneAnchorGeometryRepresentable
    var originFromAnchorTransform: simd_float4x4 { get }
    var id: UUID { get }
    var geometry: Geometry { get }
    var classification: PlaneAnchor.Classification { get }
    var alignment: PlaneAnchor.Alignment { get }
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
        public var meshFaces: GeometryElement
        public var meshVertices: GeometrySource
        
        public init(extent: Extent, meshFaces: GeometryElement, meshVertices: GeometrySource) {
            self.extent = extent
            self.meshFaces = meshFaces
            self.meshVertices = meshVertices
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
    var meshFaces: GeometryElement { get }
    var meshVertices: GeometrySource { get }
}

extension PlaneAnchor.Geometry: PlaneAnchorGeometryRepresentable {}

extension PlaneAnchorGeometryRepresentable {
    var captured: CapturedPlaneAnchor.Geometry {
        CapturedPlaneAnchor.Geometry(extent: extent.captured, meshFaces: meshFaces, meshVertices: meshVertices)
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
