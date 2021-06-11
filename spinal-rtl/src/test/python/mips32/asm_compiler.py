from ctypes import c_uint32
from sys import argv
import re

code_map = {
    'ADD'  : '000_000',
    'SUB'  : '000_001',
    'AND'  : '000_010',
    'OR'   : '000_011',
    'SLT'  : '000_100',
    'MUL'  : '000_101',
    'HLT'  : '011_111',
    'LW'   : '001_000',
    'SW'   : '001_001',
    'ADDI' : '001_010',
    'SUBI' : '001_011',
    'SLTI' : '001_100',
    'BNEQZ': '001_101',
    'BEQZ' : '001_110',
}
type_map = {
    'ADD'  : 'REG_TYPE',
    'SUB'  : 'REG_TYPE',
    'AND'  : 'REG_TYPE',
    'OR'   : 'REG_TYPE',
    'SLT'  : 'REG_TYPE',
    'MUL'  : 'REG_TYPE',
    'HLT'  : 'HLT_TYPE',
    'LW'   : 'BASE_TYPE',
    'SW'   : 'BASE_TYPE',
    'ADDI' : 'IMM_TYPE',
    'SUBI' : 'IMM_TYPE',
    'SLTI' : 'IMM_TYPE',
    'BNEQZ': 'JMP_TYPE',
    'BEQZ' : 'JMP_TYPE',
}
label_map = {}

def bin_str(int_str):
    return format(c_uint32(int(int_str)).value, 'b').zfill(32)

def op_code(input_code):
    return code_map[input_code.upper()].replace('_', '')

def op_type(input_code):
    return type_map[input_code.upper()]

def remove_R(reg_str):
    return reg_str.upper().replace('R', '')

def reg_type_func(input_list, line_no, abs_line_no):
    assert len(input_list) == 4, "4 args needed for REG_TYPE at line: {0}".format(line_no)
    op = input_list[0]
    oc = op_code(op)
    reg_list = list(map(remove_R, input_list[1:]))
    (rd, rs, rt) = list(map(bin_str, reg_list))
    return oc + rs[-5:] + rt[-5:] + rd[-5:] + '00000000000'

def imm_type_func(input_list, line_no, abs_line_no):
    assert len(input_list) == 4, "4 args needed for IMM_TYPE at line: {0}".format(line_no)
    op = input_list[0]
    oc = op_code(op)
    reg_list = list(map(remove_R, input_list[1:]))
    (rt, rs, imm) = list(map(bin_str, reg_list))
    return oc + rs[-5:] + rt[-5:] + imm[-16:]

def base_type_func(input_list, line_no, abs_line_no):
    assert len(input_list) == 3, "3 args needed for BASE_TYPE at line: {0}".format(line_no)
    op = input_list[0]
    oc = op_code(op)
    reg_list = list(map(remove_R, input_list[1:]))
    (rt, source) = reg_list
    assert '(' in source, "missing '(' at line: {0}".format(line_no)
    assert ')' in source, "missing ')' at line: {0}".format(line_no)
    for r in (('(', ' '), (')', '')):
        source = source.replace(*r)
    (imm, rs) = source.split()
    reg_list = [rt, imm, rs]
    (rt, imm, rs) = list(map(bin_str, reg_list))
    return oc + rs[-5:] + rt[-5:] + imm[-16:]

def hlt_type_func(input_list, line_no, abs_line_no):
    assert len(input_list) == 1, "1 arg needed for HLT_TYPE at line: {0}".format(line_no)
    op = input_list[0]
    oc = op_code(op)
    return oc + '00000000000000000000000000'

def jmp_type_func(input_list, line_no, abs_line_no):
    assert len(input_list) == 3, "3 args needed for JMP_TYPE at line: {0}".format(line_no)
    op = input_list[0]
    oc = op_code(op)
    rs = remove_R(input_list[1])
    label = input_list[2]
    assert label in label_map, "undefined label: {0} at line: {1}".format(label, line_no)
    imm =  str(label_map[label] - abs_line_no - 1)
    return oc + bin_str(rs)[-5:] + '00000' + bin_str(imm)[-16:]

def op_type_func(input_type):
    func_map = {
        'REG_TYPE' : reg_type_func,
        'IMM_TYPE' : imm_type_func,
        'BASE_TYPE': base_type_func,
        'HLT_TYPE' : hlt_type_func,
        'JMP_TYPE' : jmp_type_func,
    }
    return func_map[input_type]

with open(argv[1]) as file:
    lines = [(line_no + 1, line.strip()) for line_no, line in enumerate(file)]
    code_lines = list(filter(lambda elm:
                                not (elm[1].startswith('#') or len(elm[1]) == 0),
                             lines))

    line_dict = {}
    for abs_line_no, elm in enumerate(code_lines):
        (line_no, line) = elm
        clean_line = line.split('#')[0].strip()
        label = ''
        if ':' in clean_line:
            split_res = clean_line.split(':')
            assert len(split_res) == 2, "only one colon allowed at line: {0}".format(line_no)
            (label, clean_line) = list(map(lambda s: s.strip(), split_res))
            assert label not in label_map, "duplicated label: {0} at line: {1}".format(label, line_no)
            label_map[label] = abs_line_no
        line_dict[abs_line_no] = (line_no, clean_line)

    for abs_line_no, elm in line_dict.items():
        (line_no, clean_line) = elm
        # print(line_no, abs_line_no, clean_line)

        parts = clean_line.split(',')
        op_parts = re.split('\s+', parts[0])
        op = op_parts[0]
        assert op in code_map, "unknown code op: {0} at line: {1}".format(op, line_no)
        assert op in type_map, "unknown type op: {0} at line: {1}".format(op, line_no)
        opt = op_type(op)
        line_parts = list(map(lambda s: re.sub('\s+', '', s), op_parts + parts[1:]))
        inst = op_type_func(opt)(line_parts, line_no, abs_line_no)
        print(inst, '\t// ', abs_line_no + 1, ':\t', lines[line_no - 1][1])
        # print(hex(int(inst, 2)), '\t// ', line_no, ':\t', lines[line_no - 1][1])
