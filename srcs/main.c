#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include "get_next_line.h"

int main(int argc, char **argv)
{
    char    marker = '\x04';

    int     fd;
    char    *line;

    if (argc >= 2)
    {
        fd = open(argv[1], O_RDONLY);
        if (fd == -1)
        {
            printf("Error opening file");
            return (1);
        }
    }
    else
        fd = 0;

    while ((line = get_next_line(fd)))
    {
        printf("%s", line);
        putchar(marker);
        free(line);
    }
    
    if (argc >= 2)
        close(fd);
        
    return (0);
}