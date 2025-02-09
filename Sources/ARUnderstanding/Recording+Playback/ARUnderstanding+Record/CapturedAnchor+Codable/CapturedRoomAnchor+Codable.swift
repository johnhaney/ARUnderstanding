//
//  CapturedRoomAnchor+Codable.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/8/25.
//

#if canImport(ARKit)
import ARKit
#endif
import Foundation
import RealityKit

extension CapturedRoomAnchor: Codable {
    enum CodingKeys: String, CodingKey {
        case VERSION
        case id
        case originFromAnchorTransform
        case capturedGeometry
        case planeAnchorIDs
        case meshAnchorIDs
        case isCurrentRoom
        case timestamp
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(originFromAnchorTransform, forKey: .originFromAnchorTransform)
        try container.encode(capturedGeometry, forKey: .capturedGeometry)
        try container.encode(planeAnchorIDs, forKey: .planeAnchorIDs)
        try container.encode(meshAnchorIDs, forKey: .meshAnchorIDs)
        try container.encode(isCurrentRoom, forKey: .isCurrentRoom)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let originFromAnchorTransform = try container.decode(simd_float4x4.self, forKey: .originFromAnchorTransform)
        let capturedGeometry = try container.decode(CapturedRoomAnchor.CapturedGeometry.self, forKey: .capturedGeometry)
        let planeAnchorIDs = try container.decode([UUID].self, forKey: .planeAnchorIDs)
        let meshAnchorIDs = try container.decode([UUID].self, forKey: .meshAnchorIDs)
        let isCurrentRoom = try container.decode(Bool.self, forKey: .isCurrentRoom)
        let timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
        self.init(id: id, originFromAnchorTransform: originFromAnchorTransform, capturedGeometry: capturedGeometry, planeAnchorIDs: planeAnchorIDs, meshAnchorIDs: meshAnchorIDs, isCurrentRoom: isCurrentRoom, timestamp: timestamp)
    }
}

extension CapturedRoomAnchor.CapturedGeometry.CapturedRoomGeometrySource: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let capturedRoomGeometry = try container.decode(CapturedRoomGeometry.self)
        self = .captured(capturedRoomGeometry)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .room(let room):
            try container.encode(CapturedRoomGeometry(room))
        case .captured(let capturedRoomGeometry):
            try container.encode(capturedRoomGeometry)
        }
    }
}
