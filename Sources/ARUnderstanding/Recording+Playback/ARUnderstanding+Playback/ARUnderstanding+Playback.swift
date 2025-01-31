//
//  File.swift
//  
//
//  Created by John Haney on 5/12/24.
//

import ARUnderstanding

extension ARUnderstanding {
    public func playback(fileName: String) -> ARUnderstandingProvider {
        AnchorPlayback(fileName: fileName)
    }
}

extension ARUnderstandingProvider {
    public func playback(fileName: String) -> ARUnderstandingProvider {
        AnchorPlayback(fileName: fileName)
    }
}
