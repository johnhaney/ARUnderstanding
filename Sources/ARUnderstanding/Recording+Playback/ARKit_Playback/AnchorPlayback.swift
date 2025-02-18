//
//  AnchorPlayback.swift
//  HandCapture
//
//  Created by John Haney on 4/29/24.
//

import Foundation

final public class AnchorPlayback: ARUnderstandingProvider, ARUnderstandingInput, Sendable {
    public let recording: AnchorRecording
    
    init(recording: AnchorRecording) {
        self.recording = recording
    }
    
    public init(fileName: String) {
        var fileData: Data? = nil
        do {
            if let fileURL = Bundle.main.url(forResource: fileName, withExtension: "anchorsession") {
                fileData = try Data(contentsOf: fileURL)
            }
        } catch {
        }

        if fileData == nil {
            do {
                let documentURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let fileURL = documentURL.appendingPathComponent("\(fileName).anchorsession", conformingTo: .arAnchorRecording)
                
                fileData = try Data(contentsOf: fileURL)
            } catch {
                logger.error("Error loading from \(fileName).anchorsession: \(error.localizedDescription)")
            }
        }
        
        guard let data = fileData else {
            recording = AnchorRecording(records: [])
            return
        }
        
        do {
            let records = try JSONDecoder().decode([CapturedAnchor].self, from: data)
            recording = AnchorRecording(records: records)
            logger.trace("Loaded \(records.count) records")
        } catch {
            logger.error("Error loading from \(fileName).anchorsession: \(error.localizedDescription)")
            recording = AnchorRecording(records: [])
        }
    }
    
    public var sessionUpdates: AsyncStream<ARUnderstandingSession.Message> {
        AsyncStream { continuation in
            let events = recording.records
            Task {
                repeat {
                    continuation.yield(ARUnderstandingSession.Message.newSession)
                    let start = Date()
                    var firstTimestamp: TimeInterval?
                    for event in events {
                        let offset = event.timestamp - (firstTimestamp ?? event.timestamp)
                        firstTimestamp = firstTimestamp ?? event.timestamp
                        while offset > Date().timeIntervalSince(start) {
                            try? await Task.sleep(for: .seconds(offset - Date().timeIntervalSince(start)))
                        }
                        continuation.yield(ARUnderstandingSession.Message.anchor(event))
                    }
                    try? await Task.sleep(for: .seconds(1))
                } while true
                continuation.finish()
            }
        }
    }
    
    public var anchorUpdates: AsyncStream<CapturedAnchor> {
        AsyncStream { continuation in
            let events = recording.records
            Task {
                repeat {
                    let start = Date()
                    var firstTimestamp: TimeInterval?
                    for event in events {
                        let offset = event.timestamp - (firstTimestamp ?? event.timestamp)
                        firstTimestamp = firstTimestamp ?? event.timestamp
                        while offset > Date().timeIntervalSince(start) {
                            try? await Task.sleep(for: .seconds(offset - Date().timeIntervalSince(start)))
                        }
                        continuation.yield(event)
                    }
                    try? await Task.sleep(for: .seconds(1))
                } while true
                continuation.finish()
            }
        }
    }
}

