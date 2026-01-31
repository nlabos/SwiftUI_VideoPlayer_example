//
//  ContentView.swift
//  VideoPlayer
//
//  Created by Chika Yamamoto on 2025/08/23.
//

import AVKit
import PhotosUI
import SwiftData
import SwiftUI

/**
 * メインの動画プレイヤー画面
 * PhotosPickerを使用した動画選択、AVPlayerによる再生、SwiftDataによるメタデータ管理を統合
 * プレイリスト管理、履歴表示、お気に入り機能など包括的な動画管理機能を提供
 */
struct ContentView: View {
    // SwiftDataの操作コンテキスト - データベース操作に使用
    @Environment(\.modelContext) private var modelContext
    
    // データベースから全ての動画メタデータを取得するクエリ - リアルタイム更新対応
    @Query private var videoMetadata: [VideoMetadata]
    
    // データベースから全てのプレイリストを取得するクエリ - プレイリスト選択時に使用
    @Query private var playlists: [Playlist]
    
    // PhotosPickerで選択された動画アイテム - 動画選択の起点となる重要な状態
    @State private var selectedItem: PhotosPickerItem?
    
    // AVPlayerインスタンス - 実際の動画再生を担当、nilの場合は未選択状態
    @State private var player: AVPlayer?
    
    // 動画の再生/一時停止状態 - UIのボタン表示と再生制御に使用
    @State private var isPlaying: Bool = false
    
    // 現在再生中の動画のメタデータ - お気に入り機能や再生位置保存に使用
    @State private var currentVideoMetadata: VideoMetadata?
    
    // プレイリスト選択シートの表示状態 - AddToPlaylistViewの表示制御
    @State private var showingPlaylistView = false
    
    // 動画履歴画面の表示状態 - VideoHistoryViewのシート表示制御
    @State private var showingHistoryView = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 動画プレイヤー表示領域 - AVPlayerが設定されている場合のみ表示
                if let player = player {
                    VideoPlayer(player: player)
                        .frame(width: 320, height: 180)
                        .cornerRadius(10)
                    
                    // 動画情報とコントロール部分 - メタデータが利用可能な場合のみ表示
                    if let metadata = currentVideoMetadata {
                        VStack(spacing: 10) {
                            Text(metadata.title)
                                .font(.headline)
                                .lineLimit(2)
                            
                            HStack {
                                // お気に入りボタン - ハートアイコンで状態を視覚的に表現
                                Button {
                                    toggleFavorite(metadata)
                                } label: {
                                    Image(systemName: metadata.isFavorite ? "heart.fill" : "heart")
                                        .foregroundColor(metadata.isFavorite ? .red : .gray)
                                        .font(.title2)
                                }
                                
                                Spacer()
                                
                                // プレイリストに追加ボタン - AddToPlaylistViewシートを表示
                                Button {
                                    showingPlaylistView = true
                                } label: {
                                    Image(systemName: "plus.circle")
                                        .font(.title2)
                                }
                                .sheet(isPresented: $showingPlaylistView) {
                                    AddToPlaylistView(videoMetadata: metadata)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 再生/一時停止ボタン - 中央の円形ボタン
                    Button {
                        if isPlaying {
                            player.pause()
                            updatePlaybackPosition()
                        } else {
                            player.play()
                        }
                        isPlaying.toggle()
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    
                    // 最初から再生ボタン - 動画を冒頭に戻すボタン
                    Button("Reset to Beginning") {
                        player.seek(to: .zero)
                        if let metadata = currentVideoMetadata {
                            metadata.playbackPosition = 0
                            try? modelContext.save()
                        }
                        if isPlaying {
                            player.play()
                        }
                    }
                    .padding()
                    
                } else {
                    // 動画未選択時のプレースホルダー表示 - グレーの矩形とメッセージ
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 320, height: 180)
                        .overlay(
                            Text("No video selected")
                                .foregroundColor(.gray)
                        )
                }
                
                // カメラロールから動画を選択するボタン - PhotosPickerを使用した動画選択の起点
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .videos
                ) {
                    Text("Select Video from Camera Roll")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                // ナビゲーションボタン群 - 他画面への移動ボタン
                HStack(spacing: 20) {
                    Button("View History") {
                        showingHistoryView = true
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    NavigationLink("Manage Playlists") {
                        PlaylistManagementView()
                    }
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("Video Player")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                await loadVideo(from: newItem)
            }
        }
        .onAppear {
            // 定期的に再生位置を更新
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if isPlaying {
                    updatePlaybackPosition()
                }
            }
        }
        .sheet(isPresented: $showingHistoryView) {
            VideoHistoryView()
        }
    }
    
    @MainActor
    private func loadVideo(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            // 選択されたアイテムから動画ファイルを取得
            if let movie = try await item.loadTransferable(type: VideoTransferable.self) {
                // 現在のプレイヤーが再生中の場合は停止
                player?.pause()
                isPlaying = false
                
                // 選択された動画で新しいプレイヤーを作成
                player = AVPlayer(url: movie.url)
                
                // 動画メタデータを取得または作成
                await createOrUpdateVideoMetadata(from: item, url: movie.url)
                
                // 利用可能な場合は再生位置を復元
                if let metadata = currentVideoMetadata, metadata.playbackPosition > 0 {
                    let time = CMTime(seconds: metadata.playbackPosition, preferredTimescale: 600)
                    await player?.seek(to: time)
                }
                
                // オプション: 動画終了時の通知を追加
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player?.currentItem,
                    queue: .main
                ) { _ in
                    isPlaying = false
                    player?.seek(to: .zero)
                    if let metadata = currentVideoMetadata {
                        metadata.playbackPosition = 0
                        try? modelContext.save()
                    }
                }
            }
        } catch {
            print("Failed to load video: \(error)")
        }
    }
    
    /// 動画メタデータの作成または更新を行う
    /// 新規動画の場合はAVAssetから動画情報を取得してメタデータを作成
    /// 既存動画の場合は最終再生日時のみ更新
    /// - Parameters:
    ///   - item: PhotosPickerアイテム
    ///   - url: 動画ファイルのローカルURL
    private func createOrUpdateVideoMetadata(from item: PhotosPickerItem, url: URL) async {
        // PhotosPickerから識別子を取得（ファイル名ベースの簡易実装）
        let identifier = url.lastPathComponent
        
        // 既存のメタデータを検索
        if let existing = videoMetadata.first(where: { $0.assetIdentifier == identifier }) {
            existing.lastPlayedAt = Date()  // 最終再生日時を現在時刻で更新
            // ファイルパスが保存されていない場合は設定
            //if existing.filePath == nil {
            //    existing.filePath = url.path
            //}
            // ファイルが実際に存在する場合のみパスを更新
            if FileManager.default.fileExists(atPath: url.path) {
                existing.filePath = url.path // 常に最新のパスを保持
            } else {
                // ファイルが存在しない場合は再コピーが必要
                print("⚠️ ファイルが見つかりません: \(url.path)")
                existing.filePath = nil  // 無効なパスをクリア
            }
            currentVideoMetadata = existing
        } else {
            // 新しいメタデータを作成
            let asset = AVURLAsset(url: url)
            let duration = try? await asset.load(.duration)
            let durationSeconds = duration?.seconds ?? 0
            
            let metadata = VideoMetadata(
                assetIdentifier: identifier,
                title: url.deletingPathExtension().lastPathComponent,  // ファイル名から拡張子を除いたものをタイトルに設定
                duration: durationSeconds,
                filePath: url.path
            )
            metadata.lastPlayedAt = Date()
            
            modelContext.insert(metadata)
            currentVideoMetadata = metadata
        }
        
        try? modelContext.save()
    }
    
    /// 動画のお気に入り状態を切り替える
    /// UIのハートボタンタップ時に呼び出される
    /// - Parameter metadata: 対象の動画メタデータ
    private func toggleFavorite(_ metadata: VideoMetadata) {
        metadata.isFavorite.toggle()
        try? modelContext.save()
    }
    
    /// 現在の再生位置をデータベースに保存
    /// タイマーまたは一時停止時に定期的に呼び出される
    /// 続きから再生機能の基盤となる重要な処理
    private func updatePlaybackPosition() {
        guard let player = player,
              let metadata = currentVideoMetadata
        else { return }
        
        let currentTime = player.currentTime().seconds
        if !currentTime.isNaN && currentTime > 0 {
            metadata.playbackPosition = currentTime    // 現在の再生位置を保存
            metadata.lastPlayedAt = Date()             // 最終再生日時も更新
            try? modelContext.save()
        }
    }
}

//#Preview {
//    ContentView()
//        .modelContainer(for: [VideoMetadata.self, Playlist.self], inMemory: true)
//}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: VideoMetadata.self, Playlist.self, configurations: config)
    
    // 動画サンプル（5つ）
    let videos = [
        ("sample1", "Introduction to Swift", 300, true, 150),
        ("sample2", "Advanced SwiftUI", 600, false, 0),
        ("sample3", "SwiftData Tutorial", 450, true, 200),
        ("sample4", "iOS App Design", 900, false, 450),
        ("sample5", "Publishing to App Store", 720, true, 0)
    ].map { (id, title, duration, isFavorite, position) in
        let video = VideoMetadata(assetIdentifier: id, title: title, duration: Double(duration))
        video.isFavorite = isFavorite
        video.playbackPosition = Double(position)
        video.lastPlayedAt = Date().addingTimeInterval(Double.random(in: -86400...0))
        return video
    }
    
    // プレイリストサンプル（4つ）
    let playlist1 = Playlist(name: "Swift Learning Path")
    playlist1.addVideo(videos[0])
    playlist1.addVideo(videos[1])
    playlist1.addVideo(videos[2])
    
    let playlist2 = Playlist(name: "Design Resources")
    playlist2.addVideo(videos[3])
    
    let playlist3 = Playlist(name: "Publishing Guide")
    playlist3.addVideo(videos[4])
    
    let playlist4 = Playlist(name: "To Watch")
    // 空のプレイリスト
    
    // すべてをコンテナに追加
    videos.forEach { container.mainContext.insert($0) }
    [playlist1, playlist2, playlist3, playlist4].forEach { container.mainContext.insert($0) }
    
    return ContentView()
        .modelContainer(container)
}
