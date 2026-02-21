//
//  VideoPlayerDetailView.swift
//  VideoPlayer
//
//  Created by Chika Yamamoto on 2026/02/21.
//


import SwiftData
import SwiftUI
import AVKit

/// 動画詳細再生画面
/// シンプル実装: `VideoMetadata.filePath` からローカルURLを作成し `AVPlayer` で再生します

struct VideoPlayerDetailView: View {
    let video: VideoMetadata
    
    @State private var player: AVPlayer? = nil
    @State private var isPlaying = false
    
    var body: some View {
        VStack(spacing: 16) {
            if let player = player {
                VideoPlayer(player: player)
                    .frame(height: 240)
                    .cornerRadius(8)
                    .onAppear {
                        player.play()
                        isPlaying = true
                    }
                    .onDisappear {
                        player.pause()
                        isPlaying = false
                    }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 240)
                    .overlay(Text("Video file not available").foregroundColor(.secondary))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(video.title)
                    .font(.headline)
                HStack {
                    Text(video.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if video.playbackPosition > 0 {
                        Text("Progress: \(video.formattedPosition)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                HStack {
                    Button(action: togglePlay) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .padding(8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle(video.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let path = video.filePath {
                let url = URL(fileURLWithPath: path)
                player = AVPlayer(url: url)
            }
        }
    }
    
    private func togglePlay() {
        guard let player = player else { return }
        if isPlaying { player.pause() } else { player.play() }
        isPlaying.toggle()
    }
}


#Preview {
    // SwiftUIプレビュー用のインメモリデータベース設定
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: VideoMetadata.self, Playlist.self, configurations: config)
    
    // プレビュー用サンプルビデオ1：お気に入り設定済み、途中再生位置あり
    let sampleVideo1 = VideoMetadata(
        assetIdentifier: "sample1", title: "Sample Video 1", duration: 120)
    sampleVideo1.lastPlayedAt = Date()
    sampleVideo1.playbackPosition = 60  // 半分まで再生済み
    sampleVideo1.isFavorite = true
    
    // サンプルデータをコンテナに追加
    container.mainContext.insert(sampleVideo1)
    
    return VideoPlayerDetailView(video: sampleVideo1)
        .modelContainer(container)
}
