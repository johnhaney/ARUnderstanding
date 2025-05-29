//
//  File 2.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/1/25.
//

import Foundation

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
    public func write(data: Data) throws {
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
