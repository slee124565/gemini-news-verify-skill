#!/bin/bash

set -euo pipefail

DIMENSIONS=(fact bias evidence timeliness)

if [ $# -lt 1 ]; then
  echo "錯誤：未提供工作目錄。"
  echo "用法: $0 <work_dir>"
  exit 1
fi

WORK_DIR="$1"
ARTICLE_FILE="${WORK_DIR}/article.txt"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROMPTS_DIR="${SKILL_DIR}/assets/prompts"
CHECKPOINT_DIR="${WORK_DIR}/checkpoint"

if [ ! -f "$ARTICLE_FILE" ]; then
  echo "錯誤：找不到文章檔案 $ARTICLE_FILE"
  exit 1
fi

if [ ! -d "$PROMPTS_DIR" ]; then
  echo "錯誤：找不到 Prompt 樣板目錄 $PROMPTS_DIR"
  exit 1
fi

mkdir -p "$CHECKPOINT_DIR"

status_file() {
  printf '%s/%s.status\n' "$CHECKPOINT_DIR" "$1"
}

signature_file() {
  printf '%s/%s.signature\n' "$CHECKPOINT_DIR" "$1"
}

meta_file() {
  printf '%s/%s.meta\n' "$CHECKPOINT_DIR" "$1"
}

prompt_file() {
  printf '%s/prompt_%s.md\n' "$WORK_DIR" "$1"
}

result_file() {
  printf '%s/result_%s.md\n' "$WORK_DIR" "$1"
}

log_file() {
  printf '%s/%s_error.log\n' "$WORK_DIR" "$1"
}

template_file() {
  printf '%s/%s-check.md\n' "$PROMPTS_DIR" "$1"
}

read_status() {
  local dimension=$1
  local file
  file="$(status_file "$dimension")"

  if [ -f "$file" ]; then
    cat "$file"
  else
    printf 'pending\n'
  fi
}

write_status() {
  local dimension=$1
  local state=$2
  printf '%s\n' "$state" > "$(status_file "$dimension")"
}

hash_stream() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  else
    perl -MDigest::SHA=sha256_hex -0777 -ne 'print sha256_hex($_), "\n"'
  fi
}

dimension_signature() {
  local dimension=$1
  cat "$ARTICLE_FILE" "$(template_file "$dimension")" | hash_stream
}

model_for() {
  case "$1" in
    fact) printf 'gemini-2.5-pro\n' ;;
    bias) printf 'gemini-2.5-flash\n' ;;
    evidence) printf 'gemini-2.5-pro\n' ;;
    timeliness) printf 'gemini-2.5-flash\n' ;;
    *)
      echo "錯誤：未知維度 $1" >&2
      exit 1
      ;;
  esac
}

instruction_for() {
  case "$1" in
    fact) printf '請根據 prompt_fact.md 的指示進行事實查核，將結果直接輸出為 markdown 格式\n' ;;
    bias) printf '請根據 prompt_bias.md 的指示進行立場查核，將結果直接輸出為 markdown 格式\n' ;;
    evidence) printf '請根據 prompt_evidence.md 的指示進行證據查核，將結果直接輸出為 markdown 格式\n' ;;
    timeliness) printf '請根據 prompt_timeliness.md 的指示進行時效查核，將結果直接輸出為 markdown 格式\n' ;;
    *)
      echo "錯誤：未知維度 $1" >&2
      exit 1
      ;;
  esac
}

write_meta() {
  local dimension=$1
  local state=$2
  local signature=$3
  local model=$4
  cat > "$(meta_file "$dimension")" <<EOF
dimension=$dimension
state=$state
signature=$signature
model=$model
updated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
}

materialize_prompt() {
  local dimension=$1
  local template
  local output

  template="$(template_file "$dimension")"
  output="$(prompt_file "$dimension")"

  perl -e '
    open(my $af, "<", $ARGV[0]) or die "無法開啟文章檔: $!";
    my $article = do { local $/; <$af> };
    close($af);

    open(my $tf, "<", $ARGV[1]) or die "無法開啟樣板檔: $!";
    my $template = do { local $/; <$tf> };
    close($tf);

    $template =~ s/\{\{article_content\}\}/$article/g;
    print $template;
  ' "$ARTICLE_FILE" "$template" > "$output"

  echo "   已產生 $(basename "$output")"
}

