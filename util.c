#include <errno.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>

void terminate(const char *string);

int read_key()
{
  int ret_size;
  char input_char;
  while ((ret_size = read(STDIN_FILENO, &input_char, 1)) != 1)
  {
    if (ret_size == -1 && errno != EAGAIN) terminate("read_key");
  }
  if (input_char == '\x1b') {
    char seq[3];
    if (read(STDIN_FILENO, &seq[0], 1) != 1) return '\x1b';
    if (read(STDIN_FILENO, &seq[1], 1) != 1) return '\x1b';
    if (seq[0] == '[') {
      switch (seq[1]) {
        case 'A': return 1000;
        case 'B': return 1001;
        case 'C': return 1002;
        case 'D': return 1003;
      }
    }
    return '\x1b';
  } else {
    return input_char;
  }
}

int get_size(int *screen_rows, int *screen_cols)
{
  struct winsize wsize;
  if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &wsize) == -1 || wsize.ws_col == 0) 
  {
    return -1;
  } 
  else
  {
    *screen_cols = wsize.ws_col;
    *screen_rows = wsize.ws_row;
    return 0;
  }
}