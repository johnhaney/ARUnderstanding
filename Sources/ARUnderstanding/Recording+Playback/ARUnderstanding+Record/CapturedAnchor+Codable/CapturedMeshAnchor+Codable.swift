//
//  CapturedMeshAnchor+Codable.swift
//  HandCapture
//
//  Created by John Haney on 4/29/24.
//

#if canImport(ARKit)
import ARKit
#endif
import Foundation
import RealityKit

extension CapturedMeshAnchor: Codable {
    enum CodingKeys: String, CodingKey {
        case VERSION
        case id
        case originFromAnchorTransform
        case geometry
        case timestamp
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(originFromAnchorTransform, forKey: .originFromAnchorTransform)
        try container.encode(geometry, forKey: .geometry)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let originFromAnchorTransform = try container.decode(simd_float4x4.self, forKey: .originFromAnchorTransform)
        let geometry = try container.decode(CapturedMeshAnchor.Geometry.self, forKey: .geometry)
        let timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
        self.init(id: id, originFromAnchorTransform: originFromAnchorTransform, geometry: geometry, timestamp: timestamp)
    }
}

extension CapturedMeshAnchor.Geometry: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.mesh)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let mesh = try container.decode(CapturedMeshGeometry.self)
        self.init(mesh: mesh)
    }
}
