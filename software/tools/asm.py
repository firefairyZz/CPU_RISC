#!/usr/bin/env python3
"""16 位 CPU 汇编器，支持 .data / .string / .word / 标签"""

import sys
import re
import os

OPCODES = {
    'ADD':   0b0000, 'SUB':   0b0001, 'AND':   0b0010, 'OR':    0b0011,
    'XOR':   0b0100, 'SHL':   0b0101, 'SHR':   0b0110, 'CMP':   0b0111,
    'LOADI': 0b1000, 'ADDI':  0b1001, 'SUBI':  0b1010, 'HLT':   0b1011,
    'JMP':   0b1100, 'JZ':    0b1101, 'LOAD':  0b1110, 'STORE': 0b1111,
}
R_TYPE = {'ADD', 'SUB', 'AND', 'OR', 'XOR', 'SHL', 'SHR'}
I_TYPE = {'LOADI', 'ADDI', 'SUBI'}
M_TYPE = {'LOAD', 'STORE'}

def expand_includes(lines, base_dir):
    """递归展开 .include "file.asm" """
    out = []
    for line in lines:
        m = re.match(r'^\s*\.include\s+"([^"]+)"\s*$', line.strip())
        if m:
            sub_path = os.path.join(base_dir, m.group(1))
            if not os.path.exists(sub_path):
                raise ValueError(f"include not found: {sub_path}")
            with open(sub_path, encoding='utf-8') as f:
                sub_lines = f.readlines()
            out.extend(expand_includes(sub_lines, os.path.dirname(sub_path)))
        else:
            out.append(line)
    return out

def strip_comment(line):
    for marker in (';', '//'):
        if marker in line:
            line = line[:line.index(marker)]
    return line.strip()


def parse_reg(s):
    s = s.strip().rstrip(',').strip('[]')
    m = re.match(r'^[Rr](\d+)$', s)
    if not m:
        raise ValueError(f"bad register: {s}")
    n = int(m.group(1))
    if n < 0 or n > 15:
        raise ValueError(f"register out of range: {s}")
    return n


def parse_imm(s, labels=None):
    s = s.strip().rstrip(',').replace('#', '').replace('$', '')
    if labels is not None and s in labels:
        return labels[s] & 0xFF
    if s.startswith('-'):
        return (-int(s[1:], 0)) & 0xFF
    return int(s, 0) & 0xFF


def parse_addr(s, labels=None, width=12):
    s = s.strip().rstrip(',').replace('#', '').replace('$', '')
    mask = (1 << width) - 1
    if labels is not None and s in labels:
        return labels[s] & mask
    if s.startswith('-'):
        return (-int(s[1:], 0)) & mask
    return int(s, 0) & mask


def split_label(line):
    m = re.match(r'^\s*([A-Za-z_]\w*)\s*:\s*(.*)$', line)
    if m:
        return m.group(1), m.group(2)
    return None, line


def unescape_string(s):
    out = []
    i = 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            c = s[i + 1]
            if c == 'n': out.append('\n'); i += 2; continue
            if c == 'r': out.append('\r'); i += 2; continue
            if c == 't': out.append('\t'); i += 2; continue
            if c == '0': out.append('\0'); i += 2; continue
            if c == '\\': out.append('\\'); i += 2; continue
            if c == '"': out.append('"'); i += 2; continue
        out.append(s[i])
        i += 1
    return ''.join(out)


def match_string(rest):
    m = re.match(r'\.string\s+"(.*)"\s*$', rest)
    if not m:
        raise ValueError(f"bad .string: {rest}")
    return unescape_string(m.group(1))


def resolve_word_value(v, labels):
    v = v.strip()
    if labels is not None and v in labels:
        return labels[v] & 0xFFFF
    return int(v, 0) & 0xFFFF


