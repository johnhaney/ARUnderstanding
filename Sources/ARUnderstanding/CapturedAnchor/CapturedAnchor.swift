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

public enum CapturedAnchor: Sendable, Hashable, Equatable {
    case hand(CapturedAnchorUpdate<CapturedHandAnchor>)
    case mesh(CapturedAnchorUpdate<CapturedMeshAnchor>)
    case plane(CapturedAnchorUpdate<CapturedPlaneAnchor>)
    case image(CapturedAnchorUpdate<CapturedImageAnchor>)
    case world(CapturedAnchorUpdate<CapturedWorldAnchor>)
    case device(CapturedAnchorUpdate<CapturedDeviceAnchor>)
    case room(CapturedAnchorUpdate<CapturedRoomAnchor>)
    case object(CapturedAnchorUpdate<CapturedObjectAnchor>)
}

protocol CapturedAnchorUpdateRepresentable {
    var timestamp: TimeInterval { get }
    var event: CapturedAnchorEvent { get }

}

public struct CapturedAnchorUpdate<AnchorType: Anchor & Hashable & Identifiable>: CapturedAnchorUpdateRepresentable, Sendable, Hashable, Equatable where AnchorType: Anchor {
    public let anchor: AnchorType
    public let timestamp: TimeInterval
    public let event: CapturedAnchorEvent
    
    public init(anchor: AnchorType, timestamp: TimeInterval, event: CapturedAnchorEvent) {
        self.anchor = anchor
        self.timestamp = timestamp
        self.event = event
    }
}

public enum CapturedAnchorEvent: String, Sendable, Hashable {
    case added
    case updated
    case removed
    
    var code: UInt8 {
        switch self {
        case .added: 1
        case .updated: 2
        case .removed: 3
        }
    }
    
    init?(code: UInt8) {
        switch code {
        case 1: self = .added
        case 2: self = .updated
        case 3: self = .removed
        default: return nil
        }
    }
}

extension CapturedAnchor {
    private var anchor: any Anchor {
        switch self {
        case .hand(let update): update.anchor
        case .mesh(let update): update.anchor
        case .plane(let update): update.anchor
        case .image(let update): update.anchor
        case .world(let update): update.anchor
        case .device(let update): update.anchor
        case .room(let update): update.anchor
        case .object(let update): update.anchor
        }
    }
    
    private var update: any CapturedAnchorUpdateRepresentable {
        switch self {
        case .hand(let update): update
        case .mesh(let update): update
        case .plane(let update): update
        case .image(let update): update
        case .world(let update): update
        case .device(let update): update
        case .room(let update): update
        case .object(let update): update
        }
    }
    
    public var id: UUID { anchor.id }
    
    public var timestamp: TimeInterval { update.timestamp }
    
    public var event: CapturedAnchorEvent { update.event }
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
