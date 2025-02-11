//
//  CapturedObjectAnchor+Codable.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/10/25.
//

#if canImport(ARKit)
import ARKit
#endif
import Foundation
import RealityKit

extension CapturedObjectAnchor: Codable {
    enum CodingKeys: String, CodingKey {
        case VERSION
        case id
        case originFromAnchorTransform
        case isTracked
        case timestamp
        case referenceObjectName
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(1, forKey: .VERSION)
        try container.encode(originFromAnchorTransform, forKey: .originFromAnchorTransform)
        try container.encode(isTracked, forKey: .isTracked)
        try container.encode(referenceObjectName, forKey: .referenceObjectName)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let originFromAnchorTransform = try container.decode(simd_float4x4.self, forKey: .originFromAnchorTransform)
        let isTracked = try container.decode(Bool.self, forKey: .isTracked)
        let referenceObjectName = try container.decode(String.self, forKey: .referenceObjectName)
        let timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
        self.init(id: id, originFromAnchorTransform: originFromAnchorTransform, referenceObjectName: referenceObjectName, isTracked: isTracked, timestamp: timestamp)
    }
}
