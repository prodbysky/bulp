package parser

import "../tokenizer"
import "core:fmt"
import "core:mem"


parse_ast :: proc(tokens: ^[]tokenizer.Token, arena: ^mem.Arena) -> ([dynamic]Statement, Error) {
	if len(tokens^) == 0 {
		return {}, Error{offset = 0, msg_fmt = "empty token stream"}
	}

	sts := make([dynamic]Statement, 0, 10)

	for len(tokens) > 0 {
		st, err := parse_statement(tokens, arena)
		if err.offset != -1 do return sts, err
		append(&sts, st)
	}

	return sts, Error{offset = -1}
}

parse_statement :: proc(tokens: ^[]tokenizer.Token, arena: ^mem.Arena) -> (Statement, Error) {
	st := Statement{}
	if tokens[0].value == .Return {
		st.loc = cast(u64)tokens[0].loc
		st.st_type = .Return
		tokens^ = tokens[1:]
		value, expr_err := parse_expr(tokens, 0, arena)
		if expr_err.offset != -1 do return Statement{}, expr_err
		tokens^ = tokens[1:] // ';'
		st.st = Return {
			e = value,
		}
		return st, Error{offset = -1}
	}
	return st, Error{offset = -1}
}

parse_expr :: proc(
	tokens: ^[]tokenizer.Token,
	prec: int,
	arena: ^mem.Arena,
) -> (
	^Expression,
	Error,
) {
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

		ptr, _ := mem.arena_alloc(arena, size_of(Expression))
		new_left := cast(^Expression)ptr
		new_left^ = Expression {
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

parse_primary :: proc(tokens: ^[]tokenizer.Token, arena: ^mem.Arena) -> (^Expression, Error) {
	if len(tokens^) == 0 {
		return nil, Error {
			offset = 0,
			msg_fmt = "unexpected end of input when parsing primary expression",
		}
	}

	ptr, _ := mem.arena_alloc(arena, size_of(Expression))
	node := cast(^Expression)ptr

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
	case .OpenParen:
		{
			tokens^ = tokens[1:]
			inner, err := parse_expr(tokens, 0, arena)
			if err.offset != -1 do return nil, err
			tokens^ = tokens[1:]
			return inner, Error{offset = -1}
		}
	case .CloseParen:
		{fallthrough}
	case .Keyword:
		{fallthrough}
	case .Semicolon:
		{fallthrough}
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

StatementType :: enum {
	Return,
}
Statement :: struct {
	loc:     u64,
	st_type: StatementType,
	st:      union {
		Return,
	},
}

Return :: struct {
	e: ^Expression,
}

ExpressionType :: enum {
	BinaryExpr,
	Number,
}

Expression :: struct {
	loc:   u64,
	type:  ExpressionType,
	value: union {
		u64,
		BinaryExpr,
	},
}
BinaryExpr :: struct {
	left:  ^Expression,
	op:    tokenizer.BinaryOperator,
	right: ^Expression,
}

Error :: struct {
	offset:  i64,
	msg_fmt: string,
	args:    []any,
}

EMPTY_EXPR :: Expression{}