def assemble(lines):
    # ---- 第一遍：扫标签 ----
    labels = {}
    code_pc = 0
    data_pc = 0x20
    data_start = 0x20
    in_data = False

    for raw in lines:
        line = strip_comment(raw)
        if not line:
            continue

        if line.startswith('.data'):
            parts = line.split()
            if len(parts) >= 2:
                data_start = int(parts[1], 0)
                data_pc = data_start
            in_data = True
            continue
        if line.startswith('.text'):
            in_data = False
            continue
        if line.startswith('.org'):
            addr = int(line[4:].strip(), 0)
            if in_data:
                data_pc = addr
            else:
                code_pc = addr
            continue

        label, rest = split_label(line)
        if label:
            labels[label] = data_pc if in_data else code_pc

        rest = rest.strip()
        if not rest:
            continue

        if rest.startswith('.string'):
            data_pc += len(match_string(rest)) + 1
            continue
        if rest.startswith('.word'):
            data_pc += len(rest[5:].split(','))
            continue
        if not in_data:
            code_pc += 1

    # ---- 第二遍：编码 ----
    code_out = []
    data_out = []
    in_data = False
    data_start = 0x20

    for raw in lines:
        line = strip_comment(raw)
        if not line:
            continue

        if line.startswith('.data'):
            parts = line.split()
            if len(parts) >= 2:
                data_start = int(parts[1], 0)
            in_data = True
            continue
        if line.startswith('.text'):
            in_data = False
            continue
        if line.startswith('.org'):
            addr = int(line[4:].strip(), 0)
            if in_data:
                target_len = addr - data_start
                if target_len < len(data_out):
                    raise ValueError(f".org 0x{addr:X} overlaps previous data")
                while len(data_out) < target_len:
                    data_out.append("0000")
            else:
                if addr < len(code_out):
                    raise ValueError(f".org 0x{addr:X} overlaps previous code")
                while len(code_out) < addr:
                    code_out.append("0000")
            continue

        _, rest = split_label(line)
        rest = rest.strip()
        if not rest:
            continue

        if rest.startswith('.string'):
            s = match_string(rest)
            for ch in s:
                data_out.append(f"{ord(ch) & 0xFF:04X}")
            data_out.append("0000")
            continue
        if rest.startswith('.word'):
            for v in rest[5:].split(','):
                data_out.append(f"{resolve_word_value(v, labels):04X}")
            continue
        if in_data:
            continue

        parts = rest.replace('[', ' ').replace(']', ' ')
        parts = parts.replace(',', ' ').split()
        mnemonic = parts[0].upper()
        args = parts[1:]

        if mnemonic == 'CALL':
            addr = parse_addr(args[0], labels, 10)
            code_out.append(f"{(0b1100 << 12) | (0b01 << 10) | addr:04X}")
            continue
        if mnemonic == 'RET':
            code_out.append(f"{(0b1100 << 12) | (0b11 << 10):04X}")
            continue
        if mnemonic == 'JZ':
            addr = parse_addr(args[0], labels, 10)
            code_out.append(f"{(0b1101 << 12) | (0b00 << 10) | addr:04X}")
            continue
        if mnemonic == 'JN':
            addr = parse_addr(args[0], labels, 10)
            code_out.append(f"{(0b1101 << 12) | (0b01 << 10) | addr:04X}")
            continue
        if mnemonic not in OPCODES:
            raise ValueError(f"unknown mnemonic: {mnemonic}")

        op = OPCODES[mnemonic]

        if mnemonic in R_TYPE:
            rd, rs1, rs2 = parse_reg(args[0]), parse_reg(args[1]), parse_reg(args[2])
            code_out.append(f"{(op << 12) | (rd << 8) | (rs1 << 4) | rs2:04X}")
        elif mnemonic == 'CMP':
            rs1, rs2 = parse_reg(args[0]), parse_reg(args[1])
            code_out.append(f"{(op << 12) | (rs1 << 4) | rs2:04X}")
        elif mnemonic in I_TYPE:
            rd = parse_reg(args[0])
            imm = parse_imm(args[1], labels)
            code_out.append(f"{(op << 12) | (rd << 8) | imm:04X}")
        elif mnemonic == 'HLT':
            code_out.append(f"{op << 12:04X}")
        elif mnemonic == 'JMP':
            arg = args[0].strip()
            if re.match(r'^[Rr]\d+$', arg):
                reg = parse_reg(arg)
                code_out.append(f"{(op << 12) | (0b10 << 10) | (reg << 4):04X}")
            else:
                addr = parse_addr(arg, labels, 10)
                code_out.append(f"{(op << 12) | addr:04X}")
        elif mnemonic in M_TYPE:
            rd, rs1 = parse_reg(args[0]), parse_reg(args[1])
            code_out.append(f"{(op << 12) | (rd << 8) | (rs1 << 4):04X}")
        else:
            raise ValueError(f"unhandled: {mnemonic}")

    return code_out, data_out, labels

