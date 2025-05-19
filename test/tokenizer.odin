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
	testing.expect_value(t, err.offset, -1)
}

@(test)
grr_bad_numbers :: proc(t: ^testing.T) {
	SOURCE :: "123\n 6a9\n"
	tkn := tokenizer.Tokenizer {
		source = SOURCE,
		loc    = 0,
	}
	tokens, err := tokenizer.run(&tkn)
	testing.expect_value(t, err.offset, 6)
}

@(test)
operators :: proc(t: ^testing.T) {
	SOURCE :: "123\n 6a9\n"
	tkn := tokenizer.Tokenizer {
		source = SOURCE,
		loc    = 0,
	}
	tokens, err := tokenizer.run(&tkn)
	testing.expect_value(t, err.offset, 6)
}
