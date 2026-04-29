#!/bin/bash
# Скрипт-приемник на VPS
export TERM=xterm-256color
export COLORTERM=truecolor

# Парсим аргументы из SSH_ORIGINAL_COMMAND
eval set -- "$SSH_ORIGINAL_COMMAND"

PR_NUMBER=$1
REPO_NAME=$2
USER_LANG=$3
USER_PROMPT=$4
MODEL=$5

# 1. Изолированная папка для PR
PR_WORKSPACE="/home/gemini-user/workspace/${REPO_NAME}/pr_${PR_NUMBER}"
mkdir -p "$PR_WORKSPACE"
cd "$PR_WORKSPACE" || exit 1

# 2. Получение кода
if [ ! -d .git ]; then
    git init -q
    git remote add origin "https://github.com/${REPO_NAME}.git"
fi

# Скачиваем код. 
# Если репозиторий приватный, git сам вызовет наш credential.helper (!/usr/local/bin/gh-safe auth git-credential),
# получит токен бота ai-agent-net из памяти C-обертки и успешно скачает код.
git fetch --depth 1 origin pull/${PR_NUMBER}/head:pr_branch -q

# Переключаемся на ветку PR
git checkout -qf pr_branch

# 3. Сохраняем дифф
DIFF_FILE="gemini_diff.diff"
cat > "$DIFF_FILE"

if [ ! -s "$DIFF_FILE" ]; then
    echo "Error: Received empty diff on VPS"
    rm "$DIFF_FILE"
    exit 1
fi

# 4. Формируем промпт
FULL_PROMPT="Use ${USER_LANG} language for answer. ${USER_PROMPT} 
The specific changes to review are in @${DIFF_FILE}. 
You are currently in the root directory of the project. You can explore other files in this repository to understand the context of these changes."

# 5. Запускаем Gemini
/usr/local/bin/gemini-safe \
  -r latest \
  -m "$MODEL" \
  -p "$FULL_PROMPT"

# Убираем дифф
rm "$DIFF_FILE"
