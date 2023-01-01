# ImagePicker

众所周知，想要获取系统相册照片和视频，也就是调起`UIImagePickerController`，创建控制器、遵守代理、实现代理方法、弹出/关闭控制器，拿张照片都如此繁琐。为了更快获取系统相册照片和视频，于是封装了一个系统相册的工具类`ImagePicker`，内部实现好代理和弹出/关闭的操作，方便自己平时调试。

- 🌰`ImagePicker`封装的方法其一：打开相册，通过闭包返回照片图片：
```swift
func getPhoto() {
    ImagePicker.openAlbumForImage { [weak self] result in
        guard let self = self else { return }
        switch result {
        case let .success(image):
            self.setupImage(image)
        case let .failure(pickError):
            pickError.log()
        }
    }
}
```

这么一看好像已经够简洁了，不过`Swift`现在已经有`async/await`的特性了，那是不是可以通过一句代码就能获取到图片呢？

答案是**肯定可以**的啦。

从[Swift中的async/await代码实例详解](https://juejin.cn/post/7169914508360548360#heading-9)这篇文章中得知，可以通过`withCheckedThrowingContinuation`将【基于闭包异步处理结果】转换成【结构化并发同步处理结果】，实现一句代码获取系统相册照片：
```swift
func getPhoto() async {
    let image: UIImage? = try? await ImagePicker.openAlbum()
    imgView.image = image
}
```
这样看上去就真的超简洁了~

- 主要实现方式：
```swift
// MARK: - Pick object handle
private extension ImagePicker.Controller {
    // 以前的方式：
    // - 保存闭包，直至代理方法的调起，然后通过该闭包以返回结果
    // - 外部调用：picker.pickObject() { result in ...... }，通过闭包异步获取结果
    func pickObject(completion: @escaping ImagePicker.Completion<T>) {
        self.completion = completion
    }
    
    // 现在的方式：
    // - 通过`withCheckedThrowingContinuation`将【基于闭包异步处理结果】转换成【结构化并发同步处理结果】
    // - 外部调用：let object: T? = try? await picker.pickObject()，等待并同步获取结果
    func pickObject() async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            // 修改以前闭包的实现：将[在代理方法中返回的结果]通过`continuation`实现外部同步返回
            pickObject() { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    // 用户选择了照片/视频
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // 1.获取结果
        let result: Result<T, ImagePicker.PickError>
        do {
            result = .success(try T.fetchFromPicker(info))
        } catch let pickError as ImagePicker.PickError {
            result = .failure(pickError)
        } catch {
            result = .failure(.other(error))
        }
        
        // 2.返回结果
        completion?(result)
        
        // 3.关闭控制器
        dismiss(animated: true)
    }
    
    // 用户点击了取消
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // 1.返回结果：用户点击取消
        completion?(.failure(.userCancel))
        
        // 2.关闭控制器
        dismiss(animated: true)
    }
}
```

- 通过泛型和重载的特性扩展一下，返回更多类型：
```swift
// 相册 -> 图片
let image: UIImage? = try? await ImagePicker.openAlbum()

// 相册 -> 二进制数据（图片、GIF）
let imageData: Data? = try? await ImagePicker.openAlbum()

// 相册 -> 视频路径
let videoURL: URL? = try? await ImagePicker.openAlbum()

// 拍照 -> 图片
let image: UIImage? = try? await ImagePicker.photograph()
```
PS：当然啦，肯定会有拿不到的情况，所有失败的场景我都使用了`ImagePicker.PickError`抛出，可通过`do {} catch {}`捕获。

至此，封装的`ImagePicker`可以很方便地让我获取系统相册的照片和视频。
不过获取相册数据一般都会用第三方库来做，我这个工具类只是更多的用来平时的调试，最主要是熟悉一下`async/await`的特性。

That's all, thanks.
