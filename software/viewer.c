#include <windows.h>
#include <string.h>
#include <stdio.h>
#include "shared.h"

SharedScreen   *shared_screen = NULL;
SharedKeyboard *shared_kbd    = NULL;

int view_top = 0;
int follow_bottom = 1;         // 是否自动跟随底部
int cursor_visible = 1;        // 光标闪烁状态
int last_cursor_row = -1;      // 光标上一次所在的行，用于局部刷新
int last_cursor_col = -1;

COLORREF color_map(int c) {
    switch (c) {
        case COLOR_CYAN:   return RGB(0, 255, 255);
        case COLOR_RED:    return RGB(255, 80, 80);
        case COLOR_WHITE:  return RGB(255, 255, 255);
        case COLOR_YELLOW: return RGB(255, 255, 0);
        case COLOR_BLUE:    return RGB(0x89, 0xB4, 0xFA);   // 天蓝
        case COLOR_MAGENTA: return RGB(0xF5, 0xC2, 0xE7);   // 粉紫
        case COLOR_GREY:    return RGB(0x6C, 0x70, 0x86);   // 暗灰
        default:           return RGB(0, 255, 0);
    }
}

void update_scrollbar(HWND hwnd) {
    SCROLLINFO si = {0};
    si.cbSize = sizeof(si);
    si.fMask  = SIF_RANGE | SIF_PAGE | SIF_POS;
    si.nMin   = 0;
    si.nMax   = SCREEN_ROWS - 1;
    si.nPage  = VIEW_ROWS;
    si.nPos   = view_top;
    SetScrollInfo(hwnd, SB_VERT, &si, TRUE);
}

int auto_top() {
    return (shared_screen->cursor_y >= VIEW_ROWS)
         ? shared_screen->cursor_y - VIEW_ROWS + 1
         : 0;
}

void invalidate_cursor_cell(HWND hwnd) {
    if (last_cursor_row < 0) return;
    int vr = last_cursor_row - view_top;
    if (vr < 0 || vr >= VIEW_ROWS) return;

    RECT r;
    r.left   = 10 + last_cursor_col * 8;
    r.top    = 10 + vr * 20;
    r.right  = r.left + 8;
    r.bottom = r.top + 20;
    InvalidateRect(hwnd, &r, FALSE);
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
        case WM_CREATE:
            update_scrollbar(hwnd);
            return 0;

        case WM_CHAR: {
            static DWORD last_tick = 0;
            static WPARAM last_key = 0;

            DWORD now = GetTickCount();
            // 30ms 内重复的同字符忽略
            if (wParam == last_key && (now - last_tick) < 30) {
                return 0;
            }
            last_key = wParam;
            last_tick = now;

            if (shared_kbd) {
                int next = (shared_kbd->head + 1) % KB_BUF_SIZE;
                if (next != shared_kbd->tail) {
                    shared_kbd->buf[shared_kbd->head] = (unsigned char)wParam;
                    shared_kbd->head = next;
                }
            }
            follow_bottom = 1;
            return 0;
        }

        case WM_VSCROLL: {
            // 用户动了滚动条，取消自动跟随
            follow_bottom = 0;

            int newpos = view_top;
            switch (LOWORD(wParam)) {
                case SB_LINEUP:    newpos -= 1;   break;
                case SB_LINEDOWN:  newpos += 1;   break;
                case SB_PAGEUP:    newpos -= VIEW_ROWS; break;
                case SB_PAGEDOWN:  newpos += VIEW_ROWS; break;
                case SB_THUMBTRACK:
                case SB_THUMBPOSITION:
                    newpos = HIWORD(wParam);
                    break;
            }
            if (newpos < 0) newpos = 0;
            int max_top = SCREEN_ROWS - VIEW_ROWS;
            if (newpos > max_top) newpos = max_top;
            view_top = newpos;
            update_scrollbar(hwnd);
            InvalidateRect(hwnd, NULL, FALSE);
            return 0;
        }

        case WM_PAINT: {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);

            // 双缓冲
            HDC hdcMem = CreateCompatibleDC(hdc);
            HBITMAP hbmMem = CreateCompatibleBitmap(hdc,
                ps.rcPaint.right - ps.rcPaint.left,
                ps.rcPaint.bottom - ps.rcPaint.top);
            HBITMAP hbmOld = SelectObject(hdcMem, hbmMem);

            SetViewportOrgEx(hdcMem, -ps.rcPaint.left, -ps.rcPaint.top, NULL);

            RECT bg = { ps.rcPaint.left, ps.rcPaint.top,
                        ps.rcPaint.right, ps.rcPaint.bottom };
            HBRUSH hbBg = CreateSolidBrush(RGB(0x1E, 0x1E, 0x2E));
            FillRect(hdcMem, &bg, hbBg);
            DeleteObject(hbBg);

            SetBkMode(hdcMem, TRANSPARENT);

            HFONT hFont = CreateFontA(
                20, 8, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
                DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                DEFAULT_QUALITY, FIXED_PITCH | FF_MODERN, "Consolas");
            HFONT hOldFont = (HFONT)SelectObject(hdcMem, hFont);

            if (shared_screen) {
                int first_row = (ps.rcPaint.top - 10) / 20;
                int last_row  = (ps.rcPaint.bottom - 10) / 20;
                if (first_row < 0) first_row = 0;
                if (last_row >= VIEW_ROWS) last_row = VIEW_ROWS - 1;

                for (int row = first_row; row <= last_row; row++) {
                    int abs_row = view_top + row;
                    if (abs_row >= SCREEN_ROWS) break;

                    int y = 10 + row * 20;

                    int col = 0;
                    while (col < SCREEN_COLS) {
                        char c = shared_screen->ch[abs_row][col];
                        if (c == ' ' || c == '\0') { col++; continue; }

                        int color_id = shared_screen->color[abs_row][col];
                        SetTextColor(hdcMem, color_map(color_id));

                        int start = col;
                        while (col < SCREEN_COLS
                            && shared_screen->ch[abs_row][col] != ' '
                            && shared_screen->ch[abs_row][col] != '\0'
                            && shared_screen->color[abs_row][col] == color_id) {
                            col++;
                        }
                        TextOutA(hdcMem, 10 + start * 8, y,
                                 &shared_screen->ch[abs_row][start], col - start);
                    }
                }

                // 光标
                int cy = shared_screen->cursor_y;
                int cx = shared_screen->cursor_x;
                if (cursor_visible
                    && cy >= view_top && cy < view_top + VIEW_ROWS) {
                    int vr = cy - view_top;
                    if (vr >= first_row && vr <= last_row) {
                        RECT cr;
                        cr.left   = 10 + cx * 8;
                        cr.top    = 10 + vr * 20;
                        cr.right  = cr.left + 8;
                        cr.bottom = cr.top + 20;
                        HBRUSH cur = CreateSolidBrush(RGB(0xA6, 0xE3, 0xA1));
                        FillRect(hdcMem, &cr, cur);
                        DeleteObject(cur);
                    }
                }

                // 记住光标位置，方便下一次局部刷新
                last_cursor_row = cy;
                last_cursor_col = cx;
            }

            SelectObject(hdcMem, hOldFont);
            DeleteObject(hFont);

            BitBlt(hdc, ps.rcPaint.left, ps.rcPaint.top,
                   ps.rcPaint.right - ps.rcPaint.left,
                   ps.rcPaint.bottom - ps.rcPaint.top,
                   hdcMem, ps.rcPaint.left, ps.rcPaint.top, SRCCOPY);

            SelectObject(hdcMem, hbmOld);
            DeleteObject(hbmMem);
            DeleteDC(hdcMem);

            EndPaint(hwnd, &ps);
            return 0;
        }

        case WM_TIMER: {
            if (!shared_screen) return 0;

            // ---- 光标闪烁（ID=2）----
            if (wParam == 2) {
                cursor_visible = !cursor_visible;
                invalidate_cursor_cell(hwnd);
                return 0;
            }

            // ---- 脏行刷新（ID=1）----
            // 自动跟随底部
            if (follow_bottom) {
                int at = auto_top();
                if (at != view_top) {
                    view_top = at;
                    update_scrollbar(hwnd);
                    InvalidateRect(hwnd, NULL, FALSE);
                }
            }

            for (int r = 0; r < SCREEN_ROWS; r++) {
                if (shared_screen->dirty[r]) {
                    shared_screen->dirty[r] = 0;
                    int vr = r - view_top;
                    if (vr >= 0 && vr < VIEW_ROWS) {
                        RECT rect;
                        rect.left   = 0;
                        rect.top    = 10 + vr * 20;
                        rect.right  = 10 + SCREEN_COLS * 8 + 10;
                        rect.bottom = rect.top + 20;
                        InvalidateRect(hwnd, &rect, FALSE);
                    }
                }
            }

            return 0;
        }

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;
    }
    return DefWindowProc(hwnd, msg, wParam, lParam);
}

