package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:unicode"

import "parser"
import "tokenizer"

logger := log.create_console_logger(opt = {.Terminal_Color})

main :: proc() {
	args := os.args
	context.logger = logger
	program_name := shift_args(&args).?
	input_name := shift_args(&args)
	if input_name == nil {
		usage(program_name)
		return
	}
	source, err := read_file(input_name.?)
	if err do return
	defer delete(source)
	tkn := tokenizer.Tokenizer {
		source = source,
	}
	ts, tokenizer_error := tokenizer.run(&tkn)
	if tokenizer_error.offset != -1 {
		col, row := offset_to_row_col(source, cast(int)tokenizer_error.offset)
		display_error(input_name.?, source, col, row, tokenizer_error.msg_fmt)
		return
	}
	defer delete(ts)

	arena_backing_data := [1024 * 10]u8{}
	arena := mem.Arena{}
	mem.arena_init(&arena, arena_backing_data[:])
	defer mem.arena_free_all(&arena)

	sliced := ts[:]
	prim_expr, parser_err := parser.parse_ast(&sliced, &arena)
	if parser_err.offset != -1 {
		col, row := offset_to_row_col(source, cast(int)parser_err.offset)
		display_error(input_name.?, source, col, row, parser_err.msg_fmt)
		return
	}
	log.debug(prim_expr)
}

display_error :: proc(source_name: string, source: string, col, row: int, msg: string) {
	lines, err := strings.split_lines(source)
	defer delete(lines)
	line := lines[col - 1]
	log.fatalf("./%s:%d:%d: %s", source_name, col, row, msg)
	log.fatal(line)
	log.fatalf("%*s^", row - 1, " ")
}


read_file :: proc(name: string) -> (string, bool) {
	content, err := os.read_entire_file(name)
	if !err {
		log.fatalf("Failed to either read or open the provided file")
		return "", true
	}
	return transmute(string)content, false
}

usage :: proc(program_name: string) {
	log.fatal("Input file not provided")
	log.fatal("USAGE:")
	log.fatalf("%s <input.bl>", program_name)
}

shift_args :: proc(args: ^[]string) -> Maybe(string) {
	if len(args) == 0 do return nil
	arg := args[0]
	args^ = args[1:]
	return arg
}

offset_to_row_col :: proc(text: string, offset: int) -> (int, int) {
	row, col := 1, 1
	for i in 0 ..< offset {
		if text[i] == '\n' {
			row += 1
			col = 1
		} else {
			col += 1
		}
	}
	return row, col
}
