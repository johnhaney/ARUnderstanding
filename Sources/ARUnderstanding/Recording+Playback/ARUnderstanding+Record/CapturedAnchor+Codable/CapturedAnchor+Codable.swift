//
//  CapturedAnchor+Codable.swift
//  HandCapture
//
//  Created by John Haney on 4/29/24.
//

import Foundation
import ARUnderstanding

extension CapturedAnchor: Codable {
    enum CodingKeys: String, CodingKey {
        case VERSION
        case type
        case update
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(1, forKey: .VERSION)
        switch self {
        case .hand(let capturedAnchorUpdate):
            try container.encode("hand", forKey: .type)
            try container.encode(capturedAnchorUpdate, forKey: .update)
        case .mesh(let capturedAnchorUpdate):
            try container.encode("mesh", forKey: .type)
            try container.encode(capturedAnchorUpdate, forKey: .update)
        case .plane(let capturedAnchorUpdate):
            try container.encode("plane", forKey: .type)
            try container.encode(capturedAnchorUpdate, forKey: .update)
        case .image(let capturedAnchorUpdate):
            try container.encode("image", forKey: .type)
            try container.encode(capturedAnchorUpdate, forKey: .update)
        case .world(let capturedAnchorUpdate):
            try container.encode("world", forKey: .type)
            try container.encode(capturedAnchorUpdate, forKey: .update)
        case .device(let capturedAnchorUpdate):
            try container.encode("device", forKey: .type)
            try container.encode(capturedAnchorUpdate, forKey: .update)
        case .room(let capturedAnchorUpdate):
            try container.encode("room", forKey: .type)
            try container.encode(capturedAnchorUpdate, forKey: .update)
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "hand":
            let update = try container.decode(CapturedAnchorUpdate<CapturedHandAnchor>.self, forKey: .update)
            self = .hand(update)
        case "mesh":
            let update = try container.decode(CapturedAnchorUpdate<CapturedMeshAnchor>.self, forKey: .update)
            self = .mesh(update)
        case "plane":
            let update = try container.decode(CapturedAnchorUpdate<CapturedPlaneAnchor>.self, forKey: .update)
            self = .plane(update)
        case "image":
            let update = try container.decode(CapturedAnchorUpdate<CapturedImageAnchor>.self, forKey: .update)
            self = .image(update)
        case "world":
            let update = try container.decode(CapturedAnchorUpdate<CapturedWorldAnchor>.self, forKey: .update)
            self = .world(update)
        case "device":
            let update = try container.decode(CapturedAnchorUpdate<CapturedDeviceAnchor>.self, forKey: .update)
            self = .device(update)
        case "room":
            let update = try container.decode(CapturedAnchorUpdate<CapturedRoomAnchor>.self, forKey: .update)
            self = .room(update)
        default:
            throw Error.decodingError
        }

        enum Error: Swift.Error {
            case decodingError
        }
    }
}

extension CapturedAnchorUpdate: Codable where AnchorType: Codable {
    enum CodingKeys: String, CodingKey {
        case VERSION
        case anchor
        case timestamp
        case event
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(1, forKey: .VERSION)
        try container.encode(self.anchor, forKey: .anchor)
        try container.encode(self.timestamp, forKey: .timestamp)
        try container.encode(self.event, forKey: .event)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let anchor = try container.decode(AnchorType.self, forKey: .anchor)
        let timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
        let event = try container.decode(CapturedAnchorEvent.self, forKey: .event)
        
        self.init(anchor: anchor, timestamp: timestamp, event: event)
    }
}
