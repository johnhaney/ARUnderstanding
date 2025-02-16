//
//  ARUnderstanding+Record.swift
//  HandCapture
//
//  Created by John Haney on 4/29/24.
//

import Foundation
import ARUnderstanding

extension ARUnderstanding {
    public func record(outputName: String? = nil) async -> ARUnderstandingProvider {
        await AnchorRecorder(outputName: outputName).understandingSource(self)
    }
}

extension AnchorRecorder {
    nonisolated func understandingSource(_ understanding: ARUnderstanding) async -> ARUnderstandingSource {
        await ARUnderstandingSource(recorder: self, understanding: understanding)
    }
    
    struct ARUnderstandingSource: ARUnderstandingProvider {
        private let recorder: AnchorRecorder
        private let understanding: AsyncStream<CapturedAnchor>
        
        init(recorder: AnchorRecorder, understanding: ARUnderstanding) async {
            self.recorder = recorder
            self.understanding = await understanding.anchorUpdates
        }
        
        nonisolated var anchorUpdates: AsyncStream<CapturedAnchor> {
            Self.anchorUpdates(recorder: recorder, source: understanding)
        }
        
        static func anchorUpdates(recorder: AnchorRecorder, source: AsyncStream<CapturedAnchor>) -> AsyncStream<CapturedAnchor> {
            AsyncStream { continuation in
                Task {
                    defer { continuation.finish() }
                    for await update in source {
                        continuation.yield(update)
                        Task {
                            await recorder.record(anchor: update)
                        }
                    }
                }
            }
        }
    }
}

extension AsyncStream where Element == CapturedAnchor {
    public func record(outputName: String? = nil) -> AsyncStream<CapturedAnchor> {
        AsyncStream { continuation in
            let recorder = AnchorRecorder(outputName: outputName)
            Task {
                defer { continuation.finish() }
                for await anchor in self {
                    continuation.yield(anchor)
                    Task {
                        await recorder.record(anchor: anchor)
                    }
                }
            }
        }
    }
}

extension AsyncStream where Element == CapturedAnchorUpdate<CapturedHandAnchor> {
    public func record(outputName: String? = nil) -> AsyncStream<CapturedAnchorUpdate<CapturedHandAnchor>> {
        AsyncStream { continuation in
            let recorder = AnchorRecorder(outputName: outputName)
            Task {
                defer { continuation.finish() }
                for await anchor in self {
                    continuation.yield(anchor)
                    Task {
                        await recorder.record(anchor: .hand(anchor))
                    }
                }
            }
        }
    }
}

extension AsyncStream where Element == CapturedAnchorUpdate<CapturedPlaneAnchor> {
    public func record(outputName: String? = nil) -> AsyncStream<CapturedAnchorUpdate<CapturedPlaneAnchor>> {
        AsyncStream { continuation in
            let recorder = AnchorRecorder(outputName: outputName)
            Task {
                defer { continuation.finish() }
                for await anchor in self {
                    continuation.yield(anchor)
                    Task {
                        await recorder.record(anchor: .plane(anchor))
                    }
                }
            }
        }
    }
}

extension AsyncStream where Element == CapturedAnchorUpdate<CapturedMeshAnchor> {
    public func record(outputName: String? = nil) -> AsyncStream<CapturedAnchorUpdate<CapturedMeshAnchor>> {
        AsyncStream { continuation in
            let recorder = AnchorRecorder(outputName: outputName)
            Task {
                defer { continuation.finish() }
                for await anchor in self {
                    continuation.yield(anchor)
                    Task {
                        await recorder.record(anchor: .mesh(anchor))
                    }
                }
            }
        }
    }
}

extension AsyncStream where Element == CapturedAnchorUpdate<CapturedImageAnchor> {
    public func record(outputName: String? = nil) -> AsyncStream<CapturedAnchorUpdate<CapturedImageAnchor>> {
        AsyncStream { continuation in
            let recorder = AnchorRecorder(outputName: outputName)
            Task {
                defer { continuation.finish() }
                for await anchor in self {
                    continuation.yield(anchor)
                    Task {
                        await recorder.record(anchor: .image(anchor))
                    }
                }
            }
        }
    }
}

extension AsyncStream where Element == CapturedAnchorUpdate<CapturedDeviceAnchor> {
    public func record(outputName: String? = nil) -> AsyncStream<CapturedAnchorUpdate<CapturedDeviceAnchor>> {
        AsyncStream { continuation in
            let recorder = AnchorRecorder(outputName: outputName)
            Task {
                defer { continuation.finish() }
                for await anchor in self {
                    continuation.yield(anchor)
                    Task {
                        await recorder.record(anchor: .device(anchor))
                    }
                }
            }
        }
    }
}

extension AsyncStream where Element == CapturedAnchorUpdate<CapturedWorldAnchor> {
    public func record(outputName: String? = nil) -> AsyncStream<CapturedAnchorUpdate<CapturedWorldAnchor>> {
        AsyncStream { continuation in
            let recorder = AnchorRecorder(outputName: outputName)
            Task {
                defer { continuation.finish() }
                for await anchor in self {
                    continuation.yield(anchor)
                    Task {
                        await recorder.record(anchor: .world(anchor))
                    }
                }
            }
        }
    }
}