prepare_dimension() {
  local dimension=$1
  local signature
  local previous_signature=""
  local current_status
  local result
  local prompt
  local log
  local model

  result="$(result_file "$dimension")"
  prompt="$(prompt_file "$dimension")"
  log="$(log_file "$dimension")"
  model="$(model_for "$dimension")"
  signature="$(dimension_signature "$dimension")"
  current_status="$(read_status "$dimension")"

  if [ -f "$(signature_file "$dimension")" ]; then
    previous_signature="$(cat "$(signature_file "$dimension")")"
  fi

  if [ "$previous_signature" != "$signature" ]; then
    echo "   [$dimension] 偵測到輸入變更，重設 checkpoint。"
    printf '%s\n' "$signature" > "$(signature_file "$dimension")"
    write_status "$dimension" "pending"
    write_meta "$dimension" "pending" "$signature" "$model"
    rm -f "$result" "$log"
    materialize_prompt "$dimension"
    return 0
  fi

  if [ ! -f "$prompt" ]; then
    echo "   [$dimension] 缺少 prompt 檔，重新具現化。"
    materialize_prompt "$dimension"
  fi

  if [ "$current_status" = "completed" ] && [ -s "$result" ]; then
    echo "   [$dimension] checkpoint 命中，沿用既有結果。"
    write_meta "$dimension" "completed" "$signature" "$model"
    return 0
  fi

  if [ "$current_status" = "completed" ] && [ ! -s "$result" ]; then
    echo "   [$dimension] 狀態為 completed，但結果檔遺失或為空，改為 pending。"
  elif [ "$current_status" = "failed" ]; then
    echo "   [$dimension] 上次失敗，將只補跑此維度。"
  else
    echo "   [$dimension] 尚未完成，準備執行。"
  fi

  printf '%s\n' "$signature" > "$(signature_file "$dimension")"
  write_status "$dimension" "pending"
  write_meta "$dimension" "pending" "$signature" "$model"
  rm -f "$result"
}

run_agent() {
  local dimension=$1
  local model
  local instruction
  local result
  local log
  local tmp_result
  local signature
  local rc

  model="$(model_for "$dimension")"
  instruction="$(instruction_for "$dimension")"
  result="$(result_file "$dimension")"
  log="$(log_file "$dimension")"
  tmp_result="${result}.tmp"
  signature="$(cat "$(signature_file "$dimension")")"

  rm -f "$tmp_result"
  write_status "$dimension" "running"
  write_meta "$dimension" "running" "$signature" "$model"

  echo "   -> 啟動 [$dimension] 查核代理人 (模型: $model)"

  if gemini run --model "$model" "$instruction" < "$(prompt_file "$dimension")" > "$tmp_result" 2> "$log"; then
    rc=0
  else
    rc=$?
  fi

  if [ "$rc" -ne 0 ]; then
    rm -f "$tmp_result" "$result"
    write_status "$dimension" "failed"
    write_meta "$dimension" "failed" "$signature" "$model"
    echo "   ❌ [$dimension] 查核失敗，請查看 $(basename "$log")"
    return "$rc"
  fi

  if [ ! -s "$tmp_result" ]; then
    rm -f "$tmp_result" "$result"
    write_status "$dimension" "failed"
    write_meta "$dimension" "failed" "$signature" "$model"
    echo "   ❌ [$dimension] 結果為空，請查看 $(basename "$log")"
    return 1
  fi

  mv "$tmp_result" "$result"
  write_status "$dimension" "completed"
  write_meta "$dimension" "completed" "$signature" "$model"
  echo "   <- [$dimension] 查核完成"
}

echo "開始執行自動化調度 (工作目錄: $WORK_DIR)"
echo "檢查模板與 checkpoint 狀態..."

for dimension in "${DIMENSIONS[@]}"; do
  if [ ! -f "$(template_file "$dimension")" ]; then
    echo "錯誤：缺少樣板 $(template_file "$dimension")"
    exit 1
  fi
done

echo "具現化 Prompt 並比對斷點..."
for dimension in "${DIMENSIONS[@]}"; do
  prepare_dimension "$dimension"
done

PIDS=()
RUN_DIMENSIONS=()

echo "啟動需要補跑的維度..."
for dimension in "${DIMENSIONS[@]}"; do
  if [ "$(read_status "$dimension")" = "completed" ] && [ -s "$(result_file "$dimension")" ]; then
    continue
  fi

  run_agent "$dimension" &
  PIDS+=($!)
  RUN_DIMENSIONS+=("$dimension")
done

if [ ${#PIDS[@]} -eq 0 ]; then
  echo "所有維度皆已完成，直接沿用 checkpoint。"
else
  echo "等待補跑中的代理人完成..."
fi

failures=0
for index in "${!PIDS[@]}"; do
  pid="${PIDS[$index]}"
  dimension="${RUN_DIMENSIONS[$index]}"
  if wait "$pid"; then
    rc=0
  else
    rc=$?
  fi

  if [ "$rc" -ne 0 ]; then
    failures=$((failures + 1))
    echo "   ❌ [$dimension] 子程序退出碼: $rc"
  fi
done

incomplete=0
for dimension in "${DIMENSIONS[@]}"; do
  if [ "$(read_status "$dimension")" != "completed" ] || [ ! -s "$(result_file "$dimension")" ]; then
    incomplete=$((incomplete + 1))
    echo "   ❌ [$dimension] 尚未達成 completed checkpoint"
  fi
done

if [ "$failures" -gt 0 ] || [ "$incomplete" -gt 0 ]; then
  echo "調度失敗：仍有維度未完成。可在同一個工作目錄重新執行以從 checkpoint 恢復。"
  exit 1
fi

echo "四個維度均已完成。請查看 $WORK_DIR 目錄下的 result_*.md 與 checkpoint/ 後續彙整。"
