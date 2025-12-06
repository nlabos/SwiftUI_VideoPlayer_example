//
//  PlaylistManagementView.swift
//  VideoPlayer
//
//  Created by Chika Yamamoto on 2025/09/06.
//

import SwiftData
import SwiftUI

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

/// プレイリスト一覧での個別行表示コンポーネント
/// プレイリストの基本情報（名前、動画数、総再生時間、更新日時）をコンパクトに表示
/// VStackによる縦方向レイアウトで情報の階層化を実現
/// NavigationLinkとの組み合わせでプレイリスト詳細画面への遷移を提供
struct PlaylistRowView: View {
    let playlist: Playlist  // 表示対象のプレイリストオブジェクト
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // プレイリスト名（メインタイトル）
            Text(playlist.name)
                .font(.headline)
            
            // 動画数と総再生時間を水平に配置
            HStack {
                // 含まれる動画の総数表示
                Text("\(playlist.videoCount) videos")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // プレイリスト全体の再生時間（計算プロパティ使用）
                Text(playlist.formattedTotalDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 最終更新日時の相対表示（例：「2時間前に更新」）
            Text("Updated: \(playlist.updatedAt, style: .relative)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)  // 行間の適度な余白確保
    }
}

/// 新規プレイリスト作成画面
/// シート形式で表示され、プレイリスト名を入力して作成する
struct CreatePlaylistView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var playlistName = ""  // 入力されたプレイリスト名
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Playlist Details") {
                    // プレイリスト名入力フィールド
                    TextField("Playlist Name", text: $playlistName)
                }
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // キャンセルボタン（左上）
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                // 作成ボタン（右上）- 名前が空の場合は無効化
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createPlaylist()
                    }
                    .disabled(playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    /// 新しいプレイリストを作成してデータベースに保存
    /// 空白文字のみの名前は無効とし、作成処理を実行しない
    private func createPlaylist() {
        let trimmedName = playlistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // 新しいPlaylistオブジェクトを作成
        let newPlaylist = Playlist(name: trimmedName)
        modelContext.insert(newPlaylist)
        
        // データベースに保存して画面を閉じる
        try? modelContext.save()
        dismiss()
    }
}

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
                    VideoMetadataRowView(video: video) {
                        removeVideo(video)  // 動画削除のクロージャ
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

/// プレイリスト詳細画面での動画情報表示行コンポーネント
/// 各動画のメタデータ（タイトル、お気に入り状態、再生時間、進捗）を表示
/// 削除ボタンを内蔵し、プレイリストからの動画除去機能を提供
/// HStackによる水平レイアウトで情報とアクションボタンを効率的に配置
struct VideoMetadataRowView: View {
    let video: VideoMetadata                // 表示対象の動画メタデータ
    let onRemove: () -> Void               // 削除ボタンタップ時のコールバッククロージャ
    
    var body: some View {
        HStack {
            // 動画情報表示部分（左側）
            VStack(alignment: .leading, spacing: 4) {
                // 動画タイトル（最大2行表示）
                Text(video.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    // お気に入り状態の表示（ハートアイコン）
                    if video.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // 動画の総再生時間表示
                    Text(video.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 途中再生位置がある場合の現在位置表示
                    if video.playbackPosition > 0 {
                        Text("• \(video.formattedPosition)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    // 最終再生日時の相対表示（例：「3時間前」）
                    if let lastPlayed = video.lastPlayedAt {
                        Text(lastPlayed, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 削除ボタン（右側）
            Button("Remove") {
                onRemove()
            }
            .font(.caption)
            .foregroundColor(.red)  // 削除操作なので警告色で表示
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    PlaylistManagementView()
}
