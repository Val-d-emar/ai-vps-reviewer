#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
    // Устанавливаем токен в окружение процесса
    setenv("GH_TOKEN", "ghp_", 1);

    // Запускаем оригинальный gh, передавая все аргументы
    execv("/usr/bin/gh", argv);

    // Если execv вернул управление, значит произошла ошибка
    perror("execv failed");
    return 1;
}
