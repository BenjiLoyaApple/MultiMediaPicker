//
//  ArrayVideosPicker.swift
//  PhotoVideoPicker
//
//  Created by Benji Loya on 02.05.2024.
//

import SwiftUI
import PhotosUI
import AVKit

class ArrayVideoPickerViewModel: ObservableObject {
    @Published var selectedItems: [PhotosPickerItem] = []
    @Published var selectedVideoURLs: [URL] = []

    @Published var showPicker: Bool = false
    @Published var isVideoProcessing: Bool = false
    
    func setVideos() {
          guard !selectedItems.isEmpty else { return }
          
          Task {
              do {
                  isVideoProcessing = true
                  var videoURLs: [URL] = []
                  for item in selectedItems {
                      let pickedMovie = try await item.loadTransferable(type: ArrayVideoPickerTransferable.self)
                      if let videoURL = pickedMovie?.videoURL {
                          videoURLs.append(videoURL)
                      }
                  }
                  isVideoProcessing = false
                  selectedVideoURLs = videoURLs
              } catch {
                  print(error.localizedDescription)
              }
          }
      }
    
    func deleteFiles() {
        do {
            for videoURL in selectedVideoURLs {
                try FileManager.default.removeItem(at: videoURL)
            }
            selectedVideoURLs.removeAll()
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct ArrayVideoPicker: View {
    @StateObject private var viewModel = ArrayVideoPickerViewModel()

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack {
                    if !viewModel.selectedVideoURLs.isEmpty {
                        ForEach(viewModel.selectedVideoURLs, id: \.self) { videoURL in
                            VideoPlayer(player: AVPlayer(url: videoURL))
                                .frame(height: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    
                    if viewModel.isVideoProcessing {
                        ProgressView()
                    }
                }
                .navigationTitle("Native Video Picker")
                .photosPicker(
                    isPresented: $viewModel.showPicker,
                    selection: $viewModel.selectedItems,
                    matching: .videos
                )
            }
            
            HStack(spacing: 15) {
                Button("Pick Video") {
                    viewModel.showPicker.toggle()
                }
                
                Button("Remove Picked Video") {
                    viewModel.deleteFiles()
                }
            }
            .padding(.top, 5)
            
            }
            .padding()
            .onChange(of: viewModel.selectedItems) { oldValue, newValue in
                viewModel.setVideos()
            }
        
    }
}

#Preview {
    ArrayVideoPicker()
    
}


struct ArrayVideoPickerTransferable: Transferable {
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
