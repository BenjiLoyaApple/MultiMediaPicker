//
//  OnePhotoPicker.swift
//  PhotoVideoPicker
//
//  Created by Benji Loya on 02.05.2024.
//

import SwiftUI
import PhotosUI

@MainActor
final class OnePhotoPickerViewModel: ObservableObject {
    
    //MARK: - One Photo
    @Published private(set) var selectedImage: UIImage? = nil
    @Published var imageSelection: PhotosPickerItem? = nil {
        didSet {
            setImage(from: imageSelection)
        }
    }
    
    private func setImage(from selection: PhotosPickerItem?) {
        guard let selection else { return }
        
        Task {
            do {
                let data = try await selection.loadTransferable(type: Data.self)
                
                guard let data, let uiImage = UIImage(data: data) else {
                    throw URLError(.badServerResponse)
                }
                
                selectedImage = uiImage
            } catch {
                print(error)
            }
        }
    }
}
 

// MARK: View
    struct OnePhotoPickerView: View {
        
        @StateObject private var viewModel = OnePhotoPickerViewModel()
        
        var body: some View {
            NavigationStack {
                VStack(spacing: 0) {
                    
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    PhotosPicker(
                        selection: $viewModel.imageSelection,
                        matching: .images,
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
    }
    
#Preview {
    OnePhotoPickerView()
}
