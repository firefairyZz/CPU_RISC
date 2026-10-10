#ifndef SHARED_H
#define SHARED_H

#define SHM_SCREEN   "MyCPU_Screen"
#define SHM_KEYBOARD "MyCPU_Keyboard"

#define SCREEN_ROWS 1000    // 内部历史行数
#define VIEW_ROWS   25      // 窗口可见行数
#define SCREEN_COLS 80
#define KB_BUF_SIZE 64

// 颜色代码
#define COLOR_GREEN  0
#define COLOR_CYAN   1
#define COLOR_RED    2
#define COLOR_WHITE  3
#define COLOR_YELLOW 4
#define COLOR_BLUE   5
#define COLOR_MAGENTA 6
#define COLOR_GREY   7

typedef struct {
    char          ch[SCREEN_ROWS][SCREEN_COLS];
    unsigned char color[SCREEN_ROWS][SCREEN_COLS];
    unsigned char dirty[SCREEN_ROWS];    // 每行一个标志位
    int cursor_x;
    int cursor_y;
    int scroll_offset;
} SharedScreen;

typedef struct {
    unsigned char buf[KB_BUF_SIZE];
    int head;   // 写指针
    int tail;   // 读指针
} SharedKeyboard;

#endif