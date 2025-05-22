package tests

import "core:testing"

import "../tokenizer"


@(test)
good_numbers :: proc(t: ^testing.T) {
	SOURCE :: "123 69\n"
	tkn := tokenizer.Tokenizer {
		source = SOURCE,
		loc    = 0,
	}
	tokens, err := tokenizer.run(&tkn)
	defer delete(tokens)
	testing.expect_value(t, err.offset, -1)
	testing.expect_value(t, len(tokens), 2)
	testing.expect_value(t, tokens[0], tokenizer.Token{value = 123, type = .Number, loc = 0})
	testing.expect_value(t, tokens[1], tokenizer.Token{value = 69, type = .Number, loc = 4})
}

@(test)
grr_bad_numbers :: proc(t: ^testing.T) {
	SOURCE :: "123\n 6a9\n"
	tkn := tokenizer.Tokenizer {
		source = SOURCE,
		loc    = 0,
	}
	tokens, err := tokenizer.run(&tkn)
	defer delete(tokens)
	testing.expect_value(t, err.offset, 6)
}

@(test)
operators :: proc(t: ^testing.T) {
	SOURCE :: "+\n+\n"
	tkn := tokenizer.Tokenizer {
		source = SOURCE,
		loc    = 0,
	}
	tokens, err := tokenizer.run(&tkn)
	defer delete(tokens)
	testing.expect_value(t, err.offset, -1)
	testing.expect_value(t, len(tokens), 2)
	testing.expect_value(
		t,
		tokens[0],
		tokenizer.Token{value = .Plus, type = .BinaryOperator, loc = 0},
	)
	testing.expect_value(
		t,
		tokens[1],
		tokenizer.Token{value = .Plus, type = .BinaryOperator, loc = 2},
	)
}

@(test)
keyword :: proc(t: ^testing.T) {
	SOURCE :: "return\n"
	tkn := tokenizer.Tokenizer {
		source = SOURCE,
		loc    = 0,
	}
	tokens, err := tokenizer.run(&tkn)
	defer delete(tokens)
	testing.expect_value(t, err.offset, -1)
	testing.expect_value(t, len(tokens), 1)
	testing.expect_value(t, tokens[0], tokenizer.Token{value = .Return, type = .Keyword, loc = 0})
}
