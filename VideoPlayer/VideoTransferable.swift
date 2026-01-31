//
//  VideoTransferable.swift
//  VideoPlayer
//
//  Created by Chika Yamamoto on 2025/09/06.
//

import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// PhotosPicker と AVPlayer 間での動画ファイル転送を管理するカスタム型
/// CoreTransferable プロトコルに準拠し、写真ライブラリからの動画選択とアプリ内使用を可能にする
/// ファイルベースの転送方式を採用し、一時ファイルでの効率的な動画処理を実現
struct VideoTransferable: Transferable {
    /// 転送された動画ファイルのローカルURL
    /// アプリの一時ディレクトリ内に配置され、AVPlayerでの再生に使用される
    let url: URL

    /// Transferable プロトコルの転送表現定義
    /// エクスポートとインポートの両方向転送をサポートし、.movieタイプのファイルを処理
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            // エクスポート処理：アプリ内の動画を外部に送信する際の処理
            // 現在の実装では、既存のファイルURLをそのまま送信用ファイルとして返却
            SentTransferredFile(video.url)
        } importing: { received in
            // インポート処理：PhotosPickerから選択された動画ファイルを受信・処理

            // 元ファイル名を保持してアクセス性を向上
            let fileName = received.file.lastPathComponent

            // アプリ専用の永続ディレクトリにファイルをコピー
            // Documents/Videos ディレクトリを使用する。
            let documentsPath = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first!
            let videosDirectory = documentsPath.appendingPathComponent("Videos")

            // Videosディレクトリが存在しない場合は作成
            try? FileManager.default.createDirectory(
                at: videosDirectory, withIntermediateDirectories: true)

            let permanentURL = videosDirectory.appendingPathComponent(fileName)

            // 既存の同名ファイルを削除（重複回避とストレージ効率化）
            if FileManager.default.fileExists(atPath: permanentURL.path) {
                try FileManager.default.removeItem(at: permanentURL)
            }

            // 受信ファイルを永続ディレクトリにコピーする。
            try FileManager.default.copyItem(at: received.file, to: permanentURL)

            // 新しいVideoTransferableインスタンスを作成して返却
            return VideoTransferable(url: permanentURL)
        }
    }
}
