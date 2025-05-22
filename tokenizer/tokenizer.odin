package tokenizer

import "core:log"
import "core:strconv"
import "core:strings"
import "core:unicode"

Tokenizer :: struct {
	source: string,
	loc:    int,
}

Error :: struct {
	offset:  i64,
	msg_fmt: string,
	args:    []any,
}

run :: proc(tkn: ^Tokenizer) -> ([dynamic]Token, Error) {
	tokens := make([dynamic]Token, 0, 32)
	for !finished(tkn) {
		skip_while(tkn, unicode.is_white_space)
		if finished(tkn) do break
		if unicode.is_digit(peek(tkn)) {
			t, err := lex_number(tkn)
			if err.offset != -1 do return tokens, err
			append(&tokens, t)
		}
		if peek(tkn) == '(' {
			append(&tokens, Token{loc = tkn.loc, type = .OpenParen})
			next(tkn)
		}
		if peek(tkn) == ')' {
			append(&tokens, Token{loc = tkn.loc, type = .CloseParen})
			next(tkn)
		}
		if strings.contains_rune("+-*/", peek(tkn)) {
			t, err := lex_operator(tkn)
			if err.offset != -1 do return tokens, err
			append(&tokens, t)

		}
	}
	return tokens, Error{offset = -1}
}

lex_number :: proc(tkn: ^Tokenizer) -> (Token, Error) {
	assert(unicode.is_digit(peek(tkn)), "sanity checks")
	t := Token {
		loc  = tkn.loc,
		type = .Number,
	}
	for !finished(tkn) && unicode.is_digit(peek(tkn)) do next(tkn)
	if !finished(tkn) && unicode.is_alpha(peek(tkn)) {
		return t, Error {
			offset = cast(i64)tkn.loc,
			msg_fmt = "number literal not separated from alphabetic characters",
		}
	}
	number, _ := strconv.parse_u64_of_base(tkn.source[t.loc:tkn.loc], 10)
	t.value = number
	return t, Error{offset = -1}
}

lex_operator :: proc(tkn: ^Tokenizer) -> (Token, Error) {
	t := Token{}
	switch peek(tkn) {
	case '+':
		{
			next(tkn)
			return Token {
				type = .BinaryOperator,
				value = .Plus,
				loc = tkn.loc - 1,
			}, Error{offset = -1}
		}
	case '-':
		{
			next(tkn)
			return Token {
				type = .BinaryOperator,
				value = .Minus,
				loc = tkn.loc - 1,
			}, Error{offset = -1}
		}
	case '*':
		{
			next(tkn)
			return Token {
				type = .BinaryOperator,
				value = .Mult,
				loc = tkn.loc - 1,
			}, Error{offset = -1}
		}
	case '/':
		{
			next(tkn)
			return Token {
				type = .BinaryOperator,
				value = .Div,
				loc = tkn.loc - 1,
			}, Error{offset = -1}
		}
	case:
		return t, Error {
			offset = cast(i64)tkn.loc,
			msg_fmt = "unexpected char found when parsing operators: %v",
			args = {peek(tkn)},
		}
	}
}

finished :: proc(tkn: ^Tokenizer) -> bool {
	return len(tkn.source) <= tkn.loc
}

peek :: proc(tkn: ^Tokenizer) -> rune {
	return cast(rune)tkn.source[tkn.loc]
}

next :: proc(tkn: ^Tokenizer) -> rune {
	tkn.loc += 1
	return cast(rune)tkn.source[tkn.loc]
}

skip_while :: proc(tkn: ^Tokenizer, prec: proc(_: rune) -> bool) {
	using tkn
	for !finished(tkn) && prec(peek(tkn)) do loc += 1
}
