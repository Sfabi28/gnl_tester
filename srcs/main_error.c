#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "get_next_line.h"

int main(void)
{
    char *line;


    line = get_next_line(-1);
    if (line != NULL)
    {
        printf("KO_NEG");
        free(line);
        return (1);
    }

    close(42); 
    
    line = get_next_line(42);
    if (line != NULL)
    {
        printf("KO_CLOSED");
        free(line);
        return (1);
    }

    printf("OK");
    return (0);
}