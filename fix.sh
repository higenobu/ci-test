git checkout -b fix/ci-import-app

# app をパッケージ化する簡単な __init__.py を作成
mkdir -p app
echo '__all__ = ["main"]' > app/__init__.py

git add app/__init__.py
git commit -m "fix: make app a Python package so tests can import it"
git push -u origin fix/ci-import-app

# PR を作る（gh CLI が使える場合）
gh pr create --title "fix: package app for tests" --body "Add app/__init__.py so pytest can import app and CI tests run, enabling coverage collection." --base main
