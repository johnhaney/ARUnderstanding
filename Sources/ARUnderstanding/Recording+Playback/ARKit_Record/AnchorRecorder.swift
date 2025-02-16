//
//  AnchorRecorder.swift
//  HandCapture
//
//  Created by John Haney on 4/29/24.
//

import Foundation
import UniformTypeIdentifiers
import ARUnderstanding
import JSONLStream
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
    private let prefix: String
    public private(set) var outputName: String
    private var writer: JSONLWriter?
    
    public func recording() async throws -> AnchorRecording {
        let fileURL = try Self.fileURL(outputName: outputName)
        guard let reader = JSONLReader(fileURL: fileURL)
        else {
            logger.error("Error providing recording")
            throw NSError(domain: "com.appsyoucanmake.AnchorRecorder", code: 1, userInfo: nil)
        }
        let records: [CapturedAnchor] = await reader.allObjects()
        return AnchorRecording(records: records)
    }
    
    public init(outputName: String? = nil) {
        let prefix: String = outputName ?? "ARSession"
        self.prefix = prefix
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        self.outputName = "\(prefix)-\(formatter.string(from: Date()))"
        self.writer = nil
        if let fileURL = try? Self.fileURL(outputName: self.outputName) {
            self.writer = JSONLWriter(fileURL: fileURL, appendIfExists: true)
        }
    }
    
    private func startNewSession() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        self.outputName = "\(prefix)-\(formatter.string(from: Date()))"
        if let fileURL = try? Self.fileURL(outputName: self.outputName) {
            self.writer = JSONLWriter(fileURL: fileURL, appendIfExists: true)
        }
    }
    
    public func record(anchor: CapturedAnchor) async {
        try? await writer?.write(jsonObject: anchor)
    }
    
    public static func fileURL(outputName: String) throws -> URL {
        let documentURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = documentURL.appendingPathComponent("\(outputName).anchorsession", conformingTo: .arAnchorRecording)
        return fileURL
    }
}

extension AnchorRecorder: ARUnderstandingOutput {
    public func handleNewSession() async {
        await startNewSession()
    }
    public func handleAnchor(_ anchor: CapturedAnchor) async {
        await self.record(anchor: anchor)
    }
}

#if os(visionOS)
import ARKit

extension AnchorRecorder {
    public func record(anchor: AnchorUpdate<HandAnchor>) async {
        await record(anchor: .hand(anchor.captured))
    }
    
    public func record(anchor: AnchorUpdate<WorldAnchor>) async {
        await record(anchor: .world(anchor.captured))
    }
    
    public func record(anchor: AnchorUpdate<MeshAnchor>) async {
        await record(anchor: .mesh(anchor.captured))
    }
    
    public func record(anchor: AnchorUpdate<ImageAnchor>) async {
        await record(anchor: .image(anchor.captured))
    }
    
    public func record(anchor: AnchorUpdate<PlaneAnchor>) async {
        await record(anchor: .plane(anchor.captured))
    }
    
    public func record(anchor: AnchorUpdate<DeviceAnchor>) async {
        await record(anchor: .device(anchor.captured))
    }
}
#endif
