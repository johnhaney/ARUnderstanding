//
//  ARUnderstanding+Playback.swift
//  
//
//  Created by John Haney on 5/12/24.
//

import Foundation

extension ARUnderstanding {
    public func playback(fileName: String) -> ARUnderstandingProvider? {
        AnchorPlayback(fileName: fileName)
    }
}

extension ARUnderstandingProvider {
    public func playback(fileName: String) -> ARUnderstandingProvider? {
        AnchorPlayback(fileName: fileName)
    }
}
