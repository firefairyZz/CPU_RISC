#!/usr/bin/env python3
"""
16 位 CPU 的汇编器 / 反汇编器

用法:
    汇编:   python asm.py a program.asm program.mem
    反汇编: python asm.py d program.mem
"""

import sys
import re

OPCODES = {
    'ADD':   0b0000, 'SUB':   0b0001, 'AND':   0b0010, 'OR':    0b0011,
    'XOR':   0b0100, 'SHL':   0b0101, 'SHR':   0b0110, 'CMP':   0b0111,
    'LOADI': 0b1000, 'ADDI':  0b1001, 'SUBI':  0b1010, 'HLT':   0b1011,
    'JMP':   0b1100, 'JZ':    0b1101, 'LOAD':  0b1110, 'STORE': 0b1111,
}

R_TYPE = {'ADD', 'SUB', 'AND', 'OR', 'XOR', 'SHL', 'SHR'}
I_TYPE = {'LOADI', 'ADDI', 'SUBI'}
J_TYPE = {'JMP', 'JZ'}
M_TYPE = {'LOAD', 'STORE'}


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


def split_label(line):
    m = re.match(r'^\s*([A-Za-z_]\w*)\s*:\s*(.*)$', line)
    if m:
        return m.group(1), m.group(2)
    return None, line


