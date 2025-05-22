package tokenizer

TokenType :: enum {
	Number,
	BinaryOperator,
}

BinaryOperator :: enum {
	Plus,
	Minus,
}

Token :: struct {
	type:  TokenType,
	loc:   int,
	value: union {
		u64,
		BinaryOperator,
	},
}
