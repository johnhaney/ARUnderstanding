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
    
    private static func fileURL(outputName: String) throws -> URL {
        let documentURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = documentURL.appendingPathComponent("\(outputName).anchorsession", conformingTo: .arAnchorRecording)
        return fileURL
    }

    public var sessionUpdates: AsyncStream<ARUnderstandingSession.Message> {
        return AsyncStream { continuation in
            if let fileURL,
               let reader = BinaryReader<CapturedAnchor>(fileURL: fileURL) {
                let task: Task<(), Never> = Task {
                    defer { continuation.finish() }
                    repeat {
                        continuation.yield(ARUnderstandingSession.Message.newSession)
                        let start = Date()
                        var firstTimestamp: TimeInterval?
                        for await event in reader.objects() {
                            let offset = event.timestamp - (firstTimestamp ?? event.timestamp)
                            firstTimestamp = firstTimestamp ?? event.timestamp
                            while offset > Date().timeIntervalSince(start) {
                                try? await Task.sleep(for: .seconds(offset - Date().timeIntervalSince(start)))
                            }
                            do {
                                continuation.yield(ARUnderstandingSession.Message.anchor(event))
                            }
                        }
                        try? await Task.sleep(for: .seconds(1))
                    } while true
                }
                continuation.onTermination = { @Sendable _ in
                    task.cancel()
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
                        Task {
                            while offset > -start.timeIntervalSinceNow {
                                try? await Task.sleep(for: .seconds(offset + start.timeIntervalSinceNow))
                            }
                            continuation.yield(event)
                        }
                    }
                    try? await Task.sleep(for: .seconds(1))
                } while true
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
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
