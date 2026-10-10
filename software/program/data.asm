.data 0x20

last_loaded: .word 0x0000

melody:
        .word 0x106, 0x106, 0x188, 0x188, 0x1B8, 0x1B8, 0x188
        .word 0x15D, 0x15D, 0x14A, 0x14A, 0x126, 0x126, 0x106
        .word 0x0000

ptr_help:        .word str_help
ptr_q:           .word str_q
ptr_nl:          .word str_nl
ptr_0x:          .word str_0x
ptr_col:         .word str_col
ptr_nf:          .word str_nf
ptr_usage_mem:   .word str_usage_mem
ptr_usage_dump:  .word str_usage_dump
ptr_usage_write: .word str_usage_write
ptr_usage_echo:  .word str_usage_echo
ptr_usage_clear: .word str_usage_clear
ptr_usage_beep:  .word str_usage_beep
ptr_usage_play:  .word str_usage_play
ptr_main_addr:   .word main
ptr_usage_load:  .word str_usage_load
ptr_usage_run:   .word str_usage_run
ptr_load_err:    .word str_load_err
ptr_load_ok:     .word str_load_ok
ptr_run_msg:     .word str_run_msg

str_q:           .string "?\n"
str_nl:          .string "\n"
str_0x:          .string "0x"
str_col:         .string ": "
str_nf:          .string ": not found\n"
str_usage_mem:   .string "usage: mem <hex addr>\n"
str_usage_dump:  .string "usage: dump <hex addr>\n"
str_usage_write: .string "usage: write <a> <v>\n"
str_usage_echo:  .string "usage: echo <text>\n"
str_usage_clear: .string "usage: clear\n"
str_usage_beep:  .string "usage: beep <freq>\n"
str_usage_play:  .string "usage: play\n"
str_help:        .string "help clear echo mem dump write beep play load run\n"
str_usage_load:  .string "usage: load <file>\n"
str_usage_run:   .string "usage: run <hex addr>\n"
str_load_err:    .string "load: cannot open file\n"
str_load_ok:     .string "loaded.\n"
str_run_msg:     .string "running...\n"

.text