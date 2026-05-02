#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
    setenv("GEMINI_CLI_SYSTEM_SETTINGS_PATH", "/etc/gemini-cli/settings.json", 1);
    setenv("GEMINI_SYSTEM_MD", "/etc/gemini-cli/SYSTEM.md", 1);

    setenv("GEMINI_API_KEY", "AIza.....................", 1);
    execv("/home/gemini-user/.nvm/versions/node/v24.15.0/bin/gemini", argv);
    perror("execv failed");
    return 1;
}
