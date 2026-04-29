# Server-Side Setup Guide (English)

[🇷🇺 Русский](#русский) | [🇬🇧 English](#english)

---

<a name="english"></a>

## 🇬🇧 English

This guide will help you transform a basic VPS (even with 1GB RAM) into a secure environment for an AI agent.

## 1. System Preparation

### 1.1. Create Swap File

Node.js requires Swap to run stably on 1GB RAM.

```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 1.2. Create an Isolated User

```bash
sudo adduser --disabled-password --gecos "" gemini-user
```

## 2. Install Node.js & Gemini CLI

Switch to the new user:

```bash
sudo su - gemini-user
```

Install NVM and Node.js 24:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc
nvm install 24
npm install -g @google/gemini-cli
```

## 3. Create the "Black Box" (C Wrapper)

To prevent the AI from reading your API key, we compile it into a binary.

1. Create `gemini-safe.c`:

```c
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>

int main(int argc, char *argv[]) {
    setenv("GEMINI_API_KEY", "YOUR_API_KEY_HERE", 1);
    execv("/home/gemini-user/.nvm/versions/node/v24.15.0/bin/gemini", argv);
    perror("execv failed");
    return 1;
}
```

_Note: Find the path to `gemini` using `which gemini`._

2. Compile and set permissions:

```bash
gcc gemini-safe.c -o gemini-safe
sudo mv gemini-safe /usr/local/bin/gemini-safe
sudo chown root:gemini-user /usr/local/bin/gemini-safe
sudo chmod 710 /usr/local/bin/gemini-safe
rm gemini-safe.c
```

## 4. Setup the Receiver Script

Create a directory for temporary files and the script itself:

```bash
mkdir -p ~/src/tmp
nano ~/vps-reviewer.sh
```

Paste the `vps-reviewer.sh` code from your message. Make it executable:

```bash
chmod +x ~/vps-reviewer.sh
```

## 5. SSH Access Restriction (Critical!)

Edit your `~/.ssh/authorized_keys` file. Add a forced command prefix before your public key:

```text
command="/home/gemini-user/vps-reviewer.sh",no-port-forwarding,no-x11-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAAC3Nza...
```

_This ensures that this SSH key can only trigger the reviewer script and nothing else._

## 6. Security Policies

Create AI constraint files:

1. `/etc/gemini-cli/settings.json` — allow only necessary tools (`run_shell_command`, `read_file`).
2. `/etc/gemini-cli/SYSTEM.md` — define system instructions forbidding access to hidden folders.

---

<a name="russian"></a>

## 🇷🇺 Русский

Это руководство поможет вам превратить обычный VPS (даже с 1 ГБ ОЗУ) в защищенную среду для ИИ-агента.

## 1. Подготовка системы

### 1.1. Создание файла подкачки (Swap)

Для стабильной работы Node.js на 1 ГБ ОЗУ необходим Swap.

```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 1.2. Создание изолированного пользователя

```bash
sudo adduser --disabled-password --gecos "" gemini-user
```

## 2. Установка Node.js и Gemini CLI

Зайдите под созданного пользователя:

```bash
sudo su - gemini-user
```

Установите NVM и Node.js 24:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc
nvm install 24
npm install -g @google/gemini-cli
```

## 3. Создание защитной "черной коробки" (C Wrapper)

Чтобы ИИ не мог прочитать ваш API ключ, мы скомпилируем его в бинарный файл.

1. Создайте файл `gemini-safe.c`:

```c
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>

int main(int argc, char *argv[]) {
    setenv("GEMINI_API_KEY", "ВАШ_API_КЛЮЧ_ТУТ", 1);
    execv("/home/gemini-user/.nvm/versions/node/v24.15.0/bin/gemini", argv);
    perror("execv failed");
    return 1;
}
```

_Примечание: Путь к `gemini` можно узнать командой `which gemini`._

2. Скомпилируйте и настройте права:

```bash
gcc gemini-safe.c -o gemini-safe
sudo mv gemini-safe /usr/local/bin/gemini-safe
sudo chown root:gemini-user /usr/local/bin/gemini-safe
sudo chmod 710 /usr/local/bin/gemini-safe
rm gemini-safe.c
```

## 4. Настройка скрипта-приемника

Создайте папку для временных файлов и сам скрипт:

```bash
mkdir -p ~/src/tmp
nano ~/vps-reviewer.sh
```

Вставьте код скрипта `vps-reviewer.sh` из вашего сообщения. Не забудьте сделать его исполняемым:

```bash
chmod +x ~/vps-reviewer.sh
```

## 5. Ограничение доступа по SSH (Критично!)

Отредактируйте файл `~/.ssh/authorized_keys`. Добавьте перед вашим публичным ключом специальную команду:

```text
command="/home/gemini-user/vps-reviewer.sh",no-port-forwarding,no-x11-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAAC3Nza...
```

_Это гарантирует, что через этот SSH-ключ можно запустить только скрипт ревьюера._

## 6. Настройка политик безопасности

Создайте файлы ограничений для ИИ:

1. `/etc/gemini-cli/settings.json` — разрешите только нужные инструменты (`run_shell_command`, `read_file`).
2. `/etc/gemini-cli/SYSTEM.md` — пропишите системные инструкции, запрещающие доступ к скрытым папкам.


## Лицензия

Этот проект распространяется под лицензией [GNU General Public License v3.0 (GPL-3.0)](LICENSE).
