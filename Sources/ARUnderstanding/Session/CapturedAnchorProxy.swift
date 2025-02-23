//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/22/25.
//

import Foundation

public struct CapturedAnchorProxy: Hashable, Sendable {
    let data: Data
    public init(anchor: CapturedAnchor) throws {
        data = try anchor.pack()
    }
    var anchor: CapturedAnchor? {
        do {
            let (anchor, _) = try CapturedAnchor.unpack(data: data)
            return anchor
        } catch {
            return nil
        }
    }
}
