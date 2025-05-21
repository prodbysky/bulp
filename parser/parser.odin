package parser

import "../tokenizer"
import "core:fmt"
import "core:mem"

NodeType :: enum {
	BinaryExpr,
	Number,
}

Node :: struct {
	loc:   u64,
	type:  NodeType,
	value: union {
		u64,
		BinaryExpr,
	},
}
BinaryExpr :: struct {
	left:  ^Node,
	op:    tokenizer.BinaryOperator,
	right: ^Node,
}


Error :: struct {
	offset:  i64,
	msg_fmt: string,
	args:    []any,
}

parse_ast :: proc(tokens: ^[]tokenizer.Token, arena: ^mem.Arena) -> (Node, Error) {
	node, e := parse_expr(tokens, 0, arena)
	return node^, e
}

parse_expr :: proc(tokens: ^[]tokenizer.Token, prec: int, arena: ^mem.Arena) -> (^Node, Error) {
	left, err := parse_primary(tokens, arena)
	for len(tokens) > 0 {
		t := tokens[0]
		if t.type != .BinaryOperator do break
		t_prec := operator_prec(t.value.(tokenizer.BinaryOperator))
		if t_prec < prec do break
		tokens^ = tokens[1:]
		right, err := parse_expr(tokens, t_prec + 1, arena)

		ptr, _ := mem.arena_alloc(arena, size_of(Node))
		new_left := cast(^Node)ptr
		new_left^ = Node {
			type = .BinaryExpr,
			loc = left.loc,
			value = BinaryExpr {
				left = left,
				op = t.value.(tokenizer.BinaryOperator),
				right = right,
			},
		}
		left = new_left

	}
	return left, err
}

parse_primary :: proc(tokens: ^[]tokenizer.Token, arena: ^mem.Arena) -> (^Node, Error) {
	ptr, _ := mem.arena_alloc(arena, size_of(Node))
	node := cast(^Node)ptr
	switch tokens[0].type {
	case .Number:
		{
			t := tokens[0]
			tokens^ = tokens[1:]
			node.type = .Number
			node.value = t.value.(u64)
			node.loc = cast(u64)t.loc
			return node, Error{offset = -1}
		}
	case .BinaryOperator:
		{fallthrough}
	case:
		return node, Error {
			offset = cast(i64)tokens[0].loc,
			msg_fmt = "unexpected token found when parsing a primary expression: %v",
			args = {tokens[0]},
		}
	}
}

operator_prec :: proc(op: tokenizer.BinaryOperator) -> int {
	switch op {
	case .Plus:
		return 1
	}
	return -1
}
