#!/bin/sh

# この時点でconcorseがgit cloneを実行してるため、git cloneの実行は不要。
# gitのローカルリポジトリのディレクトリに移動
cd repository-with-a-version-bump

# 現在のバージョンを取得
current_version=$(cat ./.version/number)

# バージョンをバンプするタイプを指定
BUMP_TYPE=${BUMP_TYPE:-"major"}  # デフォルトはメジャーバージョンをバンプ

# current_version が空文字列の場合
if [ "$current_version" = "" ]; then
    # 適切な初期バージョンを設定
    if [ "$BUMP_TYPE" = "major" ]; then
      new_version="1.0.0"
    elif [ "$BUMP_TYPE" = "minor" ]; then
      new_version="0.1.0"
    elif [ "$BUMP_TYPE" = "patch" ]; then
      new_version="0.0.1"
    else
      echo "Invalid bump_type specified."
      exit 1
    fi
else
  # バージョンをバンプする
  IFS_SAVE=$IFS
  IFS='.'
  set $current_version
  IFS=$IFS_SAVE
  major="$1"
  minor="$2"
  patch="$3"
  if [ "$BUMP_TYPE" = "major" ]; then
    major=$((major + 1))
    minor=0
    patch=0
  elif [ "$BUMP_TYPE" = "minor" ]; then
    minor=$((minor + 1))
    patch=0
  elif [ "$BUMP_TYPE" = "patch" ]; then
    patch=$((patch + 1))
  fi
  new_version="$major.$minor.$patch"
fi

# 新しいバージョンをファイルに書き込む
echo "$new_version" > ./.version/number
cat ./.version/number

# コミットしタグを付加する
git config --global user.email "concourse@local" # メールアドレスは必須（ユーザ名は任意）
git add ./.version/number
git commit -m "Bump version to v$new_version"
git tag v$new_version
