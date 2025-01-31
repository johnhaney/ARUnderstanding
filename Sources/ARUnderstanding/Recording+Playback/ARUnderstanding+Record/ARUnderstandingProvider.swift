//
//  ARUnderstandingProvider.swift
//  HandCapture
//
//  Created by John Haney on 4/29/24.
//

import Foundation
import ARUnderstanding

public protocol ARUnderstandingProvider {
    var anchorUpdates: AsyncStream<CapturedAnchor> { get }
    var handUpdates: AsyncStream<CapturedAnchorUpdate<CapturedHandAnchor>> { get }
}

extension ARUnderstandingProvider {
    public var handUpdates: AsyncStream<CapturedAnchorUpdate<CapturedHandAnchor>> {
        AsyncStream { continuation in
            let anchorUpdates = self.anchorUpdates
            Task {
                defer {
                    continuation.finish()
                }
                for await anchor in anchorUpdates {
                    if case let .hand(handAnchor) = anchor {
                        continuation.yield(handAnchor)
                    }
                }
            }
        }
    }
}
