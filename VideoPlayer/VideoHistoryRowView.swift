//
//  VideoHistoryRowView.swift
//  VideoPlayer
//
//  Created by Chika Yamamoto on 2026/02/21.
//

import SwiftData
import SwiftUI

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
    
    // プレビュー用サンプルビデオ1：お気に入り設定済み、途中再生位置あり
    let sampleVideo1 = VideoMetadata(
        assetIdentifier: "sample1", title: "Sample Video 1", duration: 120)
    sampleVideo1.lastPlayedAt = Date()
    sampleVideo1.playbackPosition = 60  // 半分まで再生済み
    sampleVideo1.isFavorite = true
    
    
    // サンプルデータをコンテナに追加
    container.mainContext.insert(sampleVideo1)
    
    return VideoHistoryRowView(video: sampleVideo1) {
        print("favorite toggle tapped in preview")
    }
    .modelContainer(container)
}