def disassemble(lines):
    output = []
    for i, line in enumerate(lines):
        line = strip_comment(line)
        if not line:
            continue
        word = int(line, 16)
        op  = (word >> 12) & 0xF
        rd  = (word >> 8)  & 0xF
        rs1 = (word >> 4)  & 0xF
        rs2 = word & 0xF

        if word == 0x0000:
            output.append(f"{'NOP':36s} ; addr {i:03d}")
            continue
        if op == 0xC:
            mode = (word >> 10) & 0b11
            if mode == 0b11:   asm = "RET"
            elif mode == 0b10: asm = f"JMP     R{(word >> 4) & 0xF}"
            elif mode == 0b01: asm = f"CALL    0x{word & 0x3FF:03X}"
            else:              asm = f"JMP     0x{word & 0x3FF:03X}"
        elif op == 0xD:
            mode = (word >> 10) & 0b11
            addr = word & 0x3FF
            if mode == 0:   asm = f"JZ      0x{addr:03X}"
            elif mode == 1: asm = f"JN      0x{addr:03X}"
            else:           asm = f"JC?     0x{addr:03X}"
        elif op == 0x0: asm = f"ADD     R{rd}, R{rs1}, R{rs2}"
        elif op == 0x1: asm = f"SUB     R{rd}, R{rs1}, R{rs2}"
        elif op == 0x2: asm = f"AND     R{rd}, R{rs1}, R{rs2}"
        elif op == 0x3: asm = f"OR      R{rd}, R{rs1}, R{rs2}"
        elif op == 0x4: asm = f"XOR     R{rd}, R{rs1}, R{rs2}"
        elif op == 0x5: asm = f"SHL     R{rd}, R{rs1}, R{rs2}"
        elif op == 0x6: asm = f"SHR     R{rd}, R{rs1}, R{rs2}"
        elif op == 0x7: asm = f"CMP     R{rs1}, R{rs2}"
        elif op == 0x8:
            imm = word & 0xFF
            asm = (f"LOADI   R{rd}, {imm - 0x100:4d}    ; 0x{imm:02X}"
                   if imm >= 0x80 else f"LOADI   R{rd}, {imm}")
        elif op == 0x9:
            imm = word & 0xFF
            asm = (f"ADDI    R{rd}, {imm - 0x100:4d}    ; 0x{imm:02X}"
                   if imm >= 0x80 else f"ADDI    R{rd}, {imm}")
        elif op == 0xA:
            imm = word & 0xFF
            asm = (f"SUBI    R{rd}, {imm - 0x100:4d}    ; 0x{imm:02X}"
                   if imm >= 0x80 else f"SUBI    R{rd}, {imm}")
        elif op == 0xB: asm = "HLT"
        elif op == 0xE: asm = f"LOAD    R{rd}, R{rs1}"
        elif op == 0xF: asm = f"STORE   R{rd}, R{rs1}"
        else:           asm = f"UNKNOWN 0x{word:04X}"
        output.append(f"{asm:36s} ; addr {i:03d}")
    return output


def main():
    if len(sys.argv) < 3:
        print("usage: python asm.py a program.asm program.mem")
        sys.exit(1)
    mode = sys.argv[1].lower()
    if mode == 'a':
        if len(sys.argv) < 4:
            print("usage: python asm.py a program.asm program.mem")
            sys.exit(1)
        in_path = sys.argv[2]
        with open(in_path, encoding='utf-8') as f:
            lines = f.readlines()
        lines = expand_includes(lines, os.path.dirname(os.path.abspath(in_path)))
        code, data, labels = assemble(lines)
        with open(sys.argv[3], 'w', encoding='utf-8') as f:
            f.write("#CODE\n")
            f.write('\n'.join(code) + '\n')
            f.write("#DATA 0x20\n")
            f.write('\n'.join(data) + '\n')
        print(f"code: {len(code)} instr, data: {len(data)} words")
        if labels:
            print(f"labels: {labels}")
    elif mode == 'b':
        if len(sys.argv) < 4:
            print("usage: python asm.py b program.asm program.bin")
            sys.exit(1)
        in_path = sys.argv[2]
        with open(in_path, encoding='utf-8') as f:
            lines = f.readlines()
        lines = expand_includes(lines, os.path.dirname(os.path.abspath(in_path)))
        code, data, labels = assemble(lines)
        with open(sys.argv[3], 'wb') as f:
            # 只输出代码段（数据段假设程序自己初始化，或者放在代码后面）
            for w in code:
                value = int(w, 16)
                f.write(bytes([value & 0xFF, (value >> 8) & 0xFF]))
        print(f"binary: {len(code)} words -> {sys.argv[3]}")
    elif mode == 'd':
        with open(sys.argv[2], encoding='utf-8') as f:
            lines = f.readlines()
        clean = [ln for ln in lines if not ln.startswith('#')]
        for line in disassemble(clean):
            print(line)
    else:
        print(f"unknown mode: {mode}")
        sys.exit(1)


if __name__ == '__main__':
    main()