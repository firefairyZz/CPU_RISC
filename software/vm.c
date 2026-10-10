#include <stdio.h>
#include <string.h>
#include <windows.h>
#include "shared.h"

unsigned short rom[4096];
unsigned short memory[4096];
int regs[16];
int pc = 0;
int halted = 0;
int zero_flag = 0;
int neg_flag = 0;

// 栈
unsigned short stack[256];
int sp = 0xFF;

// 共享内存
SharedScreen   *shared_screen = NULL;
SharedKeyboard *shared_kbd    = NULL;
unsigned char current_color = COLOR_GREEN;

// 文件加载
FILE *load_file = NULL;
int load_status = 0;   // 0=OK, 1=error, 2=EOF

long long instr_count = 0;

int sign_extend_8(int imm) {
    if (imm & 0x80) return imm - 0x100;
    return imm;
}

void mark_row_dirty(int row) {
    if (row < 0 || row >= SCREEN_ROWS) return;
    shared_screen->dirty[row] = 1;
}

int main() {
    // ========== 加载程序到 ROM ==========
    FILE *f = fopen("program.mem", "r");
    if (!f) {
        printf("cannot open program.mem\n");
        return 1;
    }
    char line[256];
    int rom_addr = 0;
    int data_addr = 0;
    int in_data = 0;
    while (fgets(line, sizeof(line), f)) {
        char *p = line;
        while (*p == ' ' || *p == '\t') p++;
        if (*p == '#') {
            if (strncmp(p, "#CODE", 5) == 0) {
                in_data = 0;
            } else if (strncmp(p, "#DATA", 5) == 0) {
                unsigned int base;
                if (sscanf(p + 5, "%x", &base) == 1) data_addr = base;
                in_data = 1;
            }
            continue;
        }
        unsigned int word;
        if (sscanf(p, "%x", &word) != 1) continue;
        if (in_data) {
            if (data_addr < 4096) memory[data_addr] = (unsigned short)word;
            data_addr++;
        } else {
            if (rom_addr < 4096) rom[rom_addr] = (unsigned short)word;
            rom_addr++;
        }
    }
    fclose(f);
    printf("loaded %d code, %d data words\n", rom_addr, data_addr);

    // ========== 初始化共享内存 ==========
    HANDLE hScreen = CreateFileMappingA(
        INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE,
        0, sizeof(SharedScreen), SHM_SCREEN);
    if (hScreen == NULL) {
        printf("CreateFileMapping (screen) failed: %lu\n", GetLastError());
        return 1;
    }
    shared_screen = (SharedScreen*)MapViewOfFile(
        hScreen, FILE_MAP_ALL_ACCESS, 0, 0, sizeof(SharedScreen));
    if (shared_screen == NULL) {
        printf("MapViewOfFile (screen) failed: %lu\n", GetLastError());
        return 1;
    }

    memset(shared_screen->ch, ' ', sizeof(shared_screen->ch));
    memset(shared_screen->color, COLOR_GREEN, sizeof(shared_screen->color));
    memset(shared_screen->dirty, 0, sizeof(shared_screen->dirty));
    shared_screen->cursor_x = 0;
    shared_screen->cursor_y = 0;
    shared_screen->scroll_offset = 0;

    HANDLE hKbd = CreateFileMappingA(
        INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE,
        0, sizeof(SharedKeyboard), SHM_KEYBOARD);
    if (hKbd == NULL) {
        printf("CreateFileMapping (kbd) failed: %lu\n", GetLastError());
        return 1;
    }
    shared_kbd = (SharedKeyboard*)MapViewOfFile(
        hKbd, FILE_MAP_ALL_ACCESS, 0, 0, sizeof(SharedKeyboard));
    if (shared_kbd == NULL) {
        printf("MapViewOfFile (kbd) failed: %lu\n", GetLastError());
        return 1;
    }

    shared_kbd->head = 0;
    shared_kbd->tail = 0;

    printf("shared memory created\n");
    printf("now run viewer.exe, then type commands IN THE WINDOW\n\n");

    // ========== 主循环 ==========
    while (!halted) {
        instr_count++;
        if ((instr_count & 0x3FFF) == 0) {
            Sleep(0);
        }

        unsigned short instr = rom[pc];
        pc++;

        int opcode = (instr >> 12) & 0xF;
        int rd     = (instr >> 8)  & 0xF;
        int rs1    = (instr >> 4)  & 0xF;
        int rs2    = instr & 0xF;

        switch (opcode) {
            case 0x0: regs[rd] = regs[rs1] + regs[rs2]; break;
            case 0x1: regs[rd] = regs[rs1] - regs[rs2]; break;
            case 0x2: regs[rd] = regs[rs1] & regs[rs2]; break;
            case 0x3: regs[rd] = regs[rs1] | regs[rs2]; break;
            case 0x4: regs[rd] = regs[rs1] ^ regs[rs2]; break;
            case 0x5: regs[rd] = regs[rs1] << regs[rs2]; break;
            case 0x6: regs[rd] = regs[rs1] >> regs[rs2]; break;

            case 0x7: {
                int result = regs[rs1] - regs[rs2];
                zero_flag = (result == 0) ? 1 : 0;
                neg_flag  = (result < 0)  ? 1 : 0;
                break;
            }

            case 0x8: regs[rd] = sign_extend_8(instr & 0xFF); break;
            case 0x9: regs[rd] = regs[rd] + sign_extend_8(instr & 0xFF); break;
            case 0xA: regs[rd] = regs[rd] - sign_extend_8(instr & 0xFF); break;

            case 0xB: halted = 1; break;

            case 0xC: {
                int mode = (instr >> 10) & 0x3;
                if (mode == 0x0) {
                    pc = instr & 0x3FF;
                } else if (mode == 0x1) {
                    sp--;
                    stack[sp] = pc;
                    pc = instr & 0x3FF;
                } else if (mode == 0x2) {
                    pc = regs[(instr >> 4) & 0xF];
                } else {
                    pc = stack[sp];
                    sp++;
                }
                break;
            }

            case 0xD: {
                int mode = (instr >> 10) & 0x3;
                int addr = instr & 0x3FF;
                if (mode == 0) {
                    if (zero_flag) pc = addr;
                } else if (mode == 1) {
                    if (neg_flag) pc = addr;
                }
                break;
            }

            case 0xE: {  // LOAD
                int a = regs[rs1] & 0xFFF;

                if (a == 0xFFD) {
                    regs[rd] = (shared_kbd->head != shared_kbd->tail) ? 1 : 0;
                }
                else if (a == 0xFFE) {
                    if (shared_kbd->head != shared_kbd->tail) {
                        regs[rd] = shared_kbd->buf[shared_kbd->tail];
                        shared_kbd->tail = (shared_kbd->tail + 1) % KB_BUF_SIZE;
                    } else {
                        regs[rd] = 0;
                    }
                }
                else if (a == 0xFF7) {   // 文件状态
                    regs[rd] = load_status;
                }
                else if (a == 0xFFF) {
                    regs[rd] = 0;
                }
                else {
                    regs[rd] = memory[a];
                }
                break;
            }

            case 0xF: {  // STORE
                int a = regs[rd] & 0xFFF;
                memory[a] = (unsigned short)regs[rs1];

                if (a == 0xFF9) {
                    // 打开文件：从 RAM 中取文件名
                    int name_addr = regs[rs1] & 0xFFF;
                    char fname[64];
                    int i = 0;
                    while (i < 63 && memory[name_addr + i] != 0) {
                        fname[i] = (char)(memory[name_addr + i] & 0xFF);
                        i++;
                    }
                    fname[i] = 0;
                    if (load_file) { fclose(load_file); load_file = NULL; }
                    load_file = fopen(fname, "rb");
                    if (load_file) {
                        load_status = 0;
                        printf("[LOAD: opened '%s']\n", fname);
                    } else {
                        load_status = 1;
                        printf("[LOAD: cannot open '%s']\n", fname);
                    }
                }
                else if (a == 0xFF8) {
                    // 从文件读一个字（2 字节，小端）到 RAM
                    int dst = regs[rs1] & 0xFFF;
                    if (!load_file) {
                        load_status = 1;
                    } else {
                        unsigned char lo, hi;
                        if (fread(&lo, 1, 1, load_file) != 1 ||
                            fread(&hi, 1, 1, load_file) != 1) {
                            load_status = 2;  // EOF
                        } else {
                            memory[dst] = (unsigned short)(lo | (hi << 8));
                            load_status = 0;
                        }
                    }
                }
                else if (a == 0xFFA) {
                    int freq = regs[rs1] & 0xFFFF;
                    if (freq > 0 && freq < 20000) {
                        Beep(freq, 100);
                    }
                }
                else if (a == 0xFFB) {
                    memset(shared_screen->ch, ' ', sizeof(shared_screen->ch));
                    memset(shared_screen->color, COLOR_GREEN, sizeof(shared_screen->color));
                    memset(shared_screen->dirty, 1, sizeof(shared_screen->dirty));
                    shared_screen->cursor_x = 0;
                    shared_screen->cursor_y = 0;
                }
                else if (a == 0xFFC) {
                    current_color = regs[rs1] & 0xFF;
                }
                else if (a == 0xFFF) {
                    int ch = regs[rs1] & 0xFF;

                    if (ch == 13) {
                        shared_screen->cursor_x = 0;
                        mark_row_dirty(shared_screen->cursor_y);
                    }
                    else if (ch == 10) {
                        mark_row_dirty(shared_screen->cursor_y);
                        shared_screen->cursor_y++;
                        shared_screen->cursor_x = 0;
                        mark_row_dirty(shared_screen->cursor_y);

                        if (shared_screen->cursor_y >= SCREEN_ROWS) {
                            memmove(&shared_screen->ch[0][0],
                                    &shared_screen->ch[1][0],
                                    (SCREEN_ROWS - 1) * SCREEN_COLS);
                            memmove(&shared_screen->color[0][0],
                                    &shared_screen->color[1][0],
                                    (SCREEN_ROWS - 1) * SCREEN_COLS);
                            memset(&shared_screen->ch[SCREEN_ROWS - 1][0],
                                   ' ', SCREEN_COLS);
                            memset(&shared_screen->color[SCREEN_ROWS - 1][0],
                                   COLOR_GREEN, SCREEN_COLS);
                            shared_screen->cursor_y = SCREEN_ROWS - 1;
                            memset(shared_screen->dirty, 1, sizeof(shared_screen->dirty));
                        }
                    }
                    else if (ch == 8) {
                        if (shared_screen->cursor_x > 0) {
                            shared_screen->cursor_x--;
                            shared_screen->ch[shared_screen->cursor_y][shared_screen->cursor_x] = ' ';
                        }
                        mark_row_dirty(shared_screen->cursor_y);
                    }
                    else {
                        if (shared_screen->cursor_x < SCREEN_COLS) {
                            shared_screen->ch[shared_screen->cursor_y][shared_screen->cursor_x] = (char)ch;
                            shared_screen->color[shared_screen->cursor_y][shared_screen->cursor_x] = current_color;
                            shared_screen->cursor_x++;
                        }
                        mark_row_dirty(shared_screen->cursor_y);
                    }
                }
                break;
            }

            default:
                printf("\nunknown opcode 0x%X at pc=%d\n", opcode, pc - 1);
                halted = 1;
                break;
        }
    }

    printf("\n\n--- halted ---\n");
    printf("Press Enter to exit...\n");
    getchar();

    if (load_file) fclose(load_file);
    UnmapViewOfFile(shared_screen);
    UnmapViewOfFile(shared_kbd);
    CloseHandle(hScreen);
    CloseHandle(hKbd);
    return 0;
}