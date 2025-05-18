package main

import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"

logger := log.create_console_logger(opt = {.Level, .Terminal_Color})

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
	if !err do return
	log.debug(source)
}

read_file :: proc(name: string) -> (string, bool) {
	content, err := os.read_entire_file(name)
	if !err {
		log.fatalf("Failed to either read or open the provided file")
		return "", false
	}
	return strings.clone_from_bytes(content), true
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
