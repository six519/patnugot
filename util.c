#include <errno.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>

void terminate(const char *string);

char read_key()
{
  int ret_size;
  char input_char;
  while ((ret_size = read(STDIN_FILENO, &input_char, 1)) != 1)
  {
    if (ret_size == -1 && errno != EAGAIN) terminate("read_key");
  }
  return input_char;
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