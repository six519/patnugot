#include <errno.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <string.h>

void terminate(const char *string);

typedef struct row_struct {
  int size;
  int rsize;
  char *chars;
  char *render;
} row_struct;

int s_x = 0;
int s_y = 0;
int r_x = 0;
int rows_count = 0;
int row_offset = 0;
int col_offset = 0;
row_struct *rows = NULL;
int tab_stop = 0;

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

void set_rx(int x)
{
  r_x = x;
}

int get_rx()
{
  return r_x;
}

void move_cursor()
{
  char cur_buff[32];
  snprintf(cur_buff, sizeof(cur_buff), "\x1b[%d;%dH", (s_y - row_offset) + 1, (r_x - col_offset) + 1);
  write(STDOUT_FILENO, cur_buff, strlen(cur_buff));
}

void update_row(row_struct *row) {
  int tabs = 0;
  int j;
  for (j = 0; j < row->size; j++)
    if (row->chars[j] == '\t') tabs++;
  free(row->render);
  row->render = malloc(row->size + tabs*(tab_stop - 1) + 1);
  int idx = 0;
  for (j = 0; j < row->size; j++) {
    if (row->chars[j] == '\t') {
      row->render[idx++] = ' ';
      while (idx % tab_stop != 0) row->render[idx++] = ' ';
    } else {
      row->render[idx++] = row->chars[j];
    }
  }
  row->render[idx] = '\0';
  row->rsize = idx;
}

void row_insert_char(row_struct *row, int index, int c)
{
  if (index < 0 || index > row->size) index = row->size;
  row->chars = realloc(row->chars, row->size + 2);
  memmove(&row->chars[index + 1], &row->chars[index], row->size - index + 1);
  row->size++;
  row->chars[index] = c;
  update_row(row);
}

void append_row(char *line, size_t length)
{
    rows = realloc(rows, sizeof(row_struct) * (rows_count + 1));
    int index = rows_count;
    rows[index].size = length;
    rows[index].chars = malloc(length + 1);
    memcpy(rows[index].chars, line, length);
    rows[index].chars[length] = '\0';
    rows[index].rsize = 0;
    rows[index].render = NULL;
    update_row(&rows[index]);
    rows_count++;
}

void insert_char(int c)
{
  if (s_y == rows_count)
  {
    append_row("", 0);
  }
  row_insert_char(&rows[s_y], s_x, c);
  s_x++;
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
    append_row(line, length);
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

int get_row_rsize(int index)
{
  return rows[index].rsize;
}

char *get_row_chars(int index, int col_off)
{
  return &rows[index].chars[col_off];
}

char *get_row_render(int index, int col_off)
{
  return &rows[index].render[col_off];
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

void set_tab_stop(int tstop)
{
  tab_stop = tstop;
}

void to_render()
{
  if (s_y < rows_count)
  {
    int rx = 0;
    int j;
    for (j = 0; j < s_x; j++) {
      if (rows[s_y].chars[j] == '\t')
        rx += (tab_stop - 1) - (rx % tab_stop);
      rx++;
    }
    r_x = rx;
  }
}

char *rows_to_string(int *buflen) 
{
  int totlen = 0;
  int j;
  for (j = 0; j < rows_count; j++)
    totlen += rows[j].size + 1;
  *buflen = totlen;
  char *buf = malloc(totlen);
  char *p = buf;
  for (j = 0; j < rows_count; j++) {
    memcpy(p, rows[j].chars, rows[j].size);
    p += rows[j].size;
    *p = '\n';
    p++;
  }
  return buf;
}

void rows_del_char(row_struct *row, int index)
{
  if (index < 0 || index >= row->size) return;
  memmove(&row->chars[index], &row->chars[index + 1], row->size - index);
  row->size--;
  update_row(row);
}

void del_char() {
  if (s_y == rows_count) return;
  if (s_x > 0) {
    rows_del_char(&rows[s_y], s_x - 1);
    s_x--;
  }
}