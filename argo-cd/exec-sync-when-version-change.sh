#!/bin/bash

# ファイルのパスと前回のハッシュを設定
version_number_file_path="../dev/.version/number"
previous_version_hash_file_path="./.previous-version-hash"
previous_version_hash=""

# ファイルのハッシュを取得
current_version_hash=$(sha256sum "$version-number-file_path" | awk '{print $1}')

# 前回のハッシュを取得
if [ -f "$previous_version_hash_file_path" ]; then
    previous_hash=$(cat "$previous_version_hash_file_path")
fi

# ハッシュ値が前回と異なる場合は変更があったと判断
if [ "$current_version_hash" != "$previous_version_hash" ]; then
    echo "Version number has changed. Triggering ArgoCD sync..."
    # ArgoCDアプリケーションのSyncを実行
    argocd app sync my-app
    echo "$current_version_hash" > "$previous_version_hash_file_path"
fi
