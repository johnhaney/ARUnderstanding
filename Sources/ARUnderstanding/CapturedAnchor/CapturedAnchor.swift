//
//  CapturedAnchor.swift
//
//
//  Created by John Haney on 4/7/24.
//

import Foundation
#if canImport(ARKit)
import ARKit
#endif
import RealityKit

public protocol CapturableAnchor: Anchor, Hashable {
    associatedtype CapturedType: Anchor & Hashable
    var captured: CapturedType { get }
}

public enum CapturedAnchor: Sendable, Hashable {
    case hand(CapturedAnchorUpdate<CapturedHandAnchor>)
    case mesh(CapturedAnchorUpdate<CapturedMeshAnchor>)
    case plane(CapturedAnchorUpdate<CapturedPlaneAnchor>)
    case image(CapturedAnchorUpdate<CapturedImageAnchor>)
    case world(CapturedAnchorUpdate<CapturedWorldAnchor>)
    case device(CapturedAnchorUpdate<CapturedDeviceAnchor>)
    case room(CapturedAnchorUpdate<CapturedRoomAnchor>)
    case object(CapturedAnchorUpdate<CapturedObjectAnchor>)
}

public struct CapturedAnchorUpdate<AnchorType: Hashable & Identifiable>: Sendable, Hashable where AnchorType: Anchor {
    public let anchor: AnchorType
    public let timestamp: TimeInterval
    public let event: CapturedAnchorEvent
    
    public init(anchor: AnchorType, timestamp: TimeInterval, event: CapturedAnchorEvent) {
        self.anchor = anchor
        self.timestamp = timestamp
        self.event = event
    }
}

public enum CapturedAnchorEvent: String, Codable, Sendable, Hashable {
    case added
    case updated
    case removed
}

extension CapturedAnchor {
    public var id: UUID {
        switch self {
        case .hand(let capturedAnchorUpdate):
            capturedAnchorUpdate.anchor.id
        case .mesh(let capturedAnchorUpdate):
            capturedAnchorUpdate.anchor.id
        case .plane(let capturedAnchorUpdate):
            capturedAnchorUpdate.anchor.id
        case .image(let capturedAnchorUpdate):
            capturedAnchorUpdate.anchor.id
        case .object(let capturedAnchorUpdate):
            capturedAnchorUpdate.anchor.id
        case .world(let capturedAnchorUpdate):
            capturedAnchorUpdate.anchor.id
        case .device(let capturedAnchorUpdate):
            capturedAnchorUpdate.anchor.id
        case .room(let capturedAnchorUpdate):
            capturedAnchorUpdate.anchor.id
        }
    }
    
    public var timestamp: TimeInterval {
        switch self {
        case .hand(let capturedAnchorUpdate):
            capturedAnchorUpdate.timestamp
        case .mesh(let capturedAnchorUpdate):
            capturedAnchorUpdate.timestamp
        case .plane(let capturedAnchorUpdate):
            capturedAnchorUpdate.timestamp
        case .image(let capturedAnchorUpdate):
            capturedAnchorUpdate.timestamp
        case .object(let capturedAnchorUpdate):
            capturedAnchorUpdate.timestamp
        case .world(let capturedAnchorUpdate):
            capturedAnchorUpdate.timestamp
        case .device(let capturedAnchorUpdate):
            capturedAnchorUpdate.timestamp
        case .room(let capturedAnchorUpdate):
            capturedAnchorUpdate.timestamp
        }
    }
    
    public var event: CapturedAnchorEvent {
        switch self {
        case .hand(let capturedAnchorUpdate):
            capturedAnchorUpdate.event
        case .mesh(let capturedAnchorUpdate):
            capturedAnchorUpdate.event
        case .plane(let capturedAnchorUpdate):
            capturedAnchorUpdate.event
        case .image(let capturedAnchorUpdate):
            capturedAnchorUpdate.event
        case .object(let capturedAnchorUpdate):
            capturedAnchorUpdate.event
        case .world(let capturedAnchorUpdate):
            capturedAnchorUpdate.event
        case .device(let capturedAnchorUpdate):
            capturedAnchorUpdate.event
        case .room(let capturedAnchorUpdate):
            capturedAnchorUpdate.event
        }
    }
}

extension CapturableAnchor {
    func added(timestamp: TimeInterval) -> CapturedAnchorUpdate<Self> {
        CapturedAnchorUpdate(anchor: self, timestamp: timestamp, event: .added)
    }
    
    func updated(timestamp: TimeInterval) -> CapturedAnchorUpdate<Self> {
        CapturedAnchorUpdate(anchor: self, timestamp: timestamp, event: .updated)
    }
    
    func removed(timestamp: TimeInterval) -> CapturedAnchorUpdate<Self> {
        CapturedAnchorUpdate(anchor: self, timestamp: timestamp, event: .removed)
    }
}

//extension AnchorUpdate where AnchorType: CapturableAnchor {
//    var captured: CapturedAnchorUpdate<AnchorType.CapturedType> {
//        let capturedAnchor: AnchorType.CapturedType = anchor.captured
//        
//        return CapturedAnchorUpdate<AnchorType.CapturedType>(anchor: capturedAnchor, timestamp: self.timestamp, event: self.event.captured)
//    }
//}
//
//extension AnchorUpdate.Event where AnchorType: CapturableAnchor {
//    var captured: CapturedAnchorEvent {
//        switch self {
//        case .added:
//            .added
//        case .updated:
//            .updated
//        case .removed:
//            .removed
//        }
//    }
//}
