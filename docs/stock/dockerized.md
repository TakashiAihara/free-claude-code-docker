# Docker化設計

## 概要

free-claude-code を Alpine Linux ベースの Docker コンテナで動作させるための設計。

## ベースイメージ

- **Python 3.14 Alpine**: `python:3.14-alpine`
- 理由: 軽量、セキュリティ、Python 3.14 がプロジェクト要件

## 依存関係管理

- **uv** を使用して依存関係をインストール
- Alpine 用のビルド依存パッケージが必要:
  - `build-base`: コンパイル用
  - `git`: uv.lock からのインストールに必要
  - `libffi-dev`: cffi 用
  - `openssl-dev`: OpenSSL バインディング用
  - `rust`: 一部のパッケージのビルドに必要

## 環境変数

`.env.example` で定義されているすべての環境変数を Docker 環境変数として受け取る。

### 必須環境変数

- `NVIDIA_NIM_API_KEY` または他のプロバイダ API キー
- `MODEL`: デフォルトモデル

### オプション環境変数

- `MODEL_OPUS`, `MODEL_SONNET`, `MODEL_HAIKU`
- `ENABLE_THINKING`
- `ANTHROPIC_AUTH_TOKEN`
- `MESSAGING_PLATFORM`, `DISCORD_BOT_TOKEN`, `TELEGRAM_BOT_TOKEN`
- `CLAUDE_WORKSPACE`, `ALLOWED_DIR`
- その他の設定値

## ボリューム

- `/app/agent_workspace`: Claude のワークスペース
- `/app/.env`: 設定ファイル（マウント推奨）

## ポート

- `8082`: FastAPI サーバー

## ディレクトリ構造

```
Dockerfile
.dockerignore
docker-compose.yml
```

## Dockerfile 設計

### マルチステージビルド

1. **ビルドステージ**: 依存関係のインストール
2. **実行ステージ**: 最小限のイメージで実行

### 手順

1. Alpine ベースイメージを取得
2. ビルド依存パッケージをインストール
3. uv をインストール
4. プロジェクトファイルをコピー
5. uv sync で依存関係をインストール
6. 実行用依存パッケージを削除
7. ポート 8082 を公開
8. uvicorn でサーバー起動

## docker-compose.yml 設計

### サービス定義

```yaml
services:
  free-claude-code:
    build: .
    ports:
      - "8082:8082"
    env_file:
      - .env
    volumes:
      - ./agent_workspace:/app/agent_workspace
    restart: unless-stopped
```

## .dockerignore

```
.git
.gitignore
.github
tests
*.md
.env
agent_workspace
uv.lock
```

## 起動コマンド

```bash
docker build -t free-claude-code .
docker run -p 8082:8082 --env-file .env -v $(pwd)/agent_workspace:/app/agent_workspace free-claude-code
```

または docker-compose:

```bash
docker-compose up -d
docker-compose down
```

## 注意点

1. **Python 3.14**: プロジェクト要件に合わせる
2. **uv の使用**: pyproject.toml と uv.lock からインストール
3. **Alpine の制限**: 一部のパッケージは追加の依存が必要
4. **ワークスペース**: ボリュームマウントで永続化
