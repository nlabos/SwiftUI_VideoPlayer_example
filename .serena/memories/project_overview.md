# VideoPlayer プロジェクト概要 - 2025年9月6日更新

## プロジェクトの進化
元々はシンプルなSwiftUIビデオプレイヤーでしたが、SwiftDataを活用した本格的なメディア管理アプリケーションに進化しました。

## 現在の主要機能
- **ビデオ再生**: AVKitを使用した基本的な再生機能
- **プレイリスト管理**: SwiftDataによる完全なプレイリスト機能
- **メタデータ管理**: お気に入り、再生履歴、再生位置記憶
- **履歴機能**: 視聴履歴とお気に入りの管理
- **データ永続化**: SwiftDataによる効率的なデータ管理

## テクノロジースタック
- **言語**: Swift 5.0
- **フレームワーク**: SwiftUI
- **ビデオ処理**: AVKit (AVPlayer)
- **写真選択**: PhotosUI (PhotosPicker)
- **データ永続化**: SwiftData (iOS 17+)
- **デプロイメントターゲット**: iOS 18.5

## アーキテクチャ
### コアコンポーネント
- **VideoPlayerApp**: メインアプリケーションエントリポイント + SwiftData設定
- **ContentView**: メインビュー（ビデオプレイヤーUI + メタデータ管理）
- **Models**: SwiftDataモデル（VideoMetadata, Playlist）
- **PlaylistManagementView**: プレイリスト管理UI群
- **VideoHistoryView**: 履歴・お気に入り管理UI
- **AddToPlaylistView**: プレイリスト追加UI
- **VideoTransferable**: ビデオファイル転送処理

### データモデル
- **VideoMetadata**: 個別動画のメタデータ管理
- **Playlist**: プレイリスト管理（多対多リレーション）

## 主要な改善点
1. **データ永続化**: Core Dataより簡潔なSwiftData活用
2. **ユーザー体験**: 再生位置記憶、履歴管理、お気に入り
3. **拡張性**: CloudKit同期対応、モジュール化設計
4. **保守性**: 責任分離、型安全性、リアクティブUI

## 技術的特徴
- @Model マクロによる簡潔なデータ定義
- @Query による自動UI更新
- NavigationStackベースのモダンUI
- 多対多リレーションシップの活用