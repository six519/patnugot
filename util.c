#include <errno.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <string.h>

void terminate(const char *string);

typedef struct row_struct {
  int size;
  char *chars;
} row_struct;

int s_x = 0;
int s_y = 0;
int rows_count = 0;
int row_offset = 0;
int col_offset = 0;
row_struct *rows = NULL;

int read_key()
{
  const int ARROW_UP = 1000;
  const int ARROW_DOWN = 1001;
  const int ARROW_RIGHT = 1002;
  const int ARROW_LEFT = 1003;
  const int HOME_KEY = 1004;
  const int DEL_KEY = 1005;
  const int END_KEY = 1006;
  const int PAGE_UP = 1007;
  const int PAGE_DOWN = 1008;
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
      if (seq[1] >= '0' && seq[1] <= '9') {
        if (read(STDIN_FILENO, &seq[2], 1) != 1) return '\x1b';
        if (seq[2] == '~') {
          switch (seq[1]) {
            case '1': return HOME_KEY;
            case '3': return DEL_KEY;
            case '4': return END_KEY;
            case '5': return PAGE_UP;
            case '6': return PAGE_DOWN;
            case '7': return HOME_KEY;
            case '8': return END_KEY;
          }
        }
      } else {
        switch (seq[1]) {
          case 'A': return ARROW_UP;
          case 'B': return ARROW_DOWN;
          case 'C': return ARROW_RIGHT;
          case 'D': return ARROW_LEFT;
          case 'H': return HOME_KEY;
          case 'F': return END_KEY;
        }
      }
    } else if (seq[0] == 'O') {
      switch (seq[1]) {
        case 'H': return HOME_KEY;
        case 'F': return END_KEY;
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

void set_xy(int x, int y)
{
  s_x = x;
  s_y = y;
}

int get_x()
{
  return s_x;
}

int get_y()
{
  return s_y;
}

void move_cursor()
{
  char cur_buff[32];
  snprintf(cur_buff, sizeof(cur_buff), "\x1b[%d;%dH", (s_y - row_offset) + 1, (s_x - col_offset) + 1);
  write(STDOUT_FILENO, cur_buff, strlen(cur_buff));
}

void open_editor(char *filename)
{
  FILE *file_pointer = fopen(filename, "r");
  if (!file_pointer) terminate("fopen");
  char *line = NULL;
  size_t linecap = 0;
  ssize_t length;
  while ((length = getline(&line, &linecap, file_pointer)) != -1) {
    while (length > 0 && (line[length - 1] == '\n' || line[length - 1] == '\r'))
      length--;

    rows = realloc(rows, sizeof(row_struct) * (rows_count + 1));
    int index = rows_count;
    rows[index].size = length;
    rows[index].chars = malloc(length + 1);
    memcpy(rows[index].chars, line, length);
    rows[index].chars[length] = '\0';
    rows_count++;
  }
  free(line);
  fclose(file_pointer);
}

int get_rows_count()
{
  return rows_count;
}

int get_row_size(int index)
{
  return rows[index].size;
}

char *get_row_chars(int index, int col_off)
{
  return &rows[index].chars[col_off];
}

int get_row_offset()
{
  return row_offset;
}

void set_row_offset(int n)
{
  row_offset = n;
}

int get_col_offset()
{
  return col_offset;
}

void set_col_offset(int n)
{
  col_offset = n;
}