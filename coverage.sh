BRANCH="ci/add-coverage-gate"

# 安全確認
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "You have uncommitted changes. Commit or stash first, or answer y to continue."
  read -p "Continue anyway? (y/N) " yn
  case "$yn" in [Yy]*) ;; *) echo "Aborted."; exit 1;; esac
fi

git checkout -b "$BRANCH"

# requirements.txt
cat > requirements.txt <<'EOF'
fastapi==0.95.2
uvicorn[standard]==0.22.0
pytest==7.4.2
pytest-cov==4.1.0
httpx==0.25.0
coverage==7.2.6
EOF

# .coveragerc
cat > .coveragerc <<'EOF'
[run]
omit =
    tests/*
    */__init__.py

[report]
exclude_lines =
    pragma: no cover
    if __name__ == .__main__.
EOF

# pytest.ini
cat > pytest.ini <<'EOF'
[pytest]
minversion = 6.0
addopts = --maxfail=1 -q --cov=app --cov-report=xml:coverage.xml --cov-report=term
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
EOF

# scripts/check_coverage.py
mkdir -p scripts
cat > scripts/check_coverage.py <<'EOF'
#!/usr/bin/env python3
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

def parse_coverage_xml(path: Path):
    tree = ET.parse(path)
    root = tree.getroot()
    line_rate = root.attrib.get("line-rate")
    if line_rate is not None:
        try:
            return float(line_rate) * 100.0
        except Exception:
            pass
    for child in root.findall(".//"):
        if "line-rate" in child.attrib:
            try:
                return float(child.attrib.get("line-rate")) * 100.0
            except Exception:
                continue
    raise RuntimeError("coverage percent not found in XML")

def main():
    if len(sys.argv) < 2:
        print("Usage: check_coverage.py <coverage.xml> [threshold_percent]")
        sys.exit(2)
    cov_file = Path(sys.argv[1])
    if not cov_file.exists():
        print(f"coverage file not found: {cov_file}")
        sys.exit(2)
    threshold = float(sys.argv[2]) if len(sys.argv) >= 3 else 80.0
    pct = parse_coverage_xml(cov_file)
    print(f"Total coverage: {pct:.2f}% (threshold: {threshold}%)")
    if pct + 1e-6 < threshold:
        print("Coverage is below threshold -> FAIL")
        sys.exit(1)
    print("Coverage meets threshold -> OK")
    sys.exit(0)

if __name__ == "__main__":
    main()
EOF
chmod +x scripts/check_coverage.py

# .github workflow
mkdir -p .github/workflows
cat > .github/workflows/ci.yml <<'EOF'
name: CI / Build / Test / Coverage Gate

on:
  push:
    branches: [ "main", "develop" ]
  pull_request:
    branches: [ "main", "develop" ]
  workflow_dispatch:

env:
  ARTIFACT_NAME: "app-artifact"
  COVERAGE_THRESHOLD: "80"

jobs:
  test:
    name: Run tests & produce coverage
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
      - name: Run pytest (with coverage)
        run: |
          pytest --junitxml=report.xml
      - name: Upload coverage xml
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage.xml
      - name: Upload test junit report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: junit-report
          path: report.xml

  coverage_gate:
    name: Coverage gate
    runs-on: ubuntu-latest
    needs: [test]
    steps:
      - uses: actions/checkout@v4
      - name: Download coverage artifact
        uses: actions/download-artifact@v4
        with:
          name: coverage-report
          path: ./coverage_artifacts
      - name: Install Python tools for check
        run: |
          python -m pip install --upgrade pip
          pip install coverage
      - name: Run coverage gate script
        run: |
          python scripts/check_coverage.py coverage_artifacts/coverage.xml ${{ env.COVERAGE_THRESHOLD }}
EOF

git add requirements.txt .coveragerc pytest.ini scripts/check_coverage.py .github/workflows/ci.yml
git commit -m "ci: add coverage measurement and coverage gate"
git push -u origin "$BRANCH"

echo "Branch pushed: $BRANCH"
echo "Create PR via web UI or use: gh pr create --title 'ci: add coverage measurement and coverage gate' --body 'Add coverage measurement and coverage gate (pytest-cov, check script, CI workflow update)' --base main"
