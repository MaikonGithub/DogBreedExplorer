import SwiftUI

struct BreedDetailView: View {
    let breed: Breed
    @StateObject private var viewModel: BreedDetailViewModel
    
    init(breed: Breed) {
        self.breed = breed
        self._viewModel = StateObject(wrappedValue: BreedDetailViewModel(breed: breed))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                breedInfoSection
                contentView
            }
            .padding()
        }
        .navigationTitle(viewModel.breedDisplayName)
        .navigationBarTitleDisplayMode(.large)
        .task {
            if case .idle = viewModel.state {
                viewModel.loadImages()
            }
        }
        .refreshable {
            viewModel.refresh()
        }
    }
    
    private var breedInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Breed Information")
                .font(.title2)
                .fontWeight(.semibold)
            
            if viewModel.hasSubBreeds {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sub-breeds (\(viewModel.subBreedsCount))")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100), spacing: 8)
                    ], spacing: 8) {
                        ForEach(viewModel.subBreeds, id: \.self) { subBreed in
                            Text(subBreed.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(16)
                        }
                    }
                }
            } else {
                Text("This breed has no recognized sub-breeds.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Photos")
                .font(.title2)
                .fontWeight(.semibold)
            
            switch viewModel.state {
            case .idle:
                EmptyView()
                
            case .loading:
                loadingView
                
            case .loaded(_):
                imagesGrid
                
            case .error(_):
                errorView
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading images...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    private var imagesGrid: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let padding: CGFloat = 16
            let spacing: CGFloat = 8
            let availableWidth = screenWidth - (padding * 2) - spacing
            let itemSize = availableWidth / 2
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: spacing),
                GridItem(.flexible(), spacing: spacing)
            ], spacing: spacing) {
                ForEach(viewModel.state.images) { image in
                    BreedImageView(image: image, size: itemSize)
                }
            }
            .padding(.horizontal, padding)
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Unable to load images")
                .font(.headline)
            
            Text(viewModel.state.errorMessage ?? "Something went wrong")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Try Again") {
                viewModel.retryLoading()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .padding()
    }
}

// MARK: - Breed Image View

struct BreedImageView: View {
    let image: BreedImage
    let size: CGFloat
    
    var body: some View {
        CachedAsyncImage(url: image.imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
            case .failure(_):
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: size, height: size)
                    .overlay {
                        VStack(spacing: 4) {
                            Image(systemName: "photo.badge.exclamationmark")
                                .font(.title3)
                                .foregroundColor(.gray)
                            Text("Failed")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
            case .empty:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: size, height: size)
                    .overlay {
                        ProgressView()
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
            @unknown default:
                EmptyView()
            }
        }
    }
}

// MARK: - Previews

#Preview("Detail - Loading") {
    NavigationStack {
        BreedDetailView(breed: MockData.breeds.first!)
    }
    .environmentObject(BreedDetailViewModel.previewLoading)
}

#Preview("Detail - Loaded") {
    NavigationStack {
        BreedDetailView(breed: MockData.breeds.first!)
    }
    .environmentObject(BreedDetailViewModel.previewLoaded)
}

#Preview("Detail - With Sub-breeds") {
    NavigationStack {
        BreedDetailView(breed: MockData.breeds.first { $0.hasSubBreeds }!)
    }
    .environmentObject(BreedDetailViewModel.previewWithSubBreeds)
}

#Preview("Detail - Error") {
    NavigationStack {
        BreedDetailView(breed: MockData.breeds.first!)
    }
    .environmentObject(BreedDetailViewModel.previewError)
}

#Preview("Breed Image View") {
    HStack {
        BreedImageView(image: MockData.images(for: "labrador", count: 1).first!, size: 120)
        BreedImageView(image: MockData.images(for: "beagle", count: 1).first!, size: 120)
    }
    .padding()
}
