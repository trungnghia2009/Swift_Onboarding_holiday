//
//  ViewController.swift
//  onboarding-holiday-app
//
//  Created by trungnghia on 4/27/20.
//  Copyright © 2020 trungnghia. All rights reserved.
//

import UIKit
import AVFoundation
import Combine

class OnboardingViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var getStartedButton: UIButton!
    @IBOutlet weak var darkView: UIView!
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private let notificationCenter = NotificationCenter.default
    private var appEventSubscribers = [AnyCancellable]()
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        observeAppEvent()
        setupPlayerIfNeeded()
        restartVideo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Keep back button for nextView
        navigationController?.setNavigationBarHidden(false, animated: animated)
        removeAppEventSubscribers()
        removePlayer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
    }
    
    // Hide statusBar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func setupView() {
        getStartedButton.layer.cornerRadius = getStartedButton.frame.height / 2
        getStartedButton.layer.masksToBounds = true
        darkView.backgroundColor = UIColor.init(white: 0.1, alpha: 0.4)
    }
    
    //MARK: - player funcs
    private func buildPlayer() -> AVPlayer? {
        guard let filePath = Bundle.main.path(forResource: "bg_video", ofType: "mp4") else { return nil }
        let url = URL(fileURLWithPath: filePath)
        let player = AVPlayer(url: url)
        player.actionAtItemEnd = .none
        player.isMuted = true
        return player
    }
    
    private func buildPlayerLayer() -> AVPlayerLayer? {
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        return layer
    }
    
    //MARK: - Handle video
    private func playVideo() {
        player?.play()
    }
    
    private func restartVideo() {
        player?.seek(to: .zero)
        playVideo()
    }
    
    private func pauseVideo() {
        player?.pause()
    }
    
    private func setupPlayerIfNeeded() {
        player = buildPlayer()
        playerLayer = buildPlayerLayer()
        
        if let layer = playerLayer {
            //Avoid double add the layers
            if view.layer.sublayers?.contains(layer) == false {
                view.layer.insertSublayer(layer, at: 0)
            }
        }
    }
    
    private func removePlayer() {
        player?.pause()
        player = nil
        
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
    
    private func observeAppEvent() {
        notificationCenter.publisher(for: .AVPlayerItemDidPlayToEndTime).sink { [weak self] _ in
            print("Video has ended...")
            self?.restartVideo()
        }.store(in: &appEventSubscribers)
        
        // Notification is being called when the app goes into background
        notificationCenter.publisher(for: UIApplication.willResignActiveNotification).sink { [weak self] (_) in
            self?.pauseVideo()
        }.store(in: &appEventSubscribers)
        
        // Notification is being called when the app come back in foreground
        notificationCenter.publisher(for: UIApplication.didBecomeActiveNotification).sink { [weak self] (_) in
            self?.playVideo()
        }.store(in: &appEventSubscribers)
        
    }
    
    private func removeAppEventSubscribers() {
        appEventSubscribers.forEach { (subscriber) in
            subscriber.cancel()
        }
    }
    
    
}

