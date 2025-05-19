package tokenizer

TokenType :: enum {
	Number,
}

Token :: struct {
	type:  TokenType,
	loc:   int,
	value: union {
		u64,
	},
}
