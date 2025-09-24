import SwiftUI

struct BreedListView: View {
    @StateObject private var viewModel = BreedListViewModel()
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Dog Breeds")
                .task {
                    if case .idle = viewModel.state {
                        viewModel.loadBreeds()
                    }
                }
                .refreshable {
                    viewModel.refresh()
                }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            loadingView
            
        case .loading:
            loadingView
            
        case .loaded(_):
            breedsList
            
        case .error(_):
            errorView
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading breeds...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var breedsList: some View {
        List(viewModel.state.breeds) { breed in
            NavigationLink(destination: BreedDetailView(breed: breed)) {
                BreedListItemView(breed: breed)
            }
        }
        .listStyle(.plain)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Oops!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(viewModel.state.errorMessage ?? "Something went wrong")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Try Again") {
                viewModel.retryLoading()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Breed List Item View

struct BreedListItemView: View {
    let breed: Breed
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(breed.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if breed.hasSubBreeds {
                    Text("\(breed.subBreedsCount) sub-breed\(breed.subBreedsCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("No sub-breeds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if breed.hasSubBreeds {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Previews

#Preview("List - Loading") {
    BreedListView()
        .environmentObject(BreedListViewModel.previewLoading)
}

#Preview("List - Loaded") {
    BreedListView()
        .environmentObject(BreedListViewModel.previewLoaded)
}

#Preview("List - Error") {
    BreedListView()
        .environmentObject(BreedListViewModel.previewError)
}

#Preview("List Item - With Sub-breeds") {
    List {
        BreedListItemView(breed: MockData.breeds.first { $0.hasSubBreeds }!)
        BreedListItemView(breed: MockData.breeds.first { !$0.hasSubBreeds }!)
    }
}
