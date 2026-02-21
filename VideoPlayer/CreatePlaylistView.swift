//
//  CreatePlaylistView.swift
//  VideoPlayer
//
//  Created by Chika Yamamoto on 2026/02/21.
//

import SwiftUI

/// 新規プレイリスト作成画面
/// シート形式で表示され、プレイリスト名を入力して作成する
struct CreatePlaylistView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var playlistName = ""  // 入力されたプレイリスト名
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Playlist Details") {
                    // プレイリスト名入力フィールド
                    TextField("Playlist Name", text: $playlistName)
                }
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // キャンセルボタン（左上）
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                // 作成ボタン（右上）- 名前が空の場合は無効化
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createPlaylist()
                    }
                    .disabled(playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    /// 新しいプレイリストを作成してデータベースに保存
    /// 空白文字のみの名前は無効とし、作成処理を実行しない
    private func createPlaylist() {
        let trimmedName = playlistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // 新しいPlaylistオブジェクトを作成
        let newPlaylist = Playlist(name: trimmedName)
        modelContext.insert(newPlaylist)
        
        // データベースに保存して画面を閉じる
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    CreatePlaylistView()
}
