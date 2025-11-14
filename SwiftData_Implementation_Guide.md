# SwiftData プレイリスト機能実装ガイド

## 実装概要

このプロジェクトでは、SwiftDataを使用してビデオプレイヤーアプリにプレイリスト機能を追加しました。ContentView_Design_Overview.mdで提案された設計に基づいて、以下の機能を実装しています。

## 追加されたファイル

### 1. Models.swift
- `VideoMetadata`: ビデオのメタデータを管理するSwiftDataモデル
- `Playlist`: プレイリストデータを管理するSwiftDataモデル
- 多対多のリレーションシップを実装

### 2. PlaylistManagementView.swift
- プレイリスト一覧表示
- プレイリスト作成・削除・編集
- プレイリスト詳細表示とビデオ管理

### 3. AddToPlaylistView.swift
- 動画をプレイリストに追加するためのインターフェース
- 複数プレイリストへの同時追加対応
- 新規プレイリスト作成機能

### 4. VideoHistoryView.swift
- 再生履歴の表示
- お気に入り動画の一覧
- 履歴のクリア機能

### 5. VideoTransferable.swift
- PhotosPickerからの動画転送ロジック（既存コードを分離）

## 主要機能

### データ永続化
- **SwiftData**: iOS 17の最新データ永続化フレームワークを使用
- **リレーションシップ**: VideoMetadataとPlaylistの多対多関係
- **自動保存**: UI操作に応じて自動的にデータが保存される

### プレイリスト管理
- **作成**: 新しいプレイリストの作成
- **編集**: プレイリスト名の変更
- **削除**: プレイリストの削除（動画は保持）
- **動画追加**: 既存プレイリストへの動画追加
- **動画削除**: プレイリストからの動画削除

### メタデータ管理
- **再生履歴**: 最後に再生した日時を記録
- **再生位置**: 動画の停止位置を自動保存
- **お気に入り**: 動画をお気に入りとしてマーク
- **動画情報**: タイトル、長さ、評価などの管理

### ユーザーインターフェース
- **ナビゲーション**: SwiftUIのNavigationStackを活用
- **リアクティブUI**: @Queryによる自動UI更新
- **モーダル表示**: Sheet、Alert、NavigationLinkの適切な使用

## 技術的なポイント

### SwiftDataの活用
```swift
@Model
class VideoMetadata {
    @Attribute(.unique) var assetIdentifier: String
    @Relationship(deleteRule: .nullify, inverse: \Playlist.videoMetadata)
    var playlists: [Playlist] = []
    // ...
}
```

### リアクティブなデータバインディング
```swift
@Environment(\.modelContext) private var modelContext
@Query private var videoMetadata: [VideoMetadata]
@Query private var playlists: [Playlist]
```

### データ整合性の保証
- ユニーク制約による重複防止
- リレーションシップによるデータ整合性
- 適切な削除ルールの設定

## 使用方法

### 基本的な操作フロー
1. **動画選択**: PhotosPickerから動画を選択
2. **自動メタデータ作成**: 選択された動画のメタデータが自動生成
3. **お気に入り登録**: ハートボタンでお気に入りに追加
4. **プレイリスト追加**: プラスボタンでプレイリストに追加
5. **履歴確認**: 再生履歴とお気に入りの確認

### プレイリスト操作
1. **プレイリスト管理画面**: "Manage Playlists"ボタンから移動
2. **新規作成**: プラスボタンで新しいプレイリストを作成
3. **プレイリスト編集**: プレイリスト名の変更、動画の追加・削除
4. **動画追加**: 再生画面からプレイリストに直接追加

## 今後の拡張可能性

### CloudKit同期
現在はローカルストレージのみですが、VideoPlayerApp.swiftのコメントを外すことでCloudKit同期が有効になります：

```swift
// container.mainContext.cloudKitDatabase = .private("iCloud.com.yourapp.videoplayer")
```

### 追加機能の実装
- タグ機能の活用
- 評価システムの実装
- 検索・フィルター機能
- プレイリストの並び替え
- 動画のサムネイル表示

## パフォーマンス考慮事項

- **遅延読み込み**: @Queryによる効率的なデータ取得
- **メモリ管理**: SwiftDataの自動メモリ管理
- **UI応答性**: 非同期処理による滑らかなUI操作
- **データ同期**: バックグラウンドでの自動保存

この実装により、シンプルなビデオプレイヤーから本格的なメディア管理アプリケーションへと発展しました。
