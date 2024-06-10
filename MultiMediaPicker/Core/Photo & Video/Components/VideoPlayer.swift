//
//  VideoPlayer.swift
//  PhotoVideoPicker
//
//  Created by Benji Loya on 18.05.2024.
//

import SwiftUI
import AVKit

struct VideoPlayerCustom: UIViewControllerRepresentable {
    let mediaURL: URL
    @Binding var isMuted: Bool
    @Binding var isPlaying: Bool
    @Binding var isLoading: Bool

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: mediaURL)
        player.isMuted = isMuted
        
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.showsPlaybackControls = false
        
        player.addObserver(context.coordinator, forKeyPath: "status", options: [.new, .initial], context: nil)
        
        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if isPlaying {
            uiViewController.player?.play()
        } else {
            uiViewController.player?.pause()
        }
        uiViewController.player?.isMuted = isMuted // Обновление состояния звука
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: VideoPlayerCustom
        
        init(_ parent: VideoPlayerCustom) {
            self.parent = parent
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == "status", let player = object as? AVPlayer {
                if player.status == .readyToPlay {
                    DispatchQueue.main.async {
                        self.parent.isLoading = false
                        self.parent.isPlaying = true
                    }
                }
            }
        }
    }
}
