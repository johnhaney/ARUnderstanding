//
//  AnchorPlayback.swift
//  HandCapture
//
//  Created by John Haney on 4/29/24.
//

import Foundation

final public class AnchorPlayback: ARUnderstandingProvider, ARUnderstandingInput, Sendable {
    private let fileURL: URL?

    public init(fileName: String) {
        self.fileURL = Bundle.main.url(forResource: fileName, withExtension: "anchorsession")
    }
    
    public init(url: URL) {
        self.fileURL = url
    }
    
    private static func fileURL(outputName: String) throws -> URL {
        let documentURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = documentURL.appendingPathComponent("\(outputName).anchorsession", conformingTo: .arAnchorRecording)
        return fileURL
    }

    public var messages: AsyncStream<ARUnderstandingSession.Message> {
        AsyncStream { continuation in
            if let fileURL {
                let task: Task<(), Never> = Task.detached {
                    defer {
                        continuation.finish()
                    }
                    continuation.yield(ARUnderstandingSession.Message.newSession)
                    repeat {
                        if let reader = BinaryReader<CapturedAnchor>(fileURL: fileURL) {
                            let start = Date()
                            var firstTimestampSaved: TimeInterval?
                            var item = 0
                            for await event in reader.objects() {
                                item += 1
                                let firstTimestamp: TimeInterval
                                if let firstTimestampSaved {
                                    firstTimestamp = firstTimestampSaved
                                } else {
                                    firstTimestampSaved = event.timestamp
                                    firstTimestamp = event.timestamp
                                }
                                let offset = event.timestamp - firstTimestamp
                                let startOffset = Date().timeIntervalSince(start)
                                if offset > startOffset {
                                    try? await Task.sleep(for: .milliseconds(Int((offset - startOffset)*1000)))
                                }
                                do {
                                    var shouldStop = false
                                    switch continuation.yield(ARUnderstandingSession.Message.anchor(event)) {
                                    case .terminated:
                                        shouldStop = true
                                    case .dropped: break
                                    case .enqueued: break
                                    @unknown default: break
                                    }
                                    
                                    if shouldStop {
                                        break
                                    }
                                }
                            }
                        }
                        try? await Task.sleep(for: .seconds(1))
                    } while !Task.isCancelled
                }
                continuation.onTermination = { @Sendable termination in
                    switch termination {
                    case .cancelled:
                        task.cancel()
                    default: break
                    }
                }
            } else {
                continuation.finish()
            }
        }
    }
    
    public var anchorUpdates: AsyncStream<CapturedAnchor> {
        AsyncStream { continuation in
            guard let fileURL,
                  let reader = BinaryReader<CapturedAnchor>(fileURL: fileURL)
            else {
                continuation.finish()
                return
            }
            let task = Task {
                defer { continuation.finish() }
                repeat {
                    let start = Date()
                    var firstTimestamp: TimeInterval?
                    for await event in reader.objects() {
                        let offset = event.timestamp - (firstTimestamp ?? event.timestamp)
                        firstTimestamp = firstTimestamp ?? event.timestamp
                        while offset > -start.timeIntervalSinceNow {
                            try? await Task.sleep(for: .seconds(offset + start.timeIntervalSinceNow))
                        }
                        continuation.yield(event)
                    }
                    try? await Task.sleep(for: .seconds(1))
                } while !Task.isCancelled
            }
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled: task.cancel()
                default: break
                }
            }
        }
    }
    
    public func queryDeviceAnchor(atTimestamp timestamp: TimeInterval) -> CapturedDeviceAnchor? {
        guard let fileURL,
              let reader = BinaryReader<CapturedAnchor>(fileURL: fileURL)
        else { return nil }
        
        var firstTimestamp: TimeInterval?
        var lastDeviceAnchor: CapturedDeviceAnchor? = nil
        
        try? reader.iterate { (event, stop) in
            let offset = event.timestamp - (firstTimestamp ?? event.timestamp)
            firstTimestamp = firstTimestamp ?? event.timestamp
            if offset > timestamp {
                stop = true
            } else if case let .device(update) = event {
                lastDeviceAnchor = update.anchor
            }
        }
        
        return lastDeviceAnchor
    }
}
