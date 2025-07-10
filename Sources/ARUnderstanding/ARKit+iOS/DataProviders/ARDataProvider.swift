//
//  ARDataProvider.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/1/25.
//

#if os(iOS)
import Foundation
import ARKit
import RealityKit

protocol ARDataProvider: DataProvider {
    // Configure for SpatialTrackingSession
    var anchorCapabilities: Set<SpatialTrackingSession.Configuration.AnchorCapability> { get }
    var sceneUnderstanding: Set<SpatialTrackingSession.Configuration.SceneUnderstandingCapability> { get }
    
    // Configure for capture
    func configure(_ configuration: inout ARWorldTrackingConfiguration)
    func configure(_ configuration: inout ARBodyTrackingConfiguration)
}

protocol AnchorCapturingDataProvider: ARDataProvider {
    associatedtype AnchorType: ARAnchor
    // do capture per anchor
    func capture(anchor: AnchorType, timestamp: TimeInterval, event: CapturedAnchorEvent) -> CapturedAnchor?
}

extension AnchorCapturingDataProvider {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor], _ continuation: AsyncStream<ARUnderstandingSession.Message>.Continuation?) {
        guard let continuation else { return }
        let timestamp: TimeInterval = session.currentFrame?.timestamp ?? 0

        let filteredAnchors = anchors.compactMap { $0 as? AnchorType }
        guard !filteredAnchors.isEmpty else { return }
        for anchor in filteredAnchors {
            if let captured = capture(anchor: anchor, timestamp: timestamp, event: .added) {
                continuation.yield(.anchor(captured))
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor], _ continuation: AsyncStream<ARUnderstandingSession.Message>.Continuation?) {
        guard let continuation else { return }
        let timestamp: TimeInterval = session.currentFrame?.timestamp ?? 0
        
        let filteredAnchors = anchors.compactMap { $0 as? AnchorType }
        guard !filteredAnchors.isEmpty else { return }
        for anchor in filteredAnchors {
            if let captured = capture(anchor: anchor, timestamp: timestamp, event: .updated) {
                continuation.yield(.anchor(captured))
            }
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor], _ continuation: AsyncStream<ARUnderstandingSession.Message>.Continuation?) {
        guard let continuation else { return }
        let timestamp: TimeInterval = session.currentFrame?.timestamp ?? 0
        
        let filteredAnchors = anchors.compactMap { $0 as? AnchorType }
        guard !filteredAnchors.isEmpty else { return }
        for anchor in filteredAnchors {
            if let captured = capture(anchor: anchor, timestamp: timestamp, event: .removed) {
                continuation.yield(.anchor(captured))
            }
        }
    }
}

protocol FrameCapturingDataProvider: ARDataProvider {
    // Compute any anchors per frame
    func capture(session: ARSession, frame: ARFrame) -> [CapturedAnchor]
}

extension FrameCapturingDataProvider {
    func session(_ session: ARSession, didUpdate frame: ARFrame, _ continuation: AsyncStream<ARUnderstandingSession.Message>.Continuation?) {
        guard let continuation else { return }
        let updates = capture(session: session, frame: frame)
        for captured in updates {
            continuation.yield(.anchor(captured))
        }
    }
}

extension ARDataProvider {
    func configure(_ configuration: inout ARWorldTrackingConfiguration) {}
    func configure(_ configuration: inout ARBodyTrackingConfiguration) {}
    
    func session(_ session: ARSession, didUpdate frame: ARFrame, _ continuation: AsyncStream<ARUnderstandingSession.Message>.Continuation?) {
        guard let provider = self as? FrameCapturingDataProvider else { return }
        provider.session(session, didUpdate: frame, continuation)
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor], _ continuation: AsyncStream<ARUnderstandingSession.Message>.Continuation?) {
        guard let provider = self as? AnchorCapturingDataProvider else { return }
        provider.session(session, didAdd: anchors, continuation)
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor], _ continuation: AsyncStream<ARUnderstandingSession.Message>.Continuation?) {
        guard let provider = self as? AnchorCapturingDataProvider else { return }
        provider.session(session, didUpdate: anchors, continuation)
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor], _ continuation: AsyncStream<ARUnderstandingSession.Message>.Continuation?) {
        guard let provider = self as? AnchorCapturingDataProvider else { return }
        provider.session(session, didRemove: anchors, continuation)
    }
}
#endif
