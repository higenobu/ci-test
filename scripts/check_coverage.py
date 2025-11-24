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
