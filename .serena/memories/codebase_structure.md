# コードベース構造 - SwiftData実装後

## プロジェクト階層
```
VideoPlayer/
├── VideoPlayer/                      # メインソースコード
│   ├── VideoPlayerApp.swift         # アプリエントリポイント + SwiftData設定
│   ├── ContentView.swift            # メインビュー + メタデータ管理
│   ├── Models.swift                 # SwiftDataモデル定義
│   ├── PlaylistManagementView.swift # プレイリスト管理UI群
│   ├── AddToPlaylistView.swift      # プレイリスト追加UI
│   ├── VideoHistoryView.swift       # 履歴・お気に入り管理UI
│   ├── VideoTransferable.swift      # ビデオ転送ロジック
│   └── Assets.xcassets/             # リソースファイル
└── VideoPlayer.xcodeproj/           # Xcodeプロジェクト設定
```

## 主要コンポーネント詳細

### 1. VideoPlayerApp.swift
- SwiftDataコンテナ設定
- モデル登録（VideoMetadata, Playlist）
- CloudKit同期準備（コメントアウト）

### 2. ContentView.swift 
- SwiftData統合（@Query, @Environment）
- ビデオプレイヤーUI
- 自動メタデータ管理
- ナビゲーション機能

### 3. Models.swift
- **VideoMetadata**: ビデオメタデータモデル
  - ユニーク識別子、タイトル、お気に入り
  - 再生履歴、再生位置、タグ、評価
  - Playlistとの多対多リレーション
- **Playlist**: プレイリストモデル
  - 名前、作成日時、更新日時
  - VideoMetadataとのリレーション
  - 動画追加・削除メソッド

### 4. PlaylistManagementView.swift
**5つのビューコンポーネント**
- PlaylistManagementView: プレイリスト一覧
- PlaylistRowView: 行表示コンポーネント
- CreatePlaylistView: 新規作成画面
- PlaylistDetailView: 詳細・編集画面
- VideoMetadataRowView: 動画情報行

### 5. AddToPlaylistView.swift
- 動画のプレイリスト追加画面
- 複数選択対応
- 新規プレイリスト作成機能

### 6. VideoHistoryView.swift
- 再生履歴表示
- お気に入り管理
- 進捗バー表示
- 履歴クリア機能

### 7. VideoTransferable.swift
- PhotosPickerからの動画転送
- 一時ファイル管理
- AVPlayer対応URL生成

## データフロー
1. PhotosPicker → VideoTransferable → AVPlayer
2. 動画選択 → VideoMetadata作成/更新 → SwiftData保存
3. プレイリスト操作 → Playlist更新 → リアクティブUI更新
4. 再生操作 → 位置保存 → メタデータ更新

## アーキテクチャパターン
- **MVVM**: SwiftDataが自動的にViewModel層を提供
- **リアクティブ**: @Queryによる自動UI更新
- **分離**: データ、ビジネスロジック、UIの明確な分離
- **拡張性**: 新機能追加に対応しやすい設計