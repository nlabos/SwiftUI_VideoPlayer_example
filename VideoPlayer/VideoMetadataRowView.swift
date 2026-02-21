//
//  VideoMetadataRowView.swift
//  VideoPlayer
//
//  Created by Chika Yamamoto on 2026/02/21.
//

import SwiftData
import SwiftUI

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
        }
        .padding(.vertical, 2)
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
    return VideoMetadataRowView(video: sampleVideo1) {
        print("remove button tapped in preview")
    }
    .modelContainer(container)
}

