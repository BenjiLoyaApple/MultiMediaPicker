//
//  PreferPro.swift
//  MultiMediaPicker
//
//  Created by Benji Loya on 11.06.2024.
//

import SwiftUI
import PhotosUI
import AVKit

// MARK: - MediaItem
struct MediaItem: Identifiable {
    enum MediaType {
        case image(UIImage)
        case video(URL)
    }
    
    let id = UUID()
    let type: MediaType
}

// MARK: - MediaPickerViewModel
@MainActor
class MediaPickerViewModel: ObservableObject {
    
    @Published var isVideoProcessing: Bool = false
    @Published private(set) var mediaItems: [MediaItem] = []
    @Published var mediaSelections: [PhotosPickerItem] = []

    func setMedia() {
        Task {
            do {
                isVideoProcessing = true
                var mediaItems: [MediaItem] = []
                
                for item in mediaSelections {
                    do {
                        if let pickedMovie = try await item.loadTransferable(type: VideoPickerTransferable.self) {
                            mediaItems.append(MediaItem(type: .video(pickedMovie.videoURL)))
                        } else if let pickedImage = try await item.loadTransferable(type: ImagePickerTransferable.self) {
                            mediaItems.append(MediaItem(type: .image(pickedImage.image)))
                        }
                    } catch {
                        print("Failed to load media item: \(error.localizedDescription)")
                    }
                }
                self.mediaItems = mediaItems
            } catch {
                print("Failed to set media: \(error.localizedDescription)")
            }
            isVideoProcessing = false
        }
    }
    
    func deleteMediaItem(at index: Int, currentVisibleIndex: inout Int) {
        guard index >= 0 && index < mediaItems.count else { return }
        mediaItems.remove(at: index)
        if currentVisibleIndex >= mediaItems.count {
            currentVisibleIndex = max(mediaItems.count - 1, 0)
        }
    }
}

// MARK: - NativeMediaPicker
struct NativeMediaPicker: View {
    @StateObject private var viewModel = MediaPickerViewModel()
    @State private var currentVisibleIndex: Int = 0
    @State private var isMuted: Bool = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if !viewModel.mediaItems.isEmpty {
                    mediaCarousel
                }

                Spacer(minLength: 0)

                mediaPickerControls
            }
            .padding(.horizontal)
            .navigationTitle("Media Picker")
            .onChange(of: viewModel.mediaSelections) { oldValue, newValue in
                viewModel.setMedia()
            }
            .onPreferenceChange(VisibleIndexKey.self) { index in
                guard let index = index else { return }
                currentVisibleIndex = index
            }
        }
    }

    private var mediaCarousel: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(viewModel.mediaItems.indices, id: \.self) { index in
                        let mediaItem = viewModel.mediaItems[index]
                        MediaItemCard(
                            mediaItem: mediaItem,
                            size: geometry.size,
                            index: index,
                            onDelete: {
                                viewModel.deleteMediaItem(at: index, currentVisibleIndex: &currentVisibleIndex)
                            },
                            currentVisibleIndex: $currentVisibleIndex,
                            isPlaying: .constant(currentVisibleIndex == index),
                            isMuted: $isMuted
                        )
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
        .frame(height: 200)
    }

    private var mediaPickerControls: some View {
        HStack(spacing: 15) {
            PhotosPicker(
                selection: $viewModel.mediaSelections,
                maxSelectionCount: 10,
                selectionBehavior: .continuous,
                matching: .any(of: [.images, .videos]),
                preferredItemEncoding: .current,
                photoLibrary: .shared()
            ) {
                Image(systemName: "photo.on.rectangle.angled")
                    .padding(10)
                    .background(.black.opacity(0.001))
                    .clipShape(Circle())
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
}

// MARK: - MediaItemCard
struct MediaItemCard: View {
    let mediaItem: MediaItem
    let size: CGSize
    let index: Int
    let onDelete: () -> Void
    @Binding var currentVisibleIndex: Int
    @Binding var isPlaying: Bool
    @Binding var isMuted: Bool
    @State private var isLoading: Bool = true

    var body: some View {
        ZStack {
            switch mediaItem.type {
            case .image(let image):
                imageView(image)
            case .video(let videoURL):
                videoView(videoURL)
            }
        }
        .frame(width: size.width * 0.45, height: size.height)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(deleteButton, alignment: .topTrailing)
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: VisibleIndexKey.self, value: geo.frame(in: .global).midX < size.width / 2 ? index : nil)
            }
        )
        .onChange(of: currentVisibleIndex) { oldValue, newValue in
            isPlaying = newValue == index
        }
    }

    private func imageView(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
    }

    private func videoView(_ videoURL: URL) -> some View {
        VideoPlayerCustom(
            mediaURL: videoURL,
            isMuted: $isMuted,
            isPlaying: $isPlaying,
            isLoading: $isLoading
        )
        .overlay(muteButton, alignment: .bottomTrailing)
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.white, .black.opacity(0.4))
                .padding(8)
                .background(Color.black.opacity(0.001))
        }
    }

    private var muteButton: some View {
        Button(action: {
            withAnimation(.bouncy) {
                isMuted.toggle()
            }
        }) {
            Image(systemName: isMuted ? "speaker.slash.circle.fill" : "speaker.circle.fill")
                .font(.title3)
                .foregroundStyle(.white, .black.opacity(0.4))
                .padding(8)
                .background(Color.black.opacity(0.001))
                .clipShape(Circle())
        }
        .padding(5)
    }
}

// MARK: - Error
enum TransferError: Error {
   case couldNotLoadData
}

// MARK: - Transferable
struct ImagePickerTransferable: Transferable {
   let image: UIImage
    
   static var transferRepresentation: some TransferRepresentation {
       DataRepresentation(importedContentType: .image) { data in
           // Создаем изображение из данных
           guard let uiImage = UIImage(data: data) else {
               throw TransferError.couldNotLoadData
           }
           return .init(image: uiImage)
       }
   }
}

struct VideoPickerTransferable: Transferable {
    let videoURL: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { exportingFile in
            return .init(exportingFile.videoURL)
        } importing: { ReceivedTransferredFile in
            let originalFile = ReceivedTransferredFile.file
            let uniqueName = UUID().uuidString
            let copiedFile = URL.documentsDirectory.appendingPathComponent(uniqueName + ".mov")
            try FileManager.default.copyItem(at: originalFile, to: copiedFile)
            return .init(videoURL: copiedFile)
        }
    }
}

// MARK: - Prefernce Key
struct VisibleIndexKey: PreferenceKey {
static var defaultValue: Int? = nil

    static func reduce(value: inout Int?, nextValue: () -> Int?) {
        value = nextValue() ?? value
    }
}

// MARK: - Preview
#Preview {
NativeMediaPicker()
}
