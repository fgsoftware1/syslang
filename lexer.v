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

fn (l Lexer) peek() u8 {
	if l.pos >= l.source.len {
		return 0 // EOF
	}
	return l.source[l.pos]
}

fn (l Lexer) peek_next() u8 {
	if l.pos + 1 >= l.source.len {
		return 0 // EOF
	}
	return l.source[l.pos + 1]
}

fn (mut l Lexer) make_single_char_token(typ TokenType, value string) Token {
	token := Token{
		typ:   typ
		value: value
		line:  l.line
		col:   l.col
	}
	l.next()
	return token
}

fn (mut l Lexer) make_double_char_token(typ TokenType, value string) Token {
	token := Token{
		typ:   typ
		value: value
		line:  l.line
		col:   l.col
	}
	l.next() // consume first char
	l.next() // consume second char
	return token
}

fn (mut l Lexer) read_identifier(first_char u8) string {
	mut identifier := first_char.ascii_str()

	for is_alphanumeric(l.peek()) {
		identifier += l.next().ascii_str()
	}

	return identifier
}

fn (mut l Lexer) read_number(first_number u8) string {
	mut number := first_number.ascii_str()

	for is_digit(l.peek()) {
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
		mut ch := l.peek()

		// Skip whitespace
		if ch == ` ` || ch == `\t` || ch == `\n` || ch == `\r` {
			l.next()
			continue
		}

		match ch {
			`(` {
				tokens << l.make_single_char_token(.lparen, '(')
			}
			`)` {
				tokens << l.make_single_char_token(.rparen, ')')
			}
			`{` {
				tokens << l.make_single_char_token(.lbrace, '{')
			}
			`}` {
				tokens << l.make_single_char_token(.rbrace, '}')
			}
			`@` {
				tokens << l.make_single_char_token(.at, '@')
			}
			`,` {
				tokens << l.make_single_char_token(.comma, ',')
			}
			`;` {
				tokens << l.make_single_char_token(.semicolon, ';')
			}
			`:` {
				tokens << l.make_single_char_token(.colon, ':')
			}
			`-` {
				if l.peek_next() == `>` {
					tokens << l.make_double_char_token(.arrow, '->')
				} else {
					tokens << l.make_single_char_token(.minus, '-')
				}
			}
			`+` {
				tokens << l.make_single_char_token(.plus, '+')
			}
			`*` {
				tokens << l.make_single_char_token(.star, '*')
			}
			`/` {
				tokens << l.make_single_char_token(.slash, '/')
			}
			`>` {
				if l.peek_next() == `=` {
					tokens << l.make_double_char_token(.gte, '>=')
				} else {
					tokens << l.make_single_char_token(.gt, '>')
				}
			}
			`<` {
				if l.peek_next() == `=` {
					tokens << l.make_double_char_token(.lte, '<=')
				} else {
					tokens << l.make_single_char_token(.lt, '<')
				}
			}
			`=` {
				if l.peek_next() == `=` {
					tokens << l.make_double_char_token(.eq_eq, '==')
				} else {
					tokens << l.make_single_char_token(.assign, '=') // Need this for variable assignment
				}
			}
			`!` {
				if l.peek_next() == `=` {
					tokens << l.make_double_char_token(.not_eq, '!=')
				} else {
					tokens << l.make_single_char_token(.not, '!') // Logical NOT
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
				if l.peek() != `'` {
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
