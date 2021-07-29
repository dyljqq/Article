# iOS中的图片

首先我们加载到内存中的图片大小，跟图片的格式没啥关系，他是一个位图，大小为width * height * 4(RGBA)。

只有当imageView.image = image的操作发生，且imageView在当前视图中，我们才会对图片进行解码。为什么需要解码，也是因为我们将图片显示在屏幕上的时候，需要知道所有的信息。而像png（无损压缩），jpeg（有损压缩）。

但是我们知道解码过程非常消耗资源，因此我们可以通过异步的方式进行解码，并将结果在主线程中返回给imageView。

正常的展示图片的流程如下:

	Load(UIImage) -> Decode -> Render(UIImageView)
	
其中我们把UIImage看成是Model,Decode看成是controller，UIImageView就是View，标准的MVC有没有。但是这种解码流程非常的消耗CPU，因此在wwdc中使用了一种下采样的技术，对这种流程进行了优化，如下:

	Load(CGImageSource) -> Thumbnail -> Decode -> UIImage -> Render(UIImageView)
	
即我们在非主线程对image进行解码的操作，然后在主线程中将结果渲染到UIImageview中。

在KingFIsher中有对下采样的代码进行实现:

	 public static func downsampledImage(data: Data, to pointSize: CGSize, scale: CGFloat) -> KFCrossPlatformImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return nil
        }
        
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        return KingfisherWrapper.image(cgImage: downsampledImage, scale: scale, refImage: nil)
    }
    
   这样我们在使用时，配合GCD就可以完成图片的解码与赋值，以达到降低内存与加快图片渲染的目的了。

	