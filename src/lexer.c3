module syslang;

import std::core::ascii;
import std::core::string;
import std::collections::list;
import std::io;

enum TokenType
{
	TOKEN_IDENTIFIER,
	TOKEN_LPAREN,
	TOKEN_RPAREN,
	TOKEN_LBRACE,
	TOKEN_RBRACE,
	TOKEN_LBRACKET,
	TOKEN_RBRACKET,
	TOKEN_COMMA,
	TOKEN_SEMICOLON,
	TOKEN_COLON,
	TOKEN_AT,
	TOKEN_ARROW,

	INT_LIT,

	// KEYWORDS
	TOKEN_PUB,
	TOKEN_ASM,
	TOKEN_FN,
	TOKEN_LET,
	TOKEN_RETURN,
	TOKEN_IF,
	TOKEN_ELIF,
	TOKEN_ELSE,
	TOKEN_WHILE,

	TOKEN_UNROLL,
	TOKEN_REP,
	TOKEN_FOR,
	TOKEN_IN,
	TOKEN_IMPORT,
	TOKEN_MODULE,

	// SPECIAL TOKENS
	TOKEN_EOF,
}

struct Token
{
	TokenType type;
	String value;
	int line;
	int col;
}

struct Lexer
{
	String source;
	int pos;
	int line;
	int col;
}

fn Lexer newLexer(String source)
{
	return (Lexer) { .source = source, .pos = 0, .line = 1, .col = 1 };
}

fn List{Token} Lexer.tokenize(&self)
{
	List{Token} tokens;

	while (self.pos < self.source.len)
	{
		char c = self.peek();
		// io::printfn("%d %s %c", self.pos, self.source[self.pos], self.peek());

		if (c == ' ' || c == '\t' || c == '\n' || c == '\r')
		{
			self.next(); // skip whitespace
			continue;
		}

		switch (c)
		{
			case '(':
				tokens.push(self.makeSingleCharToken(TokenType.TOKEN_LPAREN, "("));
				break;
			case ')':
				tokens.push(self.makeSingleCharToken(TokenType.TOKEN_RPAREN, ")"));
				break;
			case '{':
				tokens.push(self.makeSingleCharToken(TokenType.TOKEN_LBRACE, "{"));
				break;
			case '}':
				tokens.push(self.makeSingleCharToken(TokenType.TOKEN_RBRACE, "}"));
				break;
			case '[':
				tokens.push(self.makeSingleCharToken(TokenType.TOKEN_LBRACKET, "["));
				break;
			case ']':
				tokens.push(self.makeSingleCharToken(TokenType.TOKEN_RBRACKET, "]"));
				break;
			case '-':
				if (self.peekNext() == '>')
				{
					tokens.push(self.makeDoubleCharToken(TokenType.TOKEN_ARROW, "->"));
				}
				break;
			case '@':
				tokens.push(self.makeSingleCharToken(TokenType.TOKEN_AT, "@"));
				break;
			case ',':
				tokens.push(self.makeSingleCharToken(TokenType.TOKEN_COMMA, ","));
				break;
			case ';':
				tokens.push(self.makeSingleCharToken(TokenType.TOKEN_SEMICOLON, ";"));
				break;
			case ':':
				tokens.push(self.makeSingleCharToken(TokenType.TOKEN_COLON, ":"));
				break;
			default:
				if (ascii::is_alpha(c) || c == '_')
				{
					String ident = self.readIdentifier(self.next());
					tokens.push(
						(Token) { .type = identifierType(ident), .value = ident, .line = self.line, .col = self.col }
					);
				}
				else if (ascii::is_digit(c))
				{
					tokens.push(
						(Token) {
							.type = TokenType.INT_LIT,
							.value = self.readNumber(self.next()),
							.line = self.line,
							.col = self.col
						}
					);
				}
				else
				{
					self.next();
				}
		}
	}
	return tokens;
}

fn char Lexer.next(&self)
{
	if (self.pos >= self.source.len)
	{
		return '\0';
	}
	char c = self.source[self.pos];
	self.pos += 1;
	if (c == '\n')
	{
		self.line += 1;
		self.col = 1;
	}
	else
	{
		self.col += 1;
	}
	return c;
}

fn char Lexer.peek(&self)
{
	if (self.pos >= self.source.len)
	{
		return '\0';
	}
	return self.source[self.pos];
}

fn char Lexer.peekNext(&self)
{
	if (self.pos + 1 >= self.source.len)
	{
		return '\0';
	}
	return self.source[self.pos + 1];
}

fn Token Lexer.makeSingleCharToken(&self, TokenType type, String value)
{
	Token token = (Token) { .type = type, .value = value, .line = self.line, .col = self.col };

	self.next(); // consume the character

	return token;
}

fn Token Lexer.makeDoubleCharToken(&self, TokenType type, String value)
{
	Token token = (Token) { .type = type, .value = value, .line = self.line, .col = self.col - 1 };

	self.next(); // consume the first character
	self.next(); // consume the second character

	return token;
}

fn String Lexer.readIdentifier(&self, char firstChar)
{
	DString identifier;
	identifier.append(firstChar);

	while (ascii::is_alnum(self.peek()) || self.peek() == '_')
	{
		identifier.append(self.next());
	}

	return identifier.str_view();
}

fn String Lexer.readNumber(&self, char firstChar)
{
	DString identifier;
	identifier.append(firstChar);

	while (ascii::is_digit(self.peek()))
	{
		identifier.append(self.next());
	}

	return identifier.str_view();
}

fn TokenType identifierType(String value)
{
	switch (value)
	{
		case "asm": return TOKEN_ASM;
		case "fn": return TOKEN_FN;
		case "let": return TOKEN_LET;
		case "return": return TOKEN_RETURN;
		case "if": return TOKEN_IF;
		case "else": return TOKEN_ELSE;
		case "while": return TOKEN_WHILE;
		case "for": return TOKEN_FOR;
		case "in": return TOKEN_IN;
		case "import": return TOKEN_IMPORT;
		case "module": return TOKEN_MODULE;
		case "pub": return TOKEN_PUB;
		default: return TOKEN_IDENTIFIER;
	}
}
