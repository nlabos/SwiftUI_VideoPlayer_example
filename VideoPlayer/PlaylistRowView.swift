//
//  PlaylistRowView.swift
//  VideoPlayer
//
//  Created by Chika Yamamoto on 2026/02/21.
//

import SwiftData
import SwiftUI

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
    
    return PlaylistRowView(playlist: playlist1)
        .modelContainer(container)
}
