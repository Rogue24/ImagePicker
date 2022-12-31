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

从[Swift中的async/await代码实例详解](https://juejin.cn/post/7169914508360548360#heading-9)这篇文章中得知，可以通过`withCheckedThrowingContinuation`将【基于闭包返回】转换成【结构化并发返回】，实现一句代码获取系统相册照片：
```swift
func getPhoto() async {
    let image: UIImage? = try? await ImagePicker.openAlbum()
    imgView.image = image
}
```
这样看上去就真的超简洁了~

这其中需要解决的问题是：由于`UIImagePickerController`是通过代理方法返回结果的（用户点击才触发），也就是在代码层面上压根不知道这个代理方法何时会被调用，于是我通过**对子线程加锁**的方式来等待代理方法的触发，从而实现“同步”结果返回：
```swift
// MARK: - Pick object handle
private extension ImagePicker.Controller {
    // 通过`withCheckedThrowingContinuation`将【基于闭包返回】转换成【结构化并发返回】，
    // 外部调用是这样的：let object: T = await ImagePicker.pickObject()
    func pickObject() async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            pickObject() { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // 以前的做法：保存闭包，然后在代理方法中调用闭包返回结果。
    // 现在改成：开启一个子线程等待代理方法的触发，然后在代理方法中获取结果、解锁。
    func pickObject(completion: @escaping ImagePicker.Completion<T>) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(.failure(.userCancel))
                }
                return
            }
            
            // 加锁，等待代理方法的触发
            self.tryLock()
            
            // 来到这里就是已经获取结果or用户点击取消，
            // 回到主线程将结果抛出。
            DispatchQueue.main.async {
                completion(self.result ?? .failure(.userCancel))
            }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    // 用户选择了照片/视频
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // 获取结果
        do {
            result = .success(try T.fetchFromPicker(info))
        } catch let pickError as ImagePicker.PickError {
            result = .failure(pickError)
        } catch {
            result = .failure(.other(error))
        }
        
        // 解锁，抛出结果
        tryUnlock()
        
        // 关闭控制器
        dismiss(animated: true)
    }
    
    // 用户点击了取消
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // 解锁
        tryUnlock()
        
        // 关闭控制器
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

至此，封装的`ImagePicker`可以很方便地让我获取系统相册的照片和视频，虽然说通过**卡住子线程**这种做法不安全，也不建议，不过呢这种场景也不会使用很频繁，个人觉得还能接受，并且这个工具类更多的只是用来平时的调试，正式项目中我也不会用到，主要是熟悉一下`async/await`的特性。

That's all, thanks.