def assemble(lines):
    # ---- 第一遍：扫标签 ----
    labels = {}
    pc = 0
    for raw in lines:
        line = strip_comment(raw)
        if not line:
            continue
        label, rest = split_label(line)
        if label:
            labels[label] = pc
        if rest.strip():
            pc += 1

    # ---- 第二遍：编码 ----
    output = []
    for raw in lines:
        line = strip_comment(raw)
        if not line:
            continue
        _, rest = split_label(line)
        line = rest.strip()
        if not line:
            continue

        line = line.replace('[', ' ').replace(']', ' ')
        parts = line.replace(',', ' ').split()
        if not parts:
            continue

        mnemonic = parts[0].upper()
        args = parts[1:]

        # ---- CALL 和 RET 特殊处理（复用 JMP 操作码 0b1100）----
        if mnemonic == 'CALL':
            if len(args) != 1:
                raise ValueError(f"CALL needs 1 operand: {line}")
            addr = parse_imm(args[0], labels) & 0x3FF
            word = (0b1100 << 12) | 0b0100_0000_0000 | addr
            output.append(f"{word:04X}")
            continue

        if mnemonic == 'RET':
            word = (0b1100 << 12) | 0b1100_0000_0000
            output.append(f"{word:04X}")
            continue

        if mnemonic not in OPCODES:
            raise ValueError(f"unknown mnemonic: {mnemonic}")

        op = OPCODES[mnemonic]

        if mnemonic in R_TYPE:
            if len(args) != 3:
                raise ValueError(f"{mnemonic} needs 3 operands: {line}")
            rd, rs1, rs2 = parse_reg(args[0]), parse_reg(args[1]), parse_reg(args[2])
            word = (op << 12) | (rd << 8) | (rs1 << 4) | rs2

        elif mnemonic == 'CMP':
            if len(args) != 2:
                raise ValueError(f"CMP needs 2 operands: {line}")
            rs1, rs2 = parse_reg(args[0]), parse_reg(args[1])
            word = (op << 12) | (0 << 8) | (rs1 << 4) | rs2

        elif mnemonic in I_TYPE:
            if len(args) != 2:
                raise ValueError(f"{mnemonic} needs 2 operands: {line}")
            rd = parse_reg(args[0])
            imm = parse_imm(args[1], labels)
            word = (op << 12) | (rd << 8) | imm

        elif mnemonic == 'HLT':
            word = op << 12

        elif mnemonic == 'JMP':
            if len(args) != 1:
                raise ValueError(f"JMP needs 1 operand: {line}")
            arg = args[0].strip()
            if re.match(r'^[Rr]\d+$', arg):
                reg = parse_reg(arg)
                word = (op << 12) | 0b1000_0000_0000 | (reg << 4)
            else:
                addr = parse_imm(arg, labels) & 0x3FF
                word = (op << 12) | addr

        elif mnemonic == 'JZ':
            if len(args) != 1:
                raise ValueError(f"JZ needs 1 operand: {line}")
            addr = parse_imm(args[0], labels) & 0xFFF
            word = (op << 12) | addr

        elif mnemonic in M_TYPE:
            if len(args) != 2:
                raise ValueError(f"{mnemonic} needs 2 operands: {line}")
            rd, rs1 = parse_reg(args[0]), parse_reg(args[1])
            word = (op << 12) | (rd << 8) | (rs1 << 4)

        else:
            raise ValueError(f"unhandled: {mnemonic}")

        output.append(f"{word:04X}")

    return output, labels


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
            if mode == 0b11:
                asm = "RET"
            elif mode == 0b10:
                asm = f"JMP     R{(word >> 4) & 0xF}"
            elif mode == 0b01:
                asm = f"CALL    0x{word & 0x3FF:03X}"
            else:
                asm = f"JMP     0x{word & 0x3FF:03X}"

        elif op == 0xD:
            asm = f"JZ      0x{word & 0xFFF:03X}"

        elif op == 0x0:
            asm = f"ADD     R{rd}, R{rs1}, R{rs2}"
        elif op == 0x1:
            asm = f"SUB     R{rd}, R{rs1}, R{rs2}"
        elif op == 0x2:
            asm = f"AND     R{rd}, R{rs1}, R{rs2}"
        elif op == 0x3:
            asm = f"OR      R{rd}, R{rs1}, R{rs2}"
        elif op == 0x4:
            asm = f"XOR     R{rd}, R{rs1}, R{rs2}"
        elif op == 0x5:
            asm = f"SHL     R{rd}, R{rs1}, R{rs2}"
        elif op == 0x6:
            asm = f"SHR     R{rd}, R{rs1}, R{rs2}"
        elif op == 0x7:
            asm = f"CMP     R{rs1}, R{rs2}"

        elif op == 0x8:
            imm = word & 0xFF
            if imm >= 0x80:
                asm = f"LOADI   R{rd}, {imm - 0x100:4d}    ; 0x{imm:02X}"
            else:
                asm = f"LOADI   R{rd}, {imm}"
        elif op == 0x9:
            imm = word & 0xFF
            if imm >= 0x80:
                asm = f"ADDI    R{rd}, {imm - 0x100:4d}    ; 0x{imm:02X}"
            else:
                asm = f"ADDI    R{rd}, {imm}"
        elif op == 0xA:
            imm = word & 0xFF
            if imm >= 0x80:
                asm = f"SUBI    R{rd}, {imm - 0x100:4d}    ; 0x{imm:02X}"
            else:
                asm = f"SUBI    R{rd}, {imm}"

        elif op == 0xB:
            asm = "HLT"

        elif op == 0xE:
            asm = f"LOAD    R{rd}, R{rs1}"
        elif op == 0xF:
            asm = f"STORE   R{rd}, R{rs1}"

        else:
            asm = f"UNKNOWN 0x{word:04X}"

        output.append(f"{asm:36s} ; addr {i:03d}")

    return output


def main():
    if len(sys.argv) < 3:
        print("usage:")
        print("  assemble:    python asm.py a program.asm program.mem")
        print("  disassemble: python asm.py d program.mem")
        sys.exit(1)

    mode = sys.argv[1].lower()

    if mode == 'a':
        if len(sys.argv) < 4:
            print("usage: python asm.py a program.asm program.mem")
            sys.exit(1)
        in_file, out_file = sys.argv[2], sys.argv[3]
        with open(in_file, encoding='utf-8') as f:
            lines = f.readlines()
        result, labels = assemble(lines)
        with open(out_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(result) + '\n')
        print(f"assembled {len(result)} instructions -> {out_file}")
        if labels:
            print(f"labels: {labels}")

    elif mode == 'd':
        in_file = sys.argv[2]
        with open(in_file, encoding='utf-8') as f:
            lines = f.readlines()
        for line in disassemble(lines):
            print(line)

    else:
        print(f"unknown mode: {mode}")
        sys.exit(1)


if __name__ == '__main__':
    main()