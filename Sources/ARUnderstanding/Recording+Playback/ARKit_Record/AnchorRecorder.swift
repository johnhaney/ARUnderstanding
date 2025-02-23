//
//  AnchorRecorder.swift
//  HandCapture
//
//  Created by John Haney on 4/29/24.
//

import Foundation
import UniformTypeIdentifiers
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
    private var writer: BinaryWriter<CapturedAnchor>?
    
    public func recording() throws -> AnchorRecording {
        let fileURL = try Self.fileURL(outputName: outputName)
        guard let reader = BinaryReader<CapturedAnchor>(fileURL: fileURL)
        else {
            logger.error("Error providing recording")
            throw NSError(domain: "com.appsyoucanmake.AnchorRecorder", code: 1, userInfo: nil)
        }
        let records: [CapturedAnchor] = reader.allObjects()
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
            self.writer = BinaryWriter<CapturedAnchor>(fileURL: fileURL, appendIfExists: true)
        }
    }
    
    private func startNewSession() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        self.outputName = "\(prefix)-\(formatter.string(from: Date()))"
        if let fileURL = try? Self.fileURL(outputName: self.outputName) {
            self.writer = BinaryWriter<CapturedAnchor>(fileURL: fileURL, appendIfExists: true)
        }
    }
    
    public func record(anchor: CapturedAnchor) async {
        try? writer?.write(object: anchor)
    }
    
    public static func fileURL(outputName: String) throws -> URL {
        let documentURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = documentURL.appendingPathComponent("\(outputName).anchorsession", conformingTo: .arAnchorRecording)
        return fileURL
    }
}

extension AnchorRecorder: ARUnderstandingOutput {
    public func handleNewSession() async {
        startNewSession()
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

class BinaryWriter<T: PackEncodable> {
    private let fileHandle: FileHandle
    private let fileURL: URL
    
    public init?(fileURL: URL, appendIfExists: Bool = true) {
        self.fileURL = fileURL
        
        // Ensure file exists, or create it
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        } else if !appendIfExists {
            return nil
        }
        
        // Try to open file for appending
        do {
            self.fileHandle = try FileHandle(forWritingTo: fileURL)
            self.fileHandle.seekToEndOfFile() // Move to end for appending
        } catch {
            logger.error("Failed to open file: \(error)")
            return nil
        }
    }
    
    /// Writes a single object (encoded as `Data`) to the file
    private func write(data: Data) throws {
        do {
            try fileHandle.write(contentsOf: data)
        } catch {
            logger.error("Error writing to file: \(error)")
            throw error
        }
    }

    /// Writes a single `PackEncodable` object to the file as Binary
    public func write(object: T) throws {
        do {
            let data: Data = try object.pack()
            try write(data: data)
        } catch {
            logger.error("Error encoding object: \(error)")
            throw error
        }
    }

    /// Writes a sequence of `PackEncodable` objects to the file as Binary
    public func write(objects: [T]) throws {
        do {
            for object in objects {
                try write(object: object)
            }
        } catch {
            logger.error("Error encoding object: \(error)")
            throw error
        }
    }

    /// Closes the file handle
    public func close() {
        do {
            try fileHandle.close()
        } catch {
            logger.error("Error closing file: \(error)")
        }
    }

    /// Automatically closes the file when the object is deallocated
    deinit {
        close()
    }
}

class BinaryReader<T: PackDecodable> {
    private let fileURL: URL
    
    public init?(fileURL: URL) {
        self.fileURL = fileURL
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            logger.error("File does not exist: \(fileURL.path)")
            return nil
        }
        
        if !FileManager.default.isReadableFile(atPath: fileURL.path) {
            logger.error("File is not readable: \(fileURL.path)")
            return nil
        }
    }
    
    public func iterate(_ iterator: (T, inout Bool) throws -> Void) throws {
        let fileHandle = try FileHandle(forReadingFrom: fileURL)
        var shouldStop = false
        var buffer: Data = Data()
        while let chunk = try? fileHandle.read(upToCount: 1024) {
            buffer.append(chunk)
            do {
                while !buffer.isEmpty {
                    let (item, consumed) = try T.unpack(data: buffer)
                    buffer = buffer.dropFirst(consumed)
                    try iterator(item, &shouldStop)
                    guard !shouldStop else { return }
                }
            } catch (UnpackError.needsMoreData) {
                // Continue parsing
            } catch {
                // stop all parsing
                logger.error("something went wrong: \(error.localizedDescription)")
                return
            }
        }
        do {
            while !buffer.isEmpty {
                let (item, consumed) = try T.unpack(data: buffer)
                buffer = buffer.dropFirst(consumed)
                try iterator(item, &shouldStop)
                guard !shouldStop else { return }
            }
        } catch {
            logger.error("something went wrong at end of file: \(error.localizedDescription)")
        }
    }
    
    public func allObjects() -> [T] {
        var output: [T] = []
        do {
            try self.iterate { item, _ in
                output.append(item)
            }
        } catch {
            logger.error("Error reading entire file: \(error.localizedDescription)")
        }
        return output
    }
    
    public func objects() -> AsyncStream<T> {
        AsyncStream { continuation in
            guard let fileHandle = try? FileHandle(forReadingFrom: fileURL)
            else {
                continuation.finish()
                return
            }

            let task = Task {
                defer { continuation.finish() }
                var buffer: Data = Data()
                while let chunk = try? fileHandle.read(upToCount: 1024) {
                    buffer.append(chunk)
                    do {
                        while !buffer.isEmpty {
                            let (item, consumed) = try T.unpack(data: buffer)
                            buffer = buffer.dropFirst(consumed)
                            continuation.yield(item)
                            await Task.yield()
                        }
                    } catch (UnpackError.needsMoreData) {
                        // Continue parsing
                    } catch {
                        // stop all parsing
                        logger.error("something went wrong: \(error.localizedDescription)")
                    }
                }
                do {
                    while !buffer.isEmpty {
                        let (item, consumed) = try T.unpack(data: buffer)
                        buffer = buffer.dropFirst(consumed)
                        continuation.yield(item)
                        await Task.yield()
                    }
                } catch {
                    logger.error("something went wrong at end of file: \(error.localizedDescription)")
                }
                logger.info("End of file")
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
