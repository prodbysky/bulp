package tests

import "core:mem"
import "core:testing"

import "../parser"
import "../tokenizer"


@(test)
basic_binary_expressions :: proc(t: ^testing.T) {
	SOURCE :: "34 + 35\n"
	tkn := tokenizer.Tokenizer {
		source = SOURCE,
	}
	ts, err := tokenizer.run(&tkn)
	defer delete(ts)
	testing.expect_value(t, err.offset, -1)
	sliced := ts[:]
	arena_backing_data := [1024 * 10]u8{}
	arena := mem.Arena{}
	mem.arena_init(&arena, arena_backing_data[:])
	defer mem.arena_free_all(&arena)
	ast, er := parser.parse_expr(&sliced, 0, &arena)
	testing.expect_value(t, er.offset, -1)
}

@(test)
not_so_basic_binary_expressions :: proc(t: ^testing.T) {
	SOURCE :: "(34 + 2) * 35\n"
	tkn := tokenizer.Tokenizer {
		source = SOURCE,
	}
	ts, err := tokenizer.run(&tkn)
	defer delete(ts)
	testing.expect_value(t, err.offset, -1)
	sliced := ts[:]
	arena_backing_data := [1024 * 10]u8{}
	arena := mem.Arena{}
	mem.arena_init(&arena, arena_backing_data[:])
	ast, er := parser.parse_expr(&sliced, 0, &arena)
	defer mem.arena_free_all(&arena)
	testing.expect_value(t, er.offset, -1)
}

@(test)
return_statement :: proc(t: ^testing.T) {
	SOURCE :: "return 1;\n"
	tkn := tokenizer.Tokenizer {
		source = SOURCE,
	}
	ts, err := tokenizer.run(&tkn)
	defer delete(ts)
	testing.expect_value(t, err.offset, -1)
	sliced := ts[:]
	arena_backing_data := [1024 * 10]u8{}
	arena := mem.Arena{}
	mem.arena_init(&arena, arena_backing_data[:])
	defer mem.arena_free_all(&arena)
	ast, er := parser.parse_ast(&sliced, &arena)
	defer delete(ast)
	testing.expect_value(t, er.offset, -1)
	testing.expect_value(t, len(ast), 1)
	testing.expect_value(t, ast[0].st_type, parser.StatementType.Return)
}
