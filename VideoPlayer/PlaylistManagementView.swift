//
//  PlaylistManagementView.swift
//  VideoPlayer
//
//  Created by Chika Yamamoto on 2025/09/06.
//

import SwiftData
import SwiftUI
import AVKit

/// プレイリスト管理画面のメインビュー
/// 全てのプレイリストの一覧表示、新規作成、削除機能を提供
/// SwiftData @Queryによるリアルタイム更新でデータの自動同期を実現
/// NavigationStackによる階層ナビゲーションでプレイリスト詳細への遷移を管理
struct PlaylistManagementView: View {
    @Environment(\.modelContext) private var modelContext  // SwiftDataのデータベースコンテキスト
    @Query private var playlists: [Playlist]               // 全プレイリストの自動取得・監視
    
    // UI状態管理プロパティ
    @State private var showingCreatePlaylist = false       // 新規作成シートの表示状態
    @State private var newPlaylistName = ""                // 新規プレイリスト名入力（未使用）
    
    var body: some View {
        NavigationStack {
            List {
                // プレイリスト一覧：更新日時の降順でソート表示
                ForEach(playlists.sorted(by: { $0.updatedAt > $1.updatedAt })) { playlist in
                    // 各プレイリストをタップで詳細画面に遷移
                    NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                        PlaylistRowView(playlist: playlist)
                    }
                }
                .onDelete(perform: deletePlaylists)  // スワイプ削除機能
            }
            .navigationTitle("Playlists")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // 新規作成ボタン（右上の+アイコン）
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreatePlaylist = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // 新規プレイリスト作成シート
            .sheet(isPresented: $showingCreatePlaylist) {
                CreatePlaylistView()
            }
        }
    }
    
    /// プレイリストのスワイプ削除処理
    /// 指定されたインデックスのプレイリストをデータベースから完全削除
    /// - Parameter offsets: 削除対象のプレイリストインデックス配列
    private func deletePlaylists(offsets: IndexSet) {
        let sortedPlaylists = playlists.sorted(by: { $0.updatedAt > $1.updatedAt })
        for index in offsets {
            modelContext.delete(sortedPlaylists[index])
        }
        // データベースへの変更を即座に保存
        try? modelContext.save()
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
    
    // プレビュー用サンプルプレイリスト2：1つの動画のみ
    let playlist2 = Playlist(name: "Watch Later")
    playlist2.addVideo(sampleVideo2)
    
    // プレビュー用サンプルプレイリスト3：空のプレイリスト
    let playlist3 = Playlist(name: "Empty Playlist")
    
    // サンプルデータをコンテナに追加
    container.mainContext.insert(sampleVideo1)
    container.mainContext.insert(sampleVideo2)
    container.mainContext.insert(sampleVideo3)
    container.mainContext.insert(playlist1)
    container.mainContext.insert(playlist2)
    container.mainContext.insert(playlist3)
    
    return PlaylistManagementView()
        .modelContainer(container)
}
