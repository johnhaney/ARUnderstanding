//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/5/25.
//

#if os(iOS)
import ARKit
import RealityKit

extension ARImageAnchor: CapturableARAnchor {
    func capturedAnchor(_ event: CapturedAnchorEvent, timestamp: TimeInterval) -> CapturedAnchor {
        let anchor = CapturedImageAnchor(id: identifier, originFromAnchorTransform: transform, isTracked: true, referenceImageName: referenceImage.name ?? "", estimatedScaleFactor: Float(estimatedScaleFactor), estimatedPhysicalWidth: Float(estimatedScaleFactor * referenceImage.physicalSize.width), estimatedPhysicalHeight: Float(estimatedScaleFactor * referenceImage.physicalSize.height))
        let update = CapturedAnchorUpdate<CapturedImageAnchor>(anchor: anchor, timestamp: timestamp, event: event)
        return CapturedAnchor.image(update)
    }
}
#endif
