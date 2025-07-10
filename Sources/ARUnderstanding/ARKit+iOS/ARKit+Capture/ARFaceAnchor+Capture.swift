//
//  ARFaceAnchor+Capture.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/4/25.
//

#if os(iOS)
import ARKit
import RealityKit

extension ARFaceAnchor: CapturableARAnchor {
    func capturedAnchor(_ event: CapturedAnchorEvent, timestamp: TimeInterval) -> CapturedAnchor {
        let update = CapturedAnchorUpdate<CapturedFaceAnchor>(anchor: captured, timestamp: timestamp, event: event)
        return CapturedAnchor.face(update)
    }
}
#endif
