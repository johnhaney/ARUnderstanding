//
//  FaceTracking+Playback.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/1/25.
//

#if canImport(ARKit)
import ARKit
#endif

public protocol FaceTrackingProviderRepresentable {
    var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedFaceAnchor>> { get }
}

