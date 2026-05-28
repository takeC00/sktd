## Cloud Functions (Auth ↔ Firestore sync)

この `functions/` は **Firebase Authentication** と **Firestore** を自動同期するための Cloud Functions です。

### 何をする？

- Authユーザー作成時: `users/{uid}` を自動作成
- Authユーザー削除時: `users/{uid}` を削除し、関連データも掃除
  - `circleMembers` の `userId == uid` を削除
  - `circles.memberIds` から uid を `arrayRemove`

### セットアップ手順

1. Firebase CLI をインストールしログイン

```bash
npm i -g firebase-tools
firebase login
```

2. このリポジトリのルートでプロジェクトを紐付け

```bash
firebase use --add
```

3. Functions 依存をインストール

```bash
cd functions
npm i
```

4. デプロイ

```bash
firebase deploy --only functions
```

### 注意

- 本番環境に入れる場合は、リージョンや削除対象コレクションを必ず確認してください。

