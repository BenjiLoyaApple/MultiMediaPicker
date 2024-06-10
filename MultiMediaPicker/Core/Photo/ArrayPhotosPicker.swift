//
//  ArrayPhotosPicker.swift
//  PhotoVideoPicker
//
//  Created by Benji Loya on 02.05.2024.
//

import SwiftUI
import PhotosUI

enum PhotoPickerError: Error {
    case emptyImage
}

@MainActor
final class ArrayPhotoPickerViewModel: ObservableObject {

    @Published private(set) var selectedImages: [UIImage] = []
    @Published var imageSelections: [PhotosPickerItem] = [] {
        didSet {
            setImages(from: imageSelections)
        }
    }

    private func setImages(from selections: [PhotosPickerItem]) {
        Task {
            var images: [UIImage] = []
            // Load transferables for all selections
       //     loadTransferables(from: selections)
            for selection in selections {
                if let data = try? await selection.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        images.append(uiImage)
                    }
                }
            }
            selectedImages = images
        }
    }

    // Call this method to load transferables for multiple items
//    func loadTransferables(from selections: [PhotosPickerItem]) {
//        for selection in selections {
//            let _ = loadTransferable(from: selection, completion: <#(Result<UIImage, any Error>) -> Void#>)
//        }
//    }
//    
//    func loadTransferable(from imageSelections: PhotosPickerItem, completion: @escaping (Result<UIImage, Error>) -> Void) -> Progress {
//        return imageSelections.loadTransferable(type: Image.self) { result in
//            DispatchQueue.main.async {
//                guard self.imageSelections.contains(imageSelections) else { return }
//                switch result {
//                case .success(let image?):
//                    completion(.success(image))
//                case .success(nil):
//                    completion(.failure(PhotoPickerError.emptyImage))
//                case .failure(let error):
//                    completion(.failure(error))
//                }
//            }
//        }
//    }

        
       
    
}

// MARK: View
struct ArrayPhotoPickerView: View {
    
    @StateObject private var viewModel = ArrayPhotoPickerViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ImageList(viewModel: viewModel)
                
                Spacer()
                
                PhotosPicker(
                    selection: $viewModel.imageSelections,
                    maxSelectionCount: 10,
                    selectionBehavior: .continuous,
                    
//                    matching: .images,
                    matching: .any(of: [.images, .videos]),
                    preferredItemEncoding: .current,
                    photoLibrary: .shared()
                ) {
                    Text("Select Photos")
                }
                    .photosPickerStyle(.inline)
                // .photosPickerStyle(.compact)
                    .ignoresSafeArea()
                    .photosPickerDisabledCapabilities(.selectionActions)
                    .photosPickerAccessoryVisibility(.hidden, edges: .all)
                    .frame(height: 200)
                
            }
            .navigationTitle("Photos")
            .ignoresSafeArea(.keyboard)
        }
    }
    
    struct ImageList: View {
        
        @ObservedObject var viewModel: ArrayPhotoPickerViewModel
        
        var body: some View {
            if !viewModel.selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.selectedImages, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ArrayPhotoPickerView()
}








/*
import SwiftUI
import PhotosUI

@MainActor
final class ArrayPhotoPickerViewModel: ObservableObject {

    @Published private(set) var selectedImages: [UIImage] = []
    @Published var imageSelections: [PhotosPickerItem] = [] {
        didSet {
            setImages(from: imageSelections)
        }
    }

    private func setImages(from selections: [PhotosPickerItem]) {
        Task {
            var images: [UIImage] = []
            for selection in selections {
                if let data = try? await selection.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        images.append(uiImage)
                    }
                }
            }
            
            selectedImages = images
        }
    }
    
}

// MARK: View
struct ArrayPhotoPickerView: View {
    
    @StateObject private var viewModel = ArrayPhotoPickerViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ImageList(viewModel: viewModel)
                
                Spacer()
                
                PhotosPicker(
                    selection: $viewModel.imageSelections,
                    maxSelectionCount: 10,
                    selectionBehavior: .continuous,
                    
//                    matching: .images,
                    matching: .any(of: [.images, .videos]),
                    preferredItemEncoding: .current,
                    photoLibrary: .shared()
                ) {
                    Text("Select Photos")
                }
                    .photosPickerStyle(.inline)
                // .photosPickerStyle(.compact)
                    .ignoresSafeArea()
                    .photosPickerDisabledCapabilities(.selectionActions)
                    .photosPickerAccessoryVisibility(.hidden, edges: .all)
                    .frame(height: 200)
                
            }
            .navigationTitle("Photos")
            .ignoresSafeArea(.keyboard)
        }
    }
    
    struct ImageList: View {
        
        @ObservedObject var viewModel: ArrayPhotoPickerViewModel
        
        var body: some View {
            if !viewModel.selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.selectedImages, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ArrayPhotoPickerView()
}
*/
