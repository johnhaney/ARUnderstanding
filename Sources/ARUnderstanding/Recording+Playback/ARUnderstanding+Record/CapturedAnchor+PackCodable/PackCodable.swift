//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/22/25.
//

import Foundation

enum UnpackError: Error {
    case needsMoreData(Int)
    case failed
}

enum PackError: Error {
    case failed
}

public protocol PackEncodable {
    func pack() throws -> Data
}

public protocol PackDecodable {
    static func unpack(data: Data) throws -> (Self, Int)
}

extension PackDecodable {
    public static func unpack(data: Data, count: Int) throws -> ([Self], Int) {
        guard count >= .zero
        else {
            throw UnpackError.failed
        }
        guard count > .zero else { return ([], .zero) }
        var offset: Int = 0
        let result = try (1...count).map { _ in
            let (value, consumed) = try Self.unpack(data: data[(data.startIndex + offset)...])
            offset += consumed
            return value
        }
        return (result, offset)
    }
}

protocol PackCodable: PackEncodable, PackDecodable {}

extension Data {
    init<T>(underlying value: T) {
        var target = value
        self = Swift.withUnsafeBytes(of: &target) {
            Data($0)
        }
    }
    
    func interpreted<T>(as type: T.Type = T.self) -> T {
        Data(self).withUnsafeBytes {
            $0.baseAddress!.load(as: T.self)
        }
    }
}
