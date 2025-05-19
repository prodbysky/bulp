package main

import "core:fmt"
import "core:log"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:unicode"

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
	tkn := tokenizer.Tokenizer {
		source = source,
		loc    = 0,
	}
	ts, tokenizer_error := tokenizer.run(&tkn)
	if tokenizer_error.offset != -1 {
		col, row := offset_to_row_col(source, cast(int)tokenizer_error.offset)
		lines, err := strings.split_lines(source)
		line := lines[col - 1]
		log.fatalf("./%s:%d:%d: %s", input_name, col, row, tokenizer_error.msg_fmt)
		log.fatal(line)
		log.fatalf("%*s^", row - 1, " ")
		return
	}
	log.debug(ts)
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
