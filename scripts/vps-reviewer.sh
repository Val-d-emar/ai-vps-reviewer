#!/bin/bash
# Скрипт-приемник на VPS
export TERM=xterm-256color
export COLORTERM=truecolor
export GIT_PAGER=cat

# --- ПРОВЕРКА МЕСТА НА ДИСКЕ ---
# Получаем свободное место в КБ
FREE_KB=$(df /home/gemini-user --output=avail | tail -1)
MIN_KB=1048576 # 1 ГБ

if [ "$FREE_KB" -lt "$MIN_KB" ]; then
    echo "Low disk space! Running emergency cleanup..."
    # Удаляем папки, к которым не обращались больше 7 дней
    find /home/gemini-user/src -mindepth 2 -maxdepth 3 -type d -mtime +7 -exec rm -rf {} +
fi

# Удаляем папки, к которым не обращались больше 30 дней
# Зайди под gemini-user: sudo su - gemini-user
# Открой редактор крон-таблицы: crontab -e
# # Каждое воскресенье в 03:00 удалять папки в workspace старше 30 дней
# 0 3 * * 0 find /home/gemini-user/src -mindepth 2 -maxdepth 3 -type d -mtime +30 -exec rm -rf {} +

# Проверяем еще раз
FREE_KB=$(df /home/gemini-user --output=avail | tail -1)
if [ "$FREE_KB" -lt "$MIN_KB" ]; then
    echo "Error: Not enough disk space to proceed."
    exit 1
fi

# 1. Читаем аргументы
read -r PR_NUMBER REPO_NAME LANG_B64 MODEL_B64 PROMPT_B64 <<< "$SSH_ORIGINAL_COMMAND"

# Декодируем
USER_LANG=$(echo "$LANG_B64" | base64 -d)
MODEL=$(echo "$MODEL_B64" | base64 -d)
USER_PROMPT=$(echo "$PROMPT_B64" | base64 -d)

# Первая строка - это токен (или слово EMPTY)
read -r INCOMING_TOKEN

# ЛОГИКА ТОКЕНА
if [ "$INCOMING_TOKEN" != "EMPTY" ]; then
    export GH_TOKEN="$INCOMING_TOKEN"
    # Передаем токен через HTTP заголовок Authorization
    export GIT_CONFIG_PARAMETERS="'http.https://github.com/.extraHeader=AUTHORIZATION: basic $(echo -n "x-access-token:$GH_TOKEN" | base64 -w 0)'"
fi
# Если TOKEN_B64 == "EMPTY"
# система работает по старому сценарию (через gh-safe).

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

# Скачиваем коммит PR (он автоматически попадает в системный указатель FETCH_HEAD)
git fetch --depth 1 origin "pull/${PR_NUMBER}/head" -q

# Принудительно переключаем рабочую директорию на скачанный коммит
git checkout -qf FETCH_HEAD

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
  -y \
  -p "$FULL_PROMPT"

rm "$DIFF_FILE"
