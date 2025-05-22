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

EMPTY :: Node{}

parse_ast :: proc(tokens: ^[]tokenizer.Token, arena: ^mem.Arena) -> (Node, Error) {
	if len(tokens^) == 0 {
		return {}, Error{offset = 0, msg_fmt = "empty token stream"}
	}

	node, err := parse_expr(tokens, 0, arena)
	if err.offset != -1 {
		return {}, err
	}

	if len(tokens^) > 0 {
		return EMPTY, Error {
			offset = cast(i64)tokens^[0].loc,
			msg_fmt = "unexpected token at end of expression",
			args = {tokens^[0]},
		}
	}

	return node^, err
}

parse_expr :: proc(tokens: ^[]tokenizer.Token, prec: int, arena: ^mem.Arena) -> (^Node, Error) {
	left, err := parse_primary(tokens, arena)
	if err.offset != -1 {
		return nil, err
	}

	for len(tokens^) > 0 {
		t := tokens[0]
		if t.type != .BinaryOperator do break

		t_prec := operator_prec(t.value.(tokenizer.BinaryOperator))
		if t_prec < prec do break
		tokens^ = tokens[1:]
		right, right_err := parse_expr(tokens, t_prec + 1, arena)
		if right_err.offset != -1 {
			return nil, right_err
		}

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

	return left, Error{offset = -1}
}

parse_primary :: proc(tokens: ^[]tokenizer.Token, arena: ^mem.Arena) -> (^Node, Error) {
	if len(tokens^) == 0 {
		return nil, Error {
			offset = 0,
			msg_fmt = "unexpected end of input when parsing primary expression",
		}
	}

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
		return nil, Error {
			offset = cast(i64)tokens^[0].loc,
			msg_fmt = "expected number, found operator",
			args = {tokens[0].value},
		}

	case:
		return nil, Error {
			offset = cast(i64)tokens^[0].loc,
			msg_fmt = "unexpected token found when parsing a primary expression",
			args = {tokens[0]},
		}
	}
}

operator_prec :: proc(op: tokenizer.BinaryOperator) -> int {
	switch op {
	case .Plus:
		return 1
	case .Minus:
		return 1
	case .Div:
		return 2
	case .Mult:
		return 2
	}
	return -1
}
