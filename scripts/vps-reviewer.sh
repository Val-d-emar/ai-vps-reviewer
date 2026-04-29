#!/bin/bash
# Скрипт-приемник на VPS
export TERM=xterm-256color
export COLORTERM=truecolor

# БЕЗОПАСНЫЙ ПАРСИНГ
# Читаем строку, разделенную пробелами
read -r PR_NUMBER REPO_NAME USER_LANG MODEL PROMPT_B64 <<< "$SSH_ORIGINAL_COMMAND"

# Декодируем промпт обратно из Base64
USER_PROMPT=$(echo "$PROMPT_B64" | base64 -d)

# ВАЛИДАЦИЯ ПУТЕЙ (Защита от Path Traversal)
# PR_NUMBER должен состоять только из цифр
if [[ ! "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
    echo "Security Error: Invalid PR number format"
    exit 1
fi

# REPO_NAME должен быть в формате "owner/repo" (только буквы, цифры, тире, подчеркивания)
if [[ ! "$REPO_NAME" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
    echo "Security Error: Invalid Repository name format"
    exit 1
fi

# 1. Изолированная папка для PR
PR_WORKSPACE="/home/gemini-user/src/${REPO_NAME}/pr_${PR_NUMBER}"
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
# Используем +refs/... чтобы принудительно перезаписать локальную ветку, 
# даже если история коммитов изменилась (force push в PR)
git fetch --depth 1 origin "+refs/pull/${PR_NUMBER}/head:refs/heads/pr_branch" -q
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
