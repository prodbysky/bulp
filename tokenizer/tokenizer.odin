package tokenizer

import "core:fmt"
import "core:log"
import "core:strconv"
import "core:strings"
import "core:unicode"

Tokenizer :: struct {
	source: string,
	loc:    int,
}

ErrorType :: enum {
	UnexpectedChar,
	UnexpectedIdent,
	InvalidNumberLiteral,
	InvalidOperatorChar,
}

UnexpectedChar :: struct {
	expected_predicate: string,
	c:                  rune,
}

UnexpectedIdent :: struct {
	got: string,
}

InvalidNumberLiteral :: struct {
	got: string,
}

InvalidOperatorChar :: struct {
	got: rune,
}

Error :: struct {
	offset: i64,
	type:   ErrorType,
	as:     union {
		UnexpectedChar,
		UnexpectedIdent,
		InvalidNumberLiteral,
		InvalidOperatorChar,
	},
}

error_to_string :: proc(using err: Error) -> string {
	switch type {
	case .UnexpectedChar:
		return fmt.tprintf(
			"Unexpected character found during parsing: %v, expected: %v",
			as.(UnexpectedChar).c,
			as.(UnexpectedChar).expected_predicate,
		)

	case .UnexpectedIdent:
		return fmt.tprintf(
			"Since custom identifiers are not yet supported\nwhen trying to parse `%v` as a keyword we failed",
			as.(UnexpectedIdent).got,
		)

	case .InvalidNumberLiteral:
		return fmt.tprintf("Failed to parse number: %v", as.(InvalidNumberLiteral).got)
	case .InvalidOperatorChar:
		return fmt.tprintf("Failed to parse %v as an operator", as.(InvalidOperatorChar).got)
	}
	return "Something wrong"
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
		} else if unicode.is_alpha(peek(tkn)) {
			loc := tkn.loc
			for !finished(tkn) && (unicode.is_alpha(peek(tkn)) || unicode.is_number(peek(tkn)) || peek(tkn) == '_') do next(tkn)
			if tkn.source[loc:tkn.loc] == "return" {
				append(&tokens, Token{loc = loc, type = .Keyword, value = .Return})
			} else {
				return nil, Error {
					offset = cast(i64)loc,
					type = .UnexpectedIdent,
					as = UnexpectedIdent{got = tkn.source[loc:tkn.loc]},
				}
			}
		} else if peek(tkn) == '(' {
			append(&tokens, Token{loc = tkn.loc, type = .OpenParen})
			next(tkn)
		} else if peek(tkn) == ')' {
			append(&tokens, Token{loc = tkn.loc, type = .CloseParen})
			next(tkn)
		} else if peek(tkn) == ';' {
			append(&tokens, Token{loc = tkn.loc, type = .Semicolon})
			next(tkn)
		} else if strings.contains_rune("+-*/", peek(tkn)) {
			t, err := lex_operator(tkn)
			if err.offset != -1 do return tokens, err
			append(&tokens, t)
		} else {
			return tokens, Error {
				offset = cast(i64)tkn.loc,
				type = .UnexpectedChar,
				as = UnexpectedChar{c = peek(tkn), expected_predicate = "Not this xD"},
			}
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
			type = .InvalidNumberLiteral,
			as = InvalidNumberLiteral{got = tkn.source[t.loc:tkn.loc]},
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
			type = .InvalidOperatorChar,
			as = InvalidOperatorChar{got = peek(tkn)},
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
