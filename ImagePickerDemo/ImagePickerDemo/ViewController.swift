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
    
    @IBAction func showSwiftUIView(_ sender: Any) {
        print("jpjpjp 敬请期待")
    }
}

extension ViewController {
    func reset() {
        videoURL = nil
        
        imgHeight.constant = imgWidth.constant
        UIView.animate(withDuration: 0.35) {
            self.view.layoutIfNeeded()
        }
        
        UIView.animate(withDuration: 0.2) {
            self.titleLabel.alpha = 1
            self.playBtn.alpha = 0
        }
        
        UIView.transition(with: imgView, duration: 0.2, options: .transitionCrossDissolve) {
            self.imgView.image = nil
        }
    }
    
    func setupImage(_ image: UIImage) {
        videoURL = nil
        
        let imgRatio = image.size.height / image.size.width
        imgHeight.constant = imgWidth.constant * imgRatio
        if imgHeight.constant > 600 {
            imgHeight.constant = 600
        }
        UIView.animate(withDuration: 0.35) {
            self.view.layoutIfNeeded()
        }
        
        UIView.animate(withDuration: 0.2) {
            self.titleLabel.alpha = 0
            self.playBtn.alpha = 0
        }
        
        UIView.transition(with: imgView, duration: 0.2, options: .transitionCrossDissolve) {
            self.imgView.image = image
        }
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
        
        let imgRatio = image.size.height / image.size.width
        imgHeight.constant = imgWidth.constant * imgRatio
        if imgHeight.constant > 600 {
            imgHeight.constant = 600
        }
        UIView.animate(withDuration: 0.35) {
            self.view.layoutIfNeeded()
        }
        
        UIView.animate(withDuration: 0.2) {
            self.titleLabel.alpha = 0
            self.playBtn.alpha = 1
        }
        
        UIView.transition(with: imgView, duration: 0.2, options: .transitionCrossDissolve) {
            self.imgView.image = image
        }
    }
}
