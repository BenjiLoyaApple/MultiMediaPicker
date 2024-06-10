//
//  NativeVideoPicker.swift
//  PhotoVideoPicker
//
//  Created by Benji Loya on 02.05.2024.
//

import SwiftUI
import PhotosUI
import AVKit

class OneVideoPickerViewModel: ObservableObject {
    @Published var pickedVideoURL: URL?
    @Published var isVideoProcessing: Bool = false
    @Published var selectedItem: PhotosPickerItem?
    
    func extractVideoURL() {
        guard let selectedItem = selectedItem else { return }
        Task {
            do {
                isVideoProcessing = true
                let pickedMovie = try await selectedItem.loadTransferable(type: OneVideoPickerTransferable.self)
                isVideoProcessing = false
                pickedVideoURL = pickedMovie?.videoURL
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func deletePickedVideo() {
        guard let videoURL = pickedVideoURL else { return }
        do {
            try FileManager.default.removeItem(at: videoURL)
            pickedVideoURL = nil
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct OneVideoPicker: View {
    @StateObject private var viewModel = OneVideoPickerViewModel()
    @State private var showVideoPicker: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    if let pickedVideoURL = viewModel.pickedVideoURL {
                        VideoPlayer(player: .init(url: pickedVideoURL))
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    
                    if viewModel.isVideoProcessing {
                        ProgressView()
                    }
                }
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                
                HStack(spacing: 15) {
                    Button("Pick Video") {
                        showVideoPicker.toggle()
                    }
                    
                    Button("Remove Picked Video") {
                        viewModel.deletePickedVideo()
                    }
                }
                .padding(.top, 5)
            }
            .navigationTitle("Native Video Picker")
            .photosPicker(
                isPresented: $showVideoPicker,
                selection: $viewModel.selectedItem,
                matching: .videos
            )
            .padding()
            .onChange(of: viewModel.selectedItem) { oldValue, newValue in
                viewModel.extractVideoURL()
            }
        }
    }
}

struct OneVideoPicker_Previews: PreviewProvider {
    static var previews: some View {
        OneVideoPicker()
    }
}

/// Custom Transferable for Video Picker
struct OneVideoPickerTransferable: Transferable {
    let videoURL: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { exportingFile in
            return .init(exportingFile.videoURL)
        } importing: { ReceivedTransferredFile in
            let originalFile = ReceivedTransferredFile.file
            let copiedFile = URL.documentsDirectory.appending(path: "videoPicker.mov")
            if FileManager.default.fileExists(atPath: copiedFile.path()) {
                try FileManager.default.removeItem(at: copiedFile)
            }
            try FileManager.default.copyItem(at: originalFile, to: copiedFile)
            return .init(videoURL: copiedFile)
        }
    }
}
