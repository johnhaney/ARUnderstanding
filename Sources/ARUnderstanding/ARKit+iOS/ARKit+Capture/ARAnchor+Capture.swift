//
//  ARAnchor+Capture.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/3/25.
//

#if os(iOS)
import ARKit

extension ARAnchor {
    public func captured(_ event: CapturedAnchorEvent, timestamp: TimeInterval) -> CapturedAnchor {
        if let capturable = self as? CapturableARAnchor {
            capturable.capturedAnchor(event, timestamp: timestamp)
        } else {
            CapturedAnchor.world(CapturedAnchorUpdate<CapturedWorldAnchor>(anchor: CapturedWorldAnchor(id: identifier, originFromAnchorTransform: transform, isTracked: false).captured, timestamp: timestamp, event: event))
        }
    }
}
#endif
