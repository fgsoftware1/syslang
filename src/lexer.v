module main

enum TokenType {
	// Keywords
	lowlevel // lowlevel
	fn       // fn
	return   // return
	mut      // mut
	struct   // struct
	if       // if
	else     // else

	// Operators
	plus  // +
	minus // -
	star  // *
	slash // /

	not    // !
	assign // =
	gt     // >
	lt     // <
	gte    // >=
	lte    // <=
	eq_eq  // ==
	not_eq // !=

	// Symbols
	lparen    // (
	rparen    // )
	lbrace    // {
	rbrace    // }
	arrow     // ->
	at        // @
	comma     // ,
	semicolon // ;
	dash      // -
	colon     // :

	// Literals
	identifier
	number
	char

	// Special
	eof
}

struct Token {
	typ   TokenType
	value string
	line  int
	col   int
}

fn (t Token) str() string {
	return '${t.typ}("${t.value}") at ${t.line}:${t.col}'
}

struct Lexer {
	source string
mut:
	line int
	col  int
	pos  int
}

fn new_lexer(source string) Lexer {
	return Lexer{
		source: source
		pos:    0
		line:   1
		col:    1
	}
}

fn (mut l Lexer) next() u8 {
	if l.pos >= l.source.len {
		return 0 // EOF
	}
	ch := l.source[l.pos]
	l.pos++
	if ch == `\n` {
		l.line++
		l.col = 1
	} else {
		l.col++
	}
	return ch
}

fn (l Lexer) peek(n_chars ?int) u8 {
	count := n_chars or { 0 }

	if l.pos >= l.source.len {
		return 0 // EOF
	}

	if count == 0 {
		return l.source[l.pos]
	} else {
		return l.source[l.pos + count]
	}
}

fn (mut l Lexer) make_char_token(typ TokenType, value string, n_chars ?int) Token {
	count := n_chars or { 0 }
	if count == 0 {
		panic("Number of chars can't be 0!")
	}

	token := Token{
		typ:   typ
		value: value
		line:  l.line
		col:   l.col
	}

	if count > 1 {
		for _ in 0 .. count {
			l.next()
		}
	} else {
		l.next()
	}

	return token
}

fn (mut l Lexer) read_identifier(first_char u8) string {
	mut identifier := first_char.ascii_str()

	for is_alphanumeric(l.peek(0)) {
		identifier += l.next().ascii_str()
	}

	return identifier
}

fn (mut l Lexer) read_number(first_number u8) string {
	mut number := first_number.ascii_str()

	for is_digit(l.peek(0)) {
		number += l.next().ascii_str()
	}

	return number
}

fn keyword_or_identifier(word string) TokenType {
	return match word {
		'lowlevel' { .lowlevel }
		'fn' { .fn }
		'return' { .return }
		'mut' { .mut }
		'struct' { .struct }
		'if' { .if }
		'else' { .else }
		else { .identifier }
	}
}

fn (mut l Lexer) tokenize() []Token {
	mut tokens := []Token{}

	for l.pos < l.source.len {
		mut ch := l.peek(0)

		// Skip whitespace
		if ch == ` ` || ch == `\t` || ch == `\n` || ch == `\r` {
			l.next()
			continue
		}

		match ch {
			`(` {
				tokens << l.make_char_token(.lparen, '(', 1)
			}
			`)` {
				tokens << l.make_char_token(.rparen, ')', 1)
			}
			`{` {
				tokens << l.make_char_token(.lbrace, '{', 1)
			}
			`}` {
				tokens << l.make_char_token(.rbrace, '}', 1)
			}
			`@` {
				tokens << l.make_char_token(.at, '@', 1)
			}
			`,` {
				tokens << l.make_char_token(.comma, ',', 1)
			}
			`;` {
				tokens << l.make_char_token(.semicolon, ';', 1)
			}
			`:` {
				tokens << l.make_char_token(.colon, ':', 1)
			}
			`-` {
				if l.peek(1) == `>` {
					tokens << l.make_char_token(.arrow, '->', 2)
				} else {
					tokens << l.make_char_token(.minus, '-', 1)
				}
			}
			`+` {
				tokens << l.make_char_token(.plus, '+', 1)
			}
			`*` {
				tokens << l.make_char_token(.star, '*', 1)
			}
			`/` {
				tokens << l.make_char_token(.slash, '/', 1)
			}
			`>` {
				if l.peek(1) == `=` {
					tokens << l.make_char_token(.gte, '>=', 2)
				} else {
					tokens << l.make_char_token(.gt, '>', 1)
				}
			}
			`<` {
				if l.peek(1) == `=` {
					tokens << l.make_char_token(.lte, '<=', 2)
				} else {
					tokens << l.make_char_token(.lt, '<', 1)
				}
			}
			`=` {
				if l.peek(1) == `=` {
					tokens << l.make_char_token(.eq_eq, '==', 2)
				} else {
					tokens << l.make_char_token(.assign, '=', 1)
				}
			}
			`!` {
				if l.peek(1) == `=` {
					tokens << l.make_char_token(.not_eq, '!=', 2)
				} else {
					tokens << l.make_char_token(.not, '!', 1)
				}
			}
			`'` {
				l.next() // consume opening '

				// Get the character
				// TODO: Handle escape sequences
				ch = l.next()
				// DEBUG
				// println("Char literal: ch=${ch}, ch.str()=${ch.str()}")

				// Expect closing '
				if l.peek(0) != `'` {
					panic('Unterminated character literal at ${l.line}:${l.col}')
				}
				l.next() // consume closing '

				tokens << Token{
					typ:   .char
					value: ch.str()
					line:  l.line
					col:   l.col
				}
			}
			else {
				if is_alpha(ch) || ch == `_` {
					first_char := l.next()
					identifier_value := l.read_identifier(first_char)
					typ := keyword_or_identifier(identifier_value)
					tokens << Token{
						typ:   typ
						value: identifier_value
						line:  l.line
						col:   l.col - identifier_value.len + 1
					}
				} else if is_digit(ch) {
					first_number := l.next()
					number_value := l.read_number(first_number)
					tokens << Token{
						typ:   .number
						value: number_value
						line:  l.line
						col:   l.col - number_value.len + 1
					}
				} else {
					eprintln('Unknown character: ${ch}')
					l.next()
				}
			}
		}
	}

	// Add EOF token
	tokens << Token{
		typ:   .eof
		value: ''
		line:  l.line
		col:   l.col
	}

	return tokens
}
