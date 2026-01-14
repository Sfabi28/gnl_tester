#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include "get_next_line_bonus.h"

int main(int argc, char **argv)
{
    int     fd1;
    int     fd2;
    char    *line1;
    char    *line2;
    int     active1 = 1;
    int     active2 = 1;

    if (argc != 3)
    {
        printf("Serve passare due file: ./tester file1 file2\n");
        return (1);
    }

    fd1 = open(argv[1], O_RDONLY);
    fd2 = open(argv[2], O_RDONLY);

    if (fd1 == -1 || fd2 == -1)
    {
        printf("Errore apertura file\n");
        return (1);
    }

    while (active1 || active2)
    {
        if (active1)
        {
            line1 = get_next_line(fd1);
            if (line1)
            {
                printf("%s", line1);
                free(line1);
            }
            else
                active1 = 0;
        }

        if (active2)
        {
            line2 = get_next_line(fd2);
            if (line2)
            {
                printf("%s", line2);
                free(line2);
            }
            else
                active2 = 0;
        }
    }

    close(fd1);
    close(fd2);
    return (0);
}