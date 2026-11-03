#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
node --test tests/*.test.cjs
python3 -m unittest discover -s tests -p 'test_*.py'
mkdir -p test-results
runner="${QML_TEST_RUNNER:-/usr/lib/qt6/bin/qmltestrunner}"
QT_QPA_PLATFORM=offscreen "$runner" -input tests -o test-results/qml.txt,txt || { cat test-results/qml.txt; exit 1; }
cat test-results/qml.txt
