#!/bin/bash
# Скрипт-приемник на VPS
export TERM=xterm-256color
export COLORTERM=truecolor

# 1. Читаем аргументы
read -r PR_NUMBER REPO_NAME LANG_B64 MODEL_B64 PROMPT_B64 <<< "$SSH_ORIGINAL_COMMAND"

# Декодируем
USER_LANG=$(echo "$LANG_B64" | base64 -d)
MODEL=$(echo "$MODEL_B64" | base64 -d)
USER_PROMPT=$(echo "$PROMPT_B64" | base64 -d)

# 2. ЖЕСТКАЯ ВАЛИДАЦИЯ (Защита VPS)
if [[ ! "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
    echo "Security Error: Invalid PR number"
    exit 1
fi

if [[ ! "$REPO_NAME" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
    echo "Security Error: Invalid Repository name"
    exit 1
fi

# Модель должна содержать только буквы, цифры, тире и точки (например, gemini-1.5-flash)
if [[ ! "$MODEL" =~ ^[a-zA-Z0-9.-]+$ ]]; then
    echo "Security Error: Invalid Model name format"
    exit 1
fi

# Язык должен содержать только буквы, цифры, пробелы и тире (например, Russian, English-US)
if [[ ! "$USER_LANG" =~ ^[a-zA-Z0-9\ -]+$ ]]; then
    echo "Security Error: Invalid Language format"
    exit 1
fi

# 3. Изолированная папка
PR_WORKSPACE="/home/gemini-user/src/${REPO_NAME}/pr_${PR_NUMBER}"
mkdir -p "$PR_WORKSPACE"
cd "$PR_WORKSPACE" || exit 1

# 4. Безопасный Git Fetch
if [ ! -d .git ]; then
    git init -q
    git remote add origin "https://github.com/${REPO_NAME}.git"
fi

git fetch --depth 1 origin "+refs/pull/${PR_NUMBER}/head:refs/heads/pr_branch" -q
git checkout -qf pr_branch

# 5. Сохраняем дифф
DIFF_FILE="gemini_diff.diff"
cat > "$DIFF_FILE"

if [ ! -s "$DIFF_FILE" ]; then
    echo "Error: Received empty diff on VPS"
    rm "$DIFF_FILE"
    exit 1
fi

# 6. Формируем промпт (строковая подстановка безопасна, так как не выполняется)
FULL_PROMPT="Use ${USER_LANG} language for answer. ${USER_PROMPT} 
The specific changes to review are in @${DIFF_FILE}. 
You are currently in the root directory of the project. You can explore other files in this repository to understand the context of these changes."

# 7. Запуск
/usr/local/bin/gemini-safe \
  -r latest \
  -m "$MODEL" \
  -p "$FULL_PROMPT"

rm "$DIFF_FILE"
