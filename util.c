#include <errno.h>
#include <unistd.h>

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