//
//  ViewController.swift
//  ImagePickerDemo
//
//  Created by aa on 2022/12/29.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var imgWidth: NSLayoutConstraint!
    @IBOutlet weak var imgHeight: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    var videoURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imgView.layer.cornerRadius = 20
        imgView.layer.masksToBounds = true
        imgWidth.constant = UIScreen.main.bounds.width - 32
        imgHeight.constant = imgWidth.constant
        playBtn.alpha = 0
    }

    @IBAction func photograph() {
        // 基于闭包异步处理结果
//        ImagePicker.photograph { [weak self] result in
//            guard let self = self else { return }
//            switch result {
//            case let .success(image):
//                self.setupImage(image)
//            case let .failure(pickError):
//                pickError.log()
//            }
//        }
        
        // 结构化并发同步处理结果
        Task {
            do {
                let image = try await ImagePicker.photograph()
                await MainActor.run {
                    setupImage(image)
                }
            } catch let pickError as ImagePicker.PickError {
                pickError.log()
            }
        }
    }
    
    @IBAction func openAlbum() {
        // 基于闭包异步处理结果
//        ImagePicker.openAlbumForObject { [weak self] result in
//            guard let self = self else { return }
//            switch result {
//            case let .success(object):
//                if let imageData = object.imageData, let image = UIImage(data: imageData) {
//                    self.setupImage(image)
//                } else if let videoURL = object.videoURL {
//                    self.setupVideo(videoURL)
//                } else {
//                    self.reset()
//                }
//            case let .failure(pickError):
//                pickError.log()
//            }
//        }
        
        // 结构化并发同步处理结果
        Task {
            do {
                let object: AlbumObject = try await ImagePicker.openAlbum()
                await MainActor.run {
                    if let imageData = object.imageData, let image = UIImage(data: imageData) {
                        setupImage(image)
                    } else if let videoURL = object.videoURL {
                        setupVideo(videoURL)
                    } else {
                        reset()
                    }
                }
            } catch let pickError as ImagePicker.PickError {
                pickError.log()
            }
        }
    }
    
    @IBAction func playVideo(_ sender: Any) {
        guard let videoURL = self.videoURL else { return }
        let playerVC = AVPlayerViewController()
        playerVC.player = AVPlayer(url: videoURL)
        present(playerVC, animated: true) {
            playerVC.player?.play()
        }
    }
}

extension ViewController {
    func reset() {
        videoURL = nil
        updateUI(titleLabelAlpha: 1, playBtnAlpha: 0, image: nil)
    }
    
    func setupImage(_ image: UIImage) {
        videoURL = nil
        updateUI(titleLabelAlpha: 0, playBtnAlpha: 0, image: image)
    }
    
    func setupVideo(_ videoURL: URL) {
        self.videoURL = videoURL
        
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.maximumSize = CGSize(width: 1000, height: 1000)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero
        let cgImage = try! generator.copyCGImage(at: .zero, actualTime: nil)
        let image = UIImage(cgImage: cgImage)
        
        updateUI(titleLabelAlpha: 0, playBtnAlpha: 1, image: image)
    }
    
    func updateUI(titleLabelAlpha: CGFloat, playBtnAlpha: CGFloat, image: UIImage?) {
        UIView.animate(withDuration: 0.15) {
            self.titleLabel.alpha = titleLabelAlpha
            self.playBtn.alpha = playBtnAlpha
        }
        
        UIView.transition(with: imgView, duration: 0.15, options: .transitionCrossDissolve) {
            self.imgView.image = image
        }
        
        imgHeight.constant = self.imgWidth.constant
        if let image = image {
            imgHeight.constant *= (image.size.height / image.size.width)
            if imgHeight.constant > 600 { imgHeight.constant = 600 }
        }
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0) {
            self.view.layoutIfNeeded()
        }
    }
}
