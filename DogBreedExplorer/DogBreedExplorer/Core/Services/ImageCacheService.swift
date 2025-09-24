import Foundation
import UIKit
import SwiftUI

// MARK: - Image Cache Protocol

protocol ImageCacheProtocol {
    func image(for url: String) -> UIImage?
    func setImage(_ image: UIImage, for url: String)
    func removeImage(for url: String)
    func clearCache()
}

// MARK: - Image Cache Implementation

final class ImageCacheService: ImageCacheProtocol {
    static let shared = ImageCacheService()
    
    private let cache = NSCache<NSString, UIImage>()
    private let cacheQueue = DispatchQueue(label: "ImageCacheQueue", qos: .utility)
    
    private init() {
        // Configure cache limits
        cache.countLimit = 100 // Maximum 100 images
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func image(for url: String) -> UIImage? {
        return cache.object(forKey: NSString(string: url))
    }
    
    func setImage(_ image: UIImage, for url: String) {
        let cost = image.pngData()?.count ?? 0
        cache.setObject(image, forKey: NSString(string: url), cost: cost)
    }
    
    func removeImage(for url: String) {
        cache.removeObject(forKey: NSString(string: url))
    }
    
    @objc func clearCache() {
        cache.removeAllObjects()
    }
}

// MARK: - Cached AsyncImage

struct CachedAsyncImage<Content: View>: View {
    private let url: URL?
    private let content: (AsyncImagePhase) -> Content
    
    @State private var phase: AsyncImagePhase = .empty
    
    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }
    
    var body: some View {
        content(phase)
            .onAppear {
                loadImage()
            }
            .onChange(of: url) { _ in
                loadImage()
            }
    }
    
    private func loadImage() {
        guard let url = url else {
            phase = .empty
            return
        }
        
        let urlString = url.absoluteString
        
        // Check cache first
        if let cachedImage = ImageCacheService.shared.image(for: urlString) {
            phase = .success(Image(uiImage: cachedImage))
            return
        }
        
        // Start loading
        phase = .empty
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                await MainActor.run {
                    if let uiImage = UIImage(data: data) {
                        // Cache the image
                        ImageCacheService.shared.setImage(uiImage, for: urlString)
                        phase = .success(Image(uiImage: uiImage))
                    } else {
                        phase = .failure(URLError(.badServerResponse))
                    }
                }
            } catch {
                await MainActor.run {
                    phase = .failure(error)
                }
            }
        }
    }
}

// MARK: - Convenience Initializers

extension CachedAsyncImage {
    
    init(url: URL?) where Content == AnyView {
        self.init(url: url) { phase in
            AnyView(
                Group {
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        Text("Failed to load")
                            .foregroundColor(.secondary)
                    case .empty:
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
            )
        }
    }
}
