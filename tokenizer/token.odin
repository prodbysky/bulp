package tokenizer

TokenType :: enum {
	Number,
	BinaryOperator,
	OpenParen,
	CloseParen,
	Semicolon,
	Keyword,
}


KeywordType :: enum {
	Return,
}


BinaryOperator :: enum {
	Plus,
	Minus,
	Mult,
	Div,
}

Token :: struct {
	type:  TokenType,
	loc:   int,
	value: union {
		u64,
		BinaryOperator,
		KeywordType,
	},
}
