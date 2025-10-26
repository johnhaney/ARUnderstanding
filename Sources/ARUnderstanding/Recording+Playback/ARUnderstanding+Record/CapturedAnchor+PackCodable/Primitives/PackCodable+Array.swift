//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 10/26/25.
//

import Foundation

extension Array: PackEncodable where Element: PackEncodable {
    public func pack() throws -> Data {
        let datas = try flatMap { element in
            try element.pack()
        }
        return try count.pack() + datas
    }
}

extension Array: PackDecodable where Element: PackDecodable {
    public static func unpack(data: Data) throws -> (Array<Element>, Int) {
        let (count, countBytes) = try Int.unpack(data: data)
        var offset = countBytes
        var working = data
        working.removeFirst(countBytes)
        let (elements, bytes) = try Element.unpack(data: working, count: count)
        offset += bytes
        return (elements, offset)
    }
}
