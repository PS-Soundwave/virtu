import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var showingGallery = false
    @State private var showingPhotoPicker = false
    @State private var selectedItems = [PhotosPickerItem]()
    @State private var isUploading = false
    @State private var uploadError: Error?
    @State private var showingSearchSheet = false
    @State private var galleryUsername = ""
    @State private var videos = [Video]()
    @State private var baseURL: String

    init() {
        guard
            let baseURL = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String
        else {
            fatalError("APIBaseURL not configured in Info.plist")
        }
        
        self.baseURL = baseURL
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in 
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(videos) { video in
                            VideoPlayerView(video: video)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }.scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
            }
            
            HStack(alignment: .center, spacing: 30) {
                Button(action: {
                    galleryUsername = ""
                    showingGallery = true
                }) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 30))
                }
                
                Menu {
                    Button(action: {
                        print("Record from OBS tapped")
                    }) {
                        Label("Record from OBS", systemImage: "record.circle")
                    }
                    
                    Button(action: {
                        showingPhotoPicker = true
                    }) {
                        Label("Upload Video", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "video.badge.plus")
                        .font(.system(size: 30))
                }

                Button(action: {
                    showingSearchSheet = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 30))
                }
            }
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedItems,
            maxSelectionCount: 1,
            matching: .videos,
            preferredItemEncoding: .current
        )
        .onChange(of: selectedItems) { prev, items in
            guard let item = items.first else { return }
            item.loadTransferable(
                type: VideoPickerTransferable.self
            ) { result in
                guard let videoData = try? result.get() else { return }
                Task {
                    await uploadVideo(url: videoData.url)
                }
            }
        }
        .overlay {
            if isUploading {
                ProgressView("Uploading...")
            }
        }
        .sheet(isPresented: $showingSearchSheet) {
            SearchSheet(onUserSelected: { username in 
                galleryUsername = username
                showingSearchSheet = false
                showingGallery = true
            })
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingGallery) {
            GalleryView(username: $galleryUsername)
        }
        .ignoresSafeArea(edges: [.top, .leading, .trailing])
        .ignoresSafeArea(.keyboard)
        .task {
            do {
                videos = try await VideoService.shared.getVideos()
            } catch {
                print("Error fetching videos: \(error)")
            }
        }
    }
    
    private func uploadVideo(url: URL) async {
        isUploading = true
        defer { isUploading = false }

        do {
            defer {
                try? FileManager.default.removeItem(at: url)
            }

            // Now upload the local copy
            try await UploadService.shared.uploadVideo(fileURL: url)
            print("Upload completed")
        } catch {
            print(error)
            self.uploadError = error
        }
    }
}

struct VideoPickerTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { received in
            SentTransferredFile(received.url)
        } importing: { received in
            let dest = FileManager.default.temporaryDirectory.appendingPathComponent(
                received.file.lastPathComponent)
            
            try? FileManager.default.removeItem(at: dest)

            try FileManager.default.copyItem(at: received.file, to: dest)
            
            return Self(url: dest)
        }
    }
}
