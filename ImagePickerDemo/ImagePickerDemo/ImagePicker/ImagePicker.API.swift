//
//  ImagePicker.API.swift
//  ImagePickerDemo
//
//  Created by aa on 2022/12/31.
//

import UIKit

extension ImagePicker {
    // MARK: - Open album -> 图片
    /// async/await
    static func openAlbum() async throws -> UIImage {
        try await ImagePicker.Controller<UIImage>.openAlbum(.photo)
    }
    /// closure
    static func openAlbum(completion: @escaping ImagePicker.Completion<UIImage>) {
        ImagePicker.Controller<UIImage>.openAlbum(.photo, completion: completion)
    }
    
    // MARK: - Open album -> 图片/GIF数据
    /// async/await
    static func openAlbum() async throws -> Data {
        try await ImagePicker.Controller<Data>.openAlbum(.photo)
    }
    /// closure
    static func openAlbum(completion: @escaping ImagePicker.Completion<Data>) {
        ImagePicker.Controller<Data>.openAlbum(.photo, completion: completion)
    }
    
    // MARK: - Open album -> 视频路径
    /// async/await
    static func openAlbum() async throws -> URL {
        try await ImagePicker.Controller<URL>.openAlbum(.video)
    }
    /// closure
    static func openAlbum(completion: @escaping ImagePicker.Completion<URL>) {
        ImagePicker.Controller<URL>.openAlbum(.video, completion: completion)
    }
    
    // MARK: - Open album -> 图片/GIF数据 or 视频路径
    /// async/await
    static func openAlbum() async throws -> AlbumObject {
        try await ImagePicker.Controller<AlbumObject>.openAlbum(.all)
    }
    /// closure
    static func openAlbum(completion: @escaping ImagePicker.Completion<AlbumObject>) {
        ImagePicker.Controller<AlbumObject>.openAlbum(.all, completion: completion)
    }
    
    
    // MARK: - Photograph -> 图片
    /// async/await
    static func photograph() async throws -> UIImage {
        try await ImagePicker.Controller<UIImage>.photograph()
    }
    /// closure
    static func photograph(completion: @escaping ImagePicker.Completion<UIImage>) {
        ImagePicker.Controller<UIImage>.photograph(completion: completion)
    }
    
}
