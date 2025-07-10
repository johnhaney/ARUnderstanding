//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/5/25.
//

#if os(iOS)
import ARKit
import RealityKit

extension ARObjectAnchor: CapturableARAnchor {
    func capturedAnchor(_ event: CapturedAnchorEvent, timestamp: TimeInterval) -> CapturedAnchor {
        let anchor = CapturedObjectAnchor(id: identifier, originFromAnchorTransform: transform, referenceObjectName: referenceObject.name ?? "", isTracked: true)
        let update = CapturedAnchorUpdate<CapturedObjectAnchor>(anchor: anchor, timestamp: timestamp, event: event)
        return CapturedAnchor.object(update)
    }
}
#endif
