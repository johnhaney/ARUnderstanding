//
//  CapturedPlaneAnchor+Codable.swift
//  HandCapture
//
//  Created by John Haney on 4/29/24.
//

import ARUnderstanding
#if canImport(ARKit)
import ARKit
#endif
import Foundation
import RealityKit

extension CapturedPlaneAnchor: Codable {
    enum CodingKeys: String, CodingKey {
        case VERSION
        case id
        case originFromAnchorTransform
        case geometry
        case classification
        case alignment
        case timestamp
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(1, forKey: .VERSION)
        try container.encode(id, forKey: .id)
        try container.encode(originFromAnchorTransform, forKey: .originFromAnchorTransform)
        try container.encode(geometry, forKey: .geometry)
        try container.encode(classification, forKey: .classification)
        try container.encode(alignment, forKey: .alignment)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let originFromAnchorTransform = try container.decode(simd_float4x4.self, forKey: .originFromAnchorTransform)
        let geometry = try container.decode(CapturedPlaneAnchor.Geometry.self, forKey: .geometry)
        let classification = try container.decode(PlaneAnchor.Classification.self, forKey: .classification)
        let alignment = try container.decode(PlaneAnchor.Alignment.self, forKey: .alignment)
        let timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
        self.init(id: id, originFromAnchorTransform: originFromAnchorTransform, geometry: geometry, classification: classification, alignment: alignment, timestamp: timestamp)
    }
}

extension CapturedPlaneAnchor.Geometry: Codable {
    enum CodingKeys: String, CodingKey {
        case extent
        case mesh
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(extent, forKey: .extent)
        try container.encode(mesh, forKey: .mesh)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let extent = try container.decode(Extent.self, forKey: .extent)
        let mesh = try container.decode(CapturedPlaneMeshGeometry.self, forKey: .mesh)
        self.init(extent: extent, mesh: mesh)
    }
}

extension PlaneAnchor.Classification: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        switch description {
        case PlaneAnchor.Classification.notAvailable.description:
            self = .notAvailable
        case PlaneAnchor.Classification.undetermined.description:
            self = .undetermined
        case PlaneAnchor.Classification.unknown.description:
            self = .unknown
        case PlaneAnchor.Classification.wall.description:
            self = .wall
        case PlaneAnchor.Classification.floor.description:
            self = .floor
        case PlaneAnchor.Classification.ceiling.description:
            self = .ceiling
        case PlaneAnchor.Classification.table.description:
            self = .table
        case PlaneAnchor.Classification.seat.description:
            self = .seat
        case PlaneAnchor.Classification.window.description:
            self = .window
        case PlaneAnchor.Classification.door.description:
            self = .door
        default:
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown classification type")
        }
    }

}

extension PlaneAnchor.Alignment: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        switch description {
        case PlaneAnchor.Alignment.horizontal.description:
            self = .horizontal
        case PlaneAnchor.Alignment.vertical.description:
            self = .vertical
        default:
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized alignment")
        }
    }
}

extension CapturedPlaneAnchor.Geometry.Extent: Codable {
    enum CodingKeys: String, CodingKey {
        case anchorFromExtentTransform
        case height
        case width
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(anchorFromExtentTransform, forKey: .anchorFromExtentTransform)
        try container.encode(height, forKey: .height)
        try container.encode(width, forKey: .width)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let anchorFromExtentTransform = try container.decode(simd_float4x4.self, forKey: .anchorFromExtentTransform)
        let width = try container.decode(Float.self, forKey: .width)
        let height = try container.decode(Float.self, forKey: .height)
        self.init(anchorFromExtentTransform: anchorFromExtentTransform, width: width, height: height)
    }
}
