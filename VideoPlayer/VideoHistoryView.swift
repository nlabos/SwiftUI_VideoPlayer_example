//
//  VideoHistoryView.swift
//  VideoPlayer
//
//  Created by Chika Yamamoto on 2025/09/06.
//

import SwiftData
import SwiftUI

/// 動画履歴表示画面
/// 再生履歴とお気に入り動画を管理し、削除やお気に入り切り替え機能を提供
struct VideoHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var videoMetadata: [VideoMetadata]
    
    /// 最終再生日時が設定されている動画を再生日時の降順で取得
    /// 実際に再生された動画のみをフィルタリング
    var recentlyPlayedVideos: [VideoMetadata] {
        videoMetadata
            .filter { $0.lastPlayedAt != nil }
            .sorted {
                ($0.lastPlayedAt ?? Date.distantPast) > ($1.lastPlayedAt ?? Date.distantPast)
            }
    }
    
    /// お気に入りに設定された動画を再生日時の降順で取得
    /// お気に入りフラグが立っている動画のみをフィルタリング
    var favoriteVideos: [VideoMetadata] {
        videoMetadata
            .filter { $0.isFavorite }
            .sorted {
                ($0.lastPlayedAt ?? Date.distantPast) > ($1.lastPlayedAt ?? Date.distantPast)
            }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // お気に入り動画セクション（動画がある場合のみ表示）
                if !favoriteVideos.isEmpty {
                    Section("Favorites") {
                        ForEach(favoriteVideos) { video in
                            VideoHistoryRowView(video: video) {
                                toggleFavorite(video)  // ハートタップでお気に入り切り替え
                            }
                        }
                    }
                }
                
                // 最近再生した動画セクション（動画がある場合のみ表示）
                if !recentlyPlayedVideos.isEmpty {
                    Section("Recently Played") {
                        ForEach(recentlyPlayedVideos) { video in
                            VideoHistoryRowView(video: video) {
                                toggleFavorite(video)  // ハートタップでお気に入り切り替え
                            }
                        }
                        .onDelete(perform: deleteFromHistory)  // スワイプ削除機能
                    }
                } else {
                    // 履歴が空の場合のプレースホルダー表示
                    Section {
                        Text("No videos in history")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .navigationTitle("Video History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // 完了ボタン（左上）- シートを閉じる
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                // 全削除ボタン（右上）- 履歴がある場合のみ表示
                if !recentlyPlayedVideos.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear All") {
                            clearAllHistory()
                        }
                        .foregroundColor(.red)  // 削除操作なので赤色で警告
                    }
                }
            }
        }
    }
    
    /// 動画のお気に入り状態を切り替える
    /// UIのハートボタンタップ時に呼び出される
    /// - Parameter video: お気に入り状態を変更する動画メタデータ
    private func toggleFavorite(_ video: VideoMetadata) {
        video.isFavorite.toggle()
        try? modelContext.save()
    }
    
    /// 履歴から特定の動画を削除（スワイプ削除用）
    /// - Parameter offsets: 削除対象のインデックス配列
    private func deleteFromHistory(offsets: IndexSet) {
        for index in offsets {
            let video = recentlyPlayedVideos[index]
            modelContext.delete(video)  // データベースから完全削除
        }
        try? modelContext.save()
    }
    
    /// 全ての動画履歴を削除
    /// ツールバーの「Clear All」ボタンから実行される
    /// 警告なしで実行されるため、UI設計上の注意が必要
    private func clearAllHistory() {
        for video in videoMetadata {
            modelContext.delete(video)  // 全動画メタデータを削除
        }
        try? modelContext.save()
    }
}

/// 履歴画面での動画情報表示行コンポーネント
/// 動画タイトル、再生時間、再生位置、進捗バー、最終再生日時、お気に入りボタンを表示
struct VideoHistoryRowView: View {
    let video: VideoMetadata
    let onFavoriteToggle: () -> Void  // お気に入り切り替えのクロージャ
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // 動画タイトル（最大2行表示）
                Text(video.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    // 動画の総再生時間を表示
                    Text(video.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 再生位置がある場合のみ、現在位置と進捗バーを表示
                    if video.playbackPosition > 0 {
                        Text("• \(video.formattedPosition)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        // 再生進捗バー（小さめのサイズで表示）
                        ProgressView(value: video.playbackProgress)
                            .frame(width: 50)
                            .scaleEffect(0.8)
                    }
                    
                    Spacer()
                }
                
                // 最終再生日時を相対時間で表示（例：「3時間前に再生」）
                if let lastPlayed = video.lastPlayedAt {
                    Text("Played \(lastPlayed, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // お気に入りトグルボタン
            // 塗りつぶしハート（お気に入り）vs 空のハート（通常）
            Button {
                onFavoriteToggle()
            } label: {
                Image(systemName: video.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(video.isFavorite ? .red : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())  // リスト行のタップと干渉しないように
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    // SwiftUIプレビュー用のインメモリデータベース設定
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: VideoMetadata.self, Playlist.self, configurations: config)
    
    // プレビュー用サンプルデータ1：お気に入り設定済み、途中再生位置あり
    let sampleVideo1 = VideoMetadata(
        assetIdentifier: "sample1", title: "Sample Video 1", duration: 120)
    sampleVideo1.lastPlayedAt = Date()
    sampleVideo1.playbackPosition = 60  // 半分まで再生済み
    sampleVideo1.isFavorite = true
    
    // プレビュー用サンプルデータ2：1時間前に再生済み、通常動画
    let sampleVideo2 = VideoMetadata(
        assetIdentifier: "sample2", title: "Sample Video 2", duration: 180)
    sampleVideo2.lastPlayedAt = Date().addingTimeInterval(-3600)  // 1時間前
    
    // サンプルデータをコンテナに追加
    container.mainContext.insert(sampleVideo1)
    container.mainContext.insert(sampleVideo2)
    
    return VideoHistoryView()
        .modelContainer(container)
}
