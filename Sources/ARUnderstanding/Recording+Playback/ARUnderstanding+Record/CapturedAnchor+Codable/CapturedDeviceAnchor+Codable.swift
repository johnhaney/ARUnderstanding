//
//  CapturedDeviceAnchor+Codable.swift
//  HandCapture
//
//  Created by John Haney on 4/29/24.
//

#if canImport(ARKit)
import ARKit
#endif
import Foundation
import RealityKit

extension CapturedDeviceAnchor: Codable {
    enum CodingKeys: String, CodingKey {
        case VERSION
        case id
        case originFromAnchorTransform
        case isTracked
        case timestamp
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(1, forKey: .VERSION)
        try container.encode(id, forKey: .id)
        try container.encode(originFromAnchorTransform, forKey: .originFromAnchorTransform)
        try container.encode(isTracked, forKey: .isTracked)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let originFromAnchorTransform = try container.decode(simd_float4x4.self, forKey: .originFromAnchorTransform)
        let isTracked = try container.decode(Bool.self, forKey: .isTracked)
        let timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
        self.init(id: id, originFromAnchorTransform: originFromAnchorTransform, isTracked: isTracked, timestamp: timestamp)
    }
}
