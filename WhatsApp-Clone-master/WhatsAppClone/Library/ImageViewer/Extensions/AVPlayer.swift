//
//  AVPlayer.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//

import AVFoundation

extension AVPlayer {

    func isPlaying() -> Bool {

        return (self.rate != 0.0 && self.status == .readyToPlay)
    }
}