int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrev, LPSTR cmd, int show) {
    HANDLE hScreen = NULL, hKbd = NULL;
    for (int i = 0; i < 20; i++) {
        hScreen = OpenFileMappingA(FILE_MAP_ALL_ACCESS, FALSE, SHM_SCREEN);
        hKbd    = OpenFileMappingA(FILE_MAP_ALL_ACCESS, FALSE, SHM_KEYBOARD);
        if (hScreen && hKbd) break;
        Sleep(500);
    }
    if (!hScreen || !hKbd) {
        MessageBoxA(NULL,
            "Cannot open shared memory. Start vm.exe first.",
            "Error", MB_OK);
        return 1;
    }

    shared_screen = (SharedScreen*)MapViewOfFile(
        hScreen, FILE_MAP_ALL_ACCESS, 0, 0, sizeof(SharedScreen));
    shared_kbd = (SharedKeyboard*)MapViewOfFile(
        hKbd, FILE_MAP_ALL_ACCESS, 0, 0, sizeof(SharedKeyboard));

    WNDCLASSA wc = {0};
    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = hInst;
    wc.lpszClassName = "CPUViewer";
    wc.hCursor       = LoadCursor(NULL, IDC_ARROW);
    RegisterClassA(&wc);

    HWND hwnd = CreateWindowA(
        "CPUViewer", "My CPU Screen",
        WS_OVERLAPPEDWINDOW | WS_VSCROLL,
        100, 100, 700, 600,
        NULL, NULL, hInst, NULL);

    ShowWindow(hwnd, show);

    // 两个定时器
    SetTimer(hwnd, 1, 50, NULL);    // 脏行刷新
    SetTimer(hwnd, 2, 500, NULL);   // 光标闪烁

    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    KillTimer(hwnd, 1);
    KillTimer(hwnd, 2);

    UnmapViewOfFile(shared_screen);
    UnmapViewOfFile(shared_kbd);
    CloseHandle(hScreen);
    CloseHandle(hKbd);
    return 0;
}