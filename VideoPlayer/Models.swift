//
//  Models.swift
//  VideoPlayer
//
//  Created by Chika Yamamoto on 2025/09/06.
//

import Foundation
import SwiftData

/// 動画メタデータを管理するSwiftDataモデル
/// 各動画ファイルの再生状態、ユーザー設定、メタ情報を永続化
/// CloudKit同期対応の設計で、複数デバイス間での履歴共有を想定
@Model
class VideoMetadata {
    /// 動画を一意に識別するID（重複不可）
    /// ファイル名またはPhotosライブラリのlocalIdentifierを使用
    @Attribute(.unique) var assetIdentifier: String
    
    /// 動画ファイルのローカルパスを保持（オプショナル）
    /// AVPlayerで再生する際にURL(fileURLWithPath:)で使用する
    var filePath: String?    // 新規追加: 保存されたファイルのフルパス
    
    /// ユーザーが設定可能な動画タイトル
    /// 初期値はファイル名から自動生成、後から編集可能
    var title: String
    
    /// お気に入り登録状態のフラグ
    /// UIでハートアイコンの表示制御とフィルタリングに使用
    var isFavorite: Bool
    
    /// 最終再生日時（オプショナル）
    /// 再生履歴の表示順序とクリーンアップ処理の基準として利用
    var lastPlayedAt: Date?
    
    /// 現在の再生位置（秒単位）
    /// 動画を途中まで見た際の続きから再生機能に使用
    var playbackPosition: TimeInterval
    
    /// ユーザー定義のタグ配列
    /// カテゴリ分類や検索機能の実装に使用（将来の機能拡張）
    var tags: [String]
    
    /// ユーザーによる5段階評価（0=未評価、1-5=星の数）
    /// レコメンデーション機能や品質フィルタに使用予定
    var userRating: Int  // 1-5 stars
    
    /// 動画の総再生時間（秒単位）
    /// AVAssetから取得した実際の動画長、プログレスバー計算に使用
    var duration: TimeInterval
    
    /// プレイリストとの多対多リレーションシップ
    /// 削除時はnullifyルールで、プレイリストから参照を除去するが削除はしない
    @Relationship(deleteRule: .nullify, inverse: \Playlist.videoMetadata)
    var playlists: [Playlist] = []
    
    /// VideoMetadataの初期化
    /// 必須パラメータのみ指定し、その他はデフォルト値で初期化
    /// - Parameters:
    ///   - assetIdentifier: 一意識別子（必須）
    ///   - title: 動画タイトル（必須）
    ///   - duration: 動画の長さ（デフォルト0、後から更新可能）
    ///   - filePath: 動画ファイルのフルパス（オプショナル）
    init(assetIdentifier: String, title: String, duration: TimeInterval = 0, filePath: String? = nil) {
        self.assetIdentifier = assetIdentifier
        self.filePath = filePath
        self.title = title
        self.isFavorite = false        // デフォルトは非お気に入り
        self.lastPlayedAt = nil        // 未再生状態
        self.playbackPosition = 0      // 最初から再生
        self.tags = []                 // タグなし
        self.userRating = 0            // 未評価
        self.duration = duration
        self.playlists = []            // プレイリスト所属なし
    }
    
    // 再生進捗率を計算
    var playbackProgress: Double {
        guard duration > 0 else { return 0 }
        return playbackPosition / duration
    }
    
    // 再生時間の文字列表現
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // 最後の再生位置の文字列表現
    var formattedPosition: String {
        let minutes = Int(playbackPosition) / 60
        let seconds = Int(playbackPosition) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// プレイリストを管理するSwiftDataモデル
/// 複数の動画をグループ化し、ユーザー定義のコレクションとして管理
/// 動画との多対多リレーションシップを提供し、効率的な検索・ソート機能を実装
/// CloudKit同期対応設計により、複数デバイス間でのプレイリスト共有を想定
@Model
class Playlist {
    /// ユーザーが設定するプレイリストの表示名
    /// 作成時に必須入力、後から編集可能な識別用ラベル
    var name: String
    
    /// プレイリスト作成日時（自動設定）
    /// ソート機能や履歴管理で利用される不変の基準時刻
    var createdAt: Date
    
    /// 最終更新日時（自動更新）
    /// 動画の追加・削除・順序変更時に自動で現在時刻に更新
    var updatedAt: Date
    
    /// プレイリスト内の動画数（キャッシュ）
    /// パフォーマンス最適化のため配列のcountを別途保持
    /// addVideo/removeVideoメソッドで自動同期される
    var videoCount: Int
    
    /// 動画メタデータとの多対多リレーションシップ
    /// 削除時はnullifyルールで、動画データは保持しつつ関連のみ除去
    @Relationship(deleteRule: .nullify)
    var videoMetadata: [VideoMetadata] = []
    
    /// Playlistの初期化処理
    /// 作成時刻と更新時刻を現在時刻で設定し、動画数を0で初期化
    /// - Parameter name: プレイリストの表示名（必須）
    init(name: String) {
        self.name = name
        self.createdAt = Date()    // 作成時刻を記録
        self.updatedAt = Date()    // 初期更新時刻を設定
        self.videoCount = 0        // 空のプレイリストとして初期化
    }
    
    /// プレイリストに動画を追加
    /// 重複チェックを行い、既に存在する動画の再追加を防ぐ
    /// 追加後はカウントと更新日時を自動更新
    /// - Parameter video: 追加する動画メタデータ
    func addVideo(_ video: VideoMetadata) {
        // 同じassetIdentifierを持つ動画の重複を防ぐ
        if !videoMetadata.contains(where: { $0.assetIdentifier == video.assetIdentifier }) {
            videoMetadata.append(video)
            videoCount = videoMetadata.count  // カウントを同期
            updatedAt = Date()                // 更新日時を記録
        }
    }
    
    /// プレイリストから動画を削除
    /// 指定された動画を安全に削除し、カウントと更新日時を自動更新
    /// - Parameter video: 削除する動画メタデータ
    func removeVideo(_ video: VideoMetadata) {
        // assetIdentifierベースの安全な削除処理
        videoMetadata.removeAll { $0.assetIdentifier == video.assetIdentifier }
        videoCount = videoMetadata.count  // カウントを同期
        updatedAt = Date()                // 更新日時を記録
    }
    
    /// プレイリスト内全動画の総再生時間を計算
    /// reduce関数で各動画のdurationを合計し、効率的に計算
    /// - Returns: 総再生時間（秒単位）
    var totalDuration: TimeInterval {
        videoMetadata.reduce(0) { $0 + $1.duration }
    }
    
    /// 総再生時間を「分:秒」形式でフォーマット
    /// プレイリスト情報表示やUI要約で使用される
    /// - Returns: "MM:SS"形式の文字列（例：「25:43」）
    var formattedTotalDuration: String {
        let minutes = Int(totalDuration) / 60
        let seconds = Int(totalDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
