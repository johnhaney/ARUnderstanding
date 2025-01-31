//
//  AnchorRecorder.swift
//  HandCapture
//
//  Created by John Haney on 4/29/24.
//

import Foundation
import UniformTypeIdentifiers
import ARUnderstanding
import OSLog

let logger = Logger(subsystem: "com.appsyoucanmake.AnchorRecorder", category: "general")

extension UTType {
    static var arAnchorRecording: UTType {
        UTType(exportedAs: "com.appsfromouterspace.arunderstanding.aranchor")
    }
}

public struct AnchorRecording: Sendable {
    public let records: [CapturedAnchor]
}

public actor AnchorRecorder {
    public let outputName: String
    public private(set) var records: [CapturedAnchor] = []
    
    public var recording: AnchorRecording {
        AnchorRecording(records: records)
    }
    
    public func save() async throws {
        do {
            let fileURL = try Self.fileURL(outputName: outputName)
            let recordsToSave = records
            let data = try JSONEncoder().encode(recordsToSave)
            try data.write(to: fileURL)
            logger.trace("Saved \(self.records.count) records to \(fileURL)")
        } catch {
            logger.error("Error saving \(self.records.count) records to \(self.outputName).anchorsession: \(error.localizedDescription)")
            throw error
        }
        return
    }
    
    public init(outputName: String? = nil) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        self.outputName = "\(outputName ?? "ARSession")-\(formatter.string(from: Date()))"
    }
    
    public func record(anchor: CapturedAnchor) async {
        records.append(anchor)
        if self.records.count % 200 == 0 {
            logger.trace("\(self.records.count) records in memory")
            try? await save()
        }
    }
    
    public static func fileURL(outputName: String) throws -> URL {
        let documentURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = documentURL.appendingPathComponent("\(outputName).anchorsession", conformingTo: .arAnchorRecording)
        return fileURL
    }
}

#if os(visionOS)
import ARKit

extension AnchorRecorder {
    public func record(anchor: AnchorUpdate<HandAnchor>) async {
        records.append(.hand(anchor.captured))
        if self.records.count % 200 == 0 {
            logger.trace("\(self.records.count) records in memory")
            try? await save()
        }
    }
    
    public func record(anchor: AnchorUpdate<WorldAnchor>) async {
        records.append(.world(anchor.captured))
        if self.records.count % 200 == 0 {
            logger.trace("\(self.records.count) records in memory")
            try? await save()
        }
    }
    
    public func record(anchor: AnchorUpdate<MeshAnchor>) async {
        records.append(.mesh(anchor.captured))
        if self.records.count % 200 == 0 {
            logger.trace("\(self.records.count) records in memory")
            try? await save()
        }
    }
    
    public func record(anchor: AnchorUpdate<ImageAnchor>) async {
        records.append(.image(anchor.captured))
        if self.records.count % 200 == 0 {
            logger.trace("\(self.records.count) records in memory")
            try? await save()
        }
    }
    
    public func record(anchor: AnchorUpdate<PlaneAnchor>) async {
        records.append(.plane(anchor.captured))
        if self.records.count % 200 == 0 {
            logger.trace("\(self.records.count) records in memory")
            try? await save()
        }
    }
    
    public func record(anchor: AnchorUpdate<DeviceAnchor>) async {
        records.append(.device(anchor.captured))
        if self.records.count % 200 == 0 {
            logger.trace("\(self.records.count) records in memory")
            try? await save()
        }
    }
}
#endif
