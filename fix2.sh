BRANCH="fix/ci-import-app"
git checkout -b "$BRANCH"

# 1) add app/__init__.py
mkdir -p app
if [ ! -f app/__init__.py ]; then
  cat > app/__init__.py <<'PY'
# package init to allow `import app`
__all__ = ["main"]
PY
  git add app/__init__.py
else
  echo "app/__init__.py already exists"
fi

# 2) patch workflow: add PYTHONPATH env to the pytest step
WORKFLOW=".github/workflows/ci.yml"
if [ -f "$WORKFLOW" ]; then
  # Create a backup
  cp "$WORKFLOW" "${WORKFLOW}.bak"

  # Insert env: PYTHONPATH under the pytest step (safe sed add if not exists)
  # We will look for the line "- name: Run pytest (with coverage)" and insert env: block after it.
  awk 'BEGIN{added=0}
  {
    print $0
    if ($0 ~ /- name: Run pytest/ && added==0) {
      # consume next lines until the run: line, and then insert env if not present
      getline; print $0
      if ($0 ~ /run:/) {
        print "        env:"
        print "          PYTHONPATH: ${{ github.workspace }}"
        added=1
      } else {
        # put back
        # nothing
      }
    }
  }' "$WORKFLOW" > "${WORKFLOW}.tmp" && mv "${WORKFLOW}.tmp" "$WORKFLOW"

  # If awk didn't add, fall back to a safer YAML append: replace the pytest step with a small template
  if ! grep -q "PYTHONPATH: \\$\\{\\{ github.workspace \\}\\}" "$WORKFLOW"; then
    # Replace the whole test->Run pytest step with a version that includes env
    python - "$WORKFLOW" <<'PYCODE'
import sys,io,os
p=sys.argv[1]
s=open(p).read()
old='''      - name: Run pytest (with coverage)
        run: |
          # pytest.ini already has --cov=app --cov-report=xml:coverage.xml
          pytest --junitxml=report.xml || true
        continue-on-error: false
'''
new='''      - name: Run pytest (with coverage)
        env:
          PYTHONPATH: ${{ github.workspace }}
        run: |
          # pytest.ini already has --cov=app --cov-report=xml:coverage.xml
          pytest --junitxml=report.xml || true
        continue-on-error: false
'''
if old in s:
    s=s.replace(old,new)
    open(p,'w').write(s)
    print("patched pytest step")
else:
    print("could not find exact pytest block; file left unchanged")
PYCODE
  fi

  git add "$WORKFLOW"
else
  echo "$WORKFLOW not found; please adjust workflow path"
fi

git commit -m "fix(ci): make app importable in CI (add __init__.py) and set PYTHONPATH in workflow" || git commit --amend --no-edit
git push -u origin "$BRANCH"

echo "Branch pushed: $BRANCH"
echo "Create a PR from this branch (GitHub web UI or: gh pr create --title 'fix: package app for CI' --body 'Add app/__init__.py and set PYTHONPATH for pytest in CI' --base main)"
