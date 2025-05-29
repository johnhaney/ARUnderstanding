//
//  BinaryReader.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/1/25.
//

import Foundation

class BinaryReader<T: PackDecodable & Sendable> {
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
        try Self.iterate(fileHandle: fileHandle, iterator)
    }
    
    static private func iterate(fileHandle: FileHandle, _ continuation: AsyncStream<T>.Continuation) throws {
        try self.iterate(fileHandle: fileHandle) { item, shouldStop in
            switch continuation.yield(item) {
            case .terminated:
                logger.info("BinaryReader iteration terminated")
                shouldStop = true
            case .dropped:
                logger.info("BinaryReader iteration dropped")
            case .enqueued:
                logger.info("BinaryReader iteration enqueued")
            @unknown default:
                logger.info("BinaryReader iteration UNKNOWN")
            }
            if shouldStop {
                logger.info("BinaryReader iteration terminated")
            }
        }
    }
    
    static private func iterate(fileHandle: FileHandle, _ iterator: (T, inout Bool) throws -> Void) throws {
        var shouldStop = false
        var buffer: Data = Data()
        while let chunk = try? fileHandle.read(upToCount: 1024) {
            buffer.append(chunk)
            do {
                while !buffer.isEmpty {
                    let (item, consumed) = try T.unpack(data: buffer)
                    buffer = buffer.dropFirst(consumed)
                    try iterator(item, &shouldStop)
                    guard !shouldStop else {
                        logger.info("end of buffer")
                        return
                    }
                }
            } catch (UnpackError.needsMoreData) {
                // Continue parsing
            } catch {
                // stop all parsing
                logger.error("something went wrong: \(error.localizedDescription)")
                if buffer.isEmpty {
                    logger.info("end of buffer (something went wrong)")
                    break
                }
                buffer.removeFirst()
            }
        }
        do {
            while !buffer.isEmpty {
                let (item, consumed) = try T.unpack(data: buffer)
                buffer = buffer.dropFirst(consumed)
                try iterator(item, &shouldStop)
                guard !shouldStop else {
                    return
                }
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
            let id = UUID()
            logger.info("\(id): objects() starting…")
            guard let fileHandle = try? FileHandle(forReadingFrom: fileURL)
            else {
                logger.error("\(id): objects() finished no file handle")
                continuation.finish()
                return
            }
            
            Task {
                defer {
                    logger.info("\(id): objects() closing…")
                    fileHandle.closeFile()
                }
                do {
                    logger.info("\(id): objects() iterating…")
                    try Self.iterate(fileHandle: fileHandle, continuation)
                    logger.info("\(id): objects() iterated")
                } catch {
                    logger.error("\(id): objects() error on iterate \(error.localizedDescription)")
                }
                continuation.finish()
            }
        }
    }
}
