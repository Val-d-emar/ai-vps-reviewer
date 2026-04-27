# 🤖 AI VPS Reviewer Action

## [🇷🇺 Русский](#русский) | [🇬🇧 English](#english)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

---

## English

<a name="english"></a>

**AI VPS Reviewer** is a GitHub Action for automated code review powered by Google Gemini, running on your own remote VPS.

### Key Features:

- **Security:** Your API keys and secrets never leave your VPS.
- **Performance:** Zero time wasted on installing dependencies (Node.js/Gemini CLI) on the GitHub Runner side.
- **Context-Aware:** Since it runs on a persistent VPS, the agent maintains conversation history for each PR.
- **Resource Efficient:** Works perfectly even on the smallest instances (1GB RAM).

### Quick Start

1.  Set up your server by following the [**detailed Server Setup Guide (vps-setup-howto.MD)**](vps-setup-howto.MD).
2.  Add the required secrets to your repository (`VPS_SSH_KEY`, `VPS_TARGET`, `ALLOWED_USERS`).
3.  Create a workflow file `.github/workflows/my-ai-review.yml`:

```yaml
name: Gemini AI Code Reviewer

on:
  pull_request:
    types: [review_requested]

jobs:
  review-code:
    # Recommended: run only for trusted actors
    if: github.actor == github.repository_owner
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write

    steps:
      - name: Gemini AI Review
        uses: Val-d-emar/ai-vps-reviewer@v1
        with:
          vps_ssh_key: ${{ secrets.VPS_SSH_KEY }}
          vps_target: ${{ secrets.VPS_TARGET }}
          vps_users: ${{ vars.ALLOWED_USERS }}
          review_language: "English"
          agent_model: "flash"
```

### Inputs

| Input               | Description                                          | Default   |
| :------------------ | :--------------------------------------------------- | :-------- |
| `vps_ssh_key`       | Private SSH key to access your VPS (**required**)    | -         |
| `vps_target`        | SSH target string like `user@host` (**required**)    | -         |
| `vps_users`         | Users of the action in the format `user,user2`       | nobody    |
| `agent_model`       | Gemini model (flash, pro)                            | `flash`   |
| `review_language`   | Language for the AI response                         | `English` |
| `approval_required` | If `true`, the agent will Approve or Request Changes | `false`   |

### Security Note

This action is designed with a "Security-First" approach. By using a restricted SSH `command=` on your VPS and a compiled C wrapper for API keys, you ensure that even if the SSH key is compromised, your server remains safe. See [vps-setup-howto.MD](vps-setup-howto.MD) for details.

## License

This project is licensed under the [GNU General Public License v3.0 (GPL-3.0)](LICENSE).

---

## Русский

**AI VPS Reviewer** — это GitHub Action для автоматического ревью кода с использованием Google Gemini, работающий на вашем собственном VPS.

### Основные преимущества:

- **Безопасность:** Ваши API-ключи и секреты никогда не покидают ваш VPS.
- **Скорость:** Не тратит время на установку зависимостей (Node.js/Gemini CLI) на стороне GitHub Runner.
- **Контекст:** Благодаря работе на VPS, агент сохраняет историю обсуждений для каждого PR.
- **Экономия:** Идеально работает даже на самых слабых инстансах (1GB RAM).

### Быстрый старт

1.  Настройте ваш сервер, следуя [**подробному руководству по настройке (vps-setup-howto.MD)**](vps-setup-howto.MD).
2.  Добавьте необходимые секреты в ваш репозиторий (`VPS_SSH_KEY`, `VPS_TARGET`, `ALLOWED_USERS`).
3.  Создайте workflow файл `.github/workflows/my-ai-review.yml`:

```yaml
name: Gemini AI Code Reviewer

on:
  pull_request:
    types: [review_requested]

jobs:
  review-code:
    # Рекомендуется запускать только для доверенных лиц
    if: github.actor == github.repository_owner
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write

    steps:
      - name: Gemini AI Review
        uses: Val-d-emar/ai-vps-reviewer@v1
        with:
          vps_ssh_key: ${{ secrets.VPS_SSH_KEY }}
          vps_target: ${{ secrets.VPS_TARGET }}
          vps_users: ${{ vars.ALLOWED_USERS }}
          review_language: "Russian"
          agent_model: "flash"
```

### Параметры (Inputs)

| Параметр            | Описание                                                    | По умолчанию |
| :------------------ | :---------------------------------------------------------- | :----------- |
| `vps_ssh_key`       | Приватный SSH ключ для доступа к VPS (**обязательно**)      | -            |
| `vps_target`        | Адрес сервера в формате `user@host` (**обязательно**)       | -            |
| `vps_users`         | Пользователи акшина в формате `user,user2`                  | никто        |
| `agent_model`       | Модель Gemini (flash, pro)                                  | `flash`      |
| `review_language`   | Язык ответа ИИ                                              | `English`    |
| `approval_required` | Если `true`, агент будет одобрять или запрашивать изменения | `false`      |

## Лицензия

Этот проект распространяется под лицензией [GNU General Public License v3.0 (GPL-3.0)](LICENSE).
