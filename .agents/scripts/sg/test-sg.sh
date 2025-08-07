#!/bin/bash
# Test all ast-grep YAML rules in .agents/scripts/sg/ against their example code
# Usage: bash .agents/scripts/sg/test-sg.sh

set -e
cd "$(dirname "$0")"

# Colors
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'

# List of (yaml, code) pairs
declare -a tests=(
  "match-ws-close-method.yml match-ws-close-method.ts"
  "py-func-title.yml py-func-title.py"
  "py-assign-title.yml py-assign-title.py"
  "ts-dom-event-handler-assignment.yml ts-dom-event-handler-assignment.ts"
  "inside-class-func.yml inside-class-func.py"
  "not-has-return-func.yml not-has-return-func.ts"
  "print-to-logger-fix.yml print-to-logger-fix.py"
)

# Expected results: yaml expected explanation
expected_results="
match-ws-close-method.yml PASS
py-func-title.yml PASS
py-assign-title.yml PASS
ts-dom-event-handler-assignment.yml PASS
inside-class-func.yml FAIL advanced feature (inside) not supported in single-rule YAML (see docs)
not-has-return-func.yml FAIL advanced feature (not) not supported in single-rule YAML (see docs)
print-to-logger-fix.yml FAIL fix not supported in single-rule YAML (see docs)
"

for pair in "${tests[@]}"; do
  yaml="${pair%% *}"
  code="${pair##* }"
  expected_line=$(echo "$expected_results" | grep "^$yaml ")
  expected=$(echo "$expected_line" | awk '{print $2}')
  explanation=$(echo "$expected_line" | cut -d' ' -f3-)
  echo -e "\n${CYAN}== Testing $yaml on $code ==${RESET}"
  if [[ ! -f "$yaml" || ! -f "$code" ]]; then
    echo -e "  ${YELLOW}[SKIP]${RESET} $yaml or $code missing"
    continue
  fi
  if [[ $expected == PASS ]]; then
    echo -e "  ${GREEN}[EXPECTED: PASS]${RESET} Rule should match as described."
  else
    echo -e "  ${RED}[EXPECTED: NOT PASS]${RESET} $explanation"
  fi
  sg scan --rule "$yaml" "$code"
done
