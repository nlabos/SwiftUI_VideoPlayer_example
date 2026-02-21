//
//  PlaylistDetailView.swift
//  VideoPlayer
//
//  Created by Chika Yamamoto on 2026/02/21.
//

import SwiftData
import SwiftUI
import AVKit
/// プレイリスト詳細画面
/// 指定されたプレイリストに含まれる動画の一覧表示、動画の削除、プレイリスト名の編集機能を提供
struct PlaylistDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let playlist: Playlist
    
    // UI状態管理
    @State private var showingEditName = false  // 名前編集アラートの表示状態
    @State private var editedName = ""          // 編集中のプレイリスト名
    
    var body: some View {
        List {
            Section {
                // プレイリスト内の動画を最終再生日時の降順で表示
                ForEach(
                    playlist.videoMetadata.sorted(by: {
                        ($0.lastPlayedAt ?? Date.distantPast)
                        > ($1.lastPlayedAt ?? Date.distantPast)
                    })
                ) { video in
                    // タップで再生画面へ遷移（行内のRemoveボタンはそのまま使用可能）
                    NavigationLink(destination: VideoPlayerDetailView(video: video)) {
                        VideoMetadataRowView(video: video) {
                            removeVideo(video)  // 動画削除のクロージャ
                        }
                    }
                }
                .onDelete(perform: deleteVideos)  // スワイプ削除機能
            } header: {
                // セクションヘッダー：動画数と総再生時間を表示
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Videos (\(playlist.videoCount))")
                        Spacer()
                        Text(playlist.formattedTotalDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            // 編集ボタン（右上）
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    editedName = playlist.name
                    showingEditName = true
                }
            }
        }
        // プレイリスト名編集アラート
        .alert("Edit Playlist Name", isPresented: $showingEditName) {
            TextField("Playlist Name", text: $editedName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                saveEditedName()
            }
        }
    }
    
    /// スワイプ削除に対応したビデオ削除処理
    /// - Parameter offsets: 削除対象のインデックス配列
    private func deleteVideos(offsets: IndexSet) {
        let sortedVideos = playlist.videoMetadata.sorted(by: {
            ($0.lastPlayedAt ?? Date.distantPast) > ($1.lastPlayedAt ?? Date.distantPast)
        })
        for index in offsets {
            removeVideo(sortedVideos[index])
        }
    }
    
    /// 指定された動画をプレイリストから削除
    /// - Parameter video: 削除対象の動画メタデータ
    private func removeVideo(_ video: VideoMetadata) {
        playlist.removeVideo(video)
        try? modelContext.save()
    }
    
    /// 編集されたプレイリスト名を保存
    /// 空白文字のみの名前は無効とし、保存処理を実行しない
    private func saveEditedName() {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            playlist.name = trimmedName
            playlist.updatedAt = Date()  // 更新日時も更新
            try? modelContext.save()
        }
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
    
    // プレビュー用サンプルビデオ2：1時間前に再生済み、通常動画
    let sampleVideo2 = VideoMetadata(
        assetIdentifier: "sample2", title: "Sample Video 2", duration: 180)
    sampleVideo2.lastPlayedAt = Date().addingTimeInterval(-3600)  // 1時間前
    
    // プレビュー用サンプルビデオ3：お気に入り、再生済み
    let sampleVideo3 = VideoMetadata(
        assetIdentifier: "sample3", title: "Long Documentary Video", duration: 3600)
    sampleVideo3.lastPlayedAt = Date().addingTimeInterval(-7200)  // 2時間前
    sampleVideo3.isFavorite = true
    sampleVideo3.playbackPosition = 1800  // 半分まで再生
    
    // プレビュー用サンプルプレイリスト1：複数の動画を含む
    let playlist1 = Playlist(name: "Favorites Collection")
    playlist1.addVideo(sampleVideo1)
    playlist1.addVideo(sampleVideo3)
    
    // サンプルデータをコンテナに追加
    container.mainContext.insert(sampleVideo1)
    container.mainContext.insert(sampleVideo2)
    container.mainContext.insert(sampleVideo3)
    container.mainContext.insert(playlist1)
    
    return PlaylistDetailView(playlist: playlist1)
        .modelContainer(container)
}
