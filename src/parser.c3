module syslang;

import std::collections::list;
import std::io;
import std::io::file;

struct Parser
{
	List{Token} tokens;
	int pos;
}

fn Parser newParser(List{Token} tokens)
{
	return (Parser) { .tokens = tokens, .pos = 0 };
}

fn Token Parser.peek(&self)
{
	if (self.pos >= self.tokens.len())
	{
		return (Token) { .type = TokenType.TOKEN_EOF, .value = "", .line = 0, .col = 0 };
	}
	return self.tokens[self.pos];
}

fn Token Parser.next(&self)
{
	if (self.pos >= self.tokens.len())
	{
		return (Token) { .type = TokenType.TOKEN_EOF, .value = "", .line = 0, .col = 0 };
	}

	Token tok = self.tokens[self.pos];
	self.pos++;

	return tok;
}

fn Token Parser.expect(&self, TokenType expected)
{
	Token t = self.peek();
	if (t.type == expected) return self.next();
	self.next();
	io::printfn("Expected %s but got %s ('%s') at %d:%d", expected, t.type, t.value, t.line, t.col);
	return (Token) { .type = TokenType.TOKEN_EOF, .value = "", .line = 0, .col = 0 };
}

struct Parameter
{
	String name;
	String type;
	String reg;
}

struct Operand
{
	OperandKind kind;
	String reg;
	int imm;
}

enum OperandKind
{
	OPERAND_REGISTER,
	OPERAND_IMMEDIATE
}

struct Statement
{
	StatementKind kind;
	String name;
	List{Operand} args;
}

enum StatementKind
{
	STMT_OPCODE,
	STMT_RETURN
}

struct FnStatement
{
	FnStatementKind kind;
	String value;
	String[] args;
}

enum FnStatementKind
{
	FN_STMT_RETURN
}

struct FnFunction
{
	String name;
	String return_type;
	List{FnStatement} body;
}

struct AsmFunction
{
	String name;
	List{Parameter} params;
	String return_reg;
	List{Statement} body;
	bool is_public;
}

struct Function
{
	FunctionKind kind;
	AsmFunction asm_fn;
	FnFunction fn_fn;
}

enum FunctionKind
{
	FUNC_ASM,
	FUNC_FN
}

fn Operand Parser.parseOperand(&self)
{
	Token t = self.peek();
	if (t.type == TokenType.TOKEN_AT)
	{
		self.next();
		Token reg = self.expect(TokenType.TOKEN_IDENTIFIER);
		return (Operand) { .kind = OperandKind.OPERAND_REGISTER, .reg = reg.value };
	}
	else if (t.type == TokenType.INT_LIT)
	{
		self.next();
		return (Operand) { .kind = OperandKind.OPERAND_IMMEDIATE, .imm = t.value.to_int()!! };
	}
	io::printfn("Expected operand at %d:%d", t.line, t.col);
	return (Operand) { .kind = OperandKind.OPERAND_REGISTER, .reg = "" };
}

fn Parameter Parser.parseParameter(&self)
{
	Token name = self.expect(TokenType.TOKEN_IDENTIFIER);
	self.expect(TokenType.TOKEN_COLON);
	Token type = self.expect(TokenType.TOKEN_IDENTIFIER);
	String reg = "";
	if (self.peek().type == TokenType.TOKEN_ARROW)
	{
		self.next();
		self.expect(TokenType.TOKEN_AT);
		Token r = self.expect(TokenType.TOKEN_IDENTIFIER);
		reg = r.value;
	}
	return (Parameter) { .name = name.value, .type = type.value, .reg = reg };
}

fn List{Parameter} Parser.parseParameters(&self)
{
	List{Parameter} params;
	if (self.peek().type == TokenType.TOKEN_RPAREN)
	{
		return params;
	}
	params.push(self.parseParameter());
	while (self.peek().type == TokenType.TOKEN_COMMA)
	{
		self.next();
		params.push(self.parseParameter());
	}
	return params;
}

fn List{Operand} Parser.parseArguments(&self)
{
	List{Operand} args;
	if (self.peek().type == TokenType.TOKEN_RPAREN)
	{
		return args;
	}
	args.push(self.parseOperand());
	while (self.peek().type == TokenType.TOKEN_COMMA)
	{
		self.next();
		args.push(self.parseOperand());
	}
	return args;
}

fn Statement Parser.parseOpcode(&self)
{
	Token name = self.expect(TokenType.TOKEN_IDENTIFIER);
	self.expect(TokenType.TOKEN_LPAREN);
	List{Operand} args = self.parseArguments();
	self.expect(TokenType.TOKEN_RPAREN);
	self.expect(TokenType.TOKEN_SEMICOLON);
	return (Statement) { .kind = StatementKind.STMT_OPCODE, .name = name.value, .args = args };
}

fn List{Statement} Parser.parseBody(&self)
{
	List{Statement} body;
	while (self.peek().type != TokenType.TOKEN_RBRACE)
	{
		body.push(self.parseOpcode());
	}
	self.expect(TokenType.TOKEN_RBRACE);
	return body;
}

fn AsmFunction Parser.parseAsmFunction(&self)
{
	bool is_public = false;
	if (self.peek().type == TokenType.TOKEN_PUB)
	{
		self.next();
		is_public = true;
	}
	self.expect(TokenType.TOKEN_ASM);
	Token name = self.expect(TokenType.TOKEN_IDENTIFIER);
	self.expect(TokenType.TOKEN_LPAREN);
	List{Parameter} params = self.parseParameters();
	self.expect(TokenType.TOKEN_RPAREN);
	String return_reg = "";
	if (self.peek().type == TokenType.TOKEN_ARROW)
	{
		self.next();
		self.expect(TokenType.TOKEN_AT);
		Token ret_reg = self.expect(TokenType.TOKEN_IDENTIFIER);
		return_reg = ret_reg.value;
	}
	self.expect(TokenType.TOKEN_LBRACE);
	List{Statement} body = self.parseBody();
	return (AsmFunction) { .name = name.value, .params = params, .return_reg = return_reg, .body = body, .is_public = is_public };
}

fn List{FnStatement} Parser.parseFnBody(&self)
{
	List{FnStatement} body;
	while (self.peek().type != TokenType.TOKEN_RBRACE)
	{
		body.push(self.parseFnStatement());
	}
	self.expect(TokenType.TOKEN_RBRACE);
	return body;
}

fn FnStatement Parser.parseFnStatement(&self)
{
	Token t = self.peek();
	if (t.type == TokenType.TOKEN_RETURN)
	{
		self.next();
		Token val = self.expect(TokenType.TOKEN_IDENTIFIER);
		self.expect(TokenType.TOKEN_SEMICOLON);
		return (FnStatement) { .kind = FnStatementKind.FN_STMT_RETURN, .value = val.value };
	}
	else if (t.type == TokenType.TOKEN_IDENTIFIER)
	{
		Token val = self.expect(TokenType.TOKEN_IDENTIFIER);
		if (self.peek().type == TokenType.TOKEN_LPAREN)
		{
			self.next();
			self.expect(TokenType.TOKEN_RPAREN);
		}
		self.expect(TokenType.TOKEN_SEMICOLON);
		return (FnStatement) { .kind = FnStatementKind.FN_STMT_RETURN, .value = val.value };
	}
	io::printfn("Unknown fn statement at %d:%d", t.line, t.col);
	self.next();
	return (FnStatement) { .kind = FnStatementKind.FN_STMT_RETURN, .value = "" };
}

fn FnFunction Parser.parseFnFunction(&self)
{
	self.expect(TokenType.TOKEN_FN);
	Token name = self.expect(TokenType.TOKEN_IDENTIFIER);
	self.expect(TokenType.TOKEN_LPAREN);
	self.expect(TokenType.TOKEN_RPAREN);
	self.expect(TokenType.TOKEN_ARROW);
	Token ret_type = self.expect(TokenType.TOKEN_IDENTIFIER);
	self.expect(TokenType.TOKEN_LBRACE);
	List{FnStatement} body = self.parseFnBody();
	return (FnFunction) { .name = name.value, .return_type = ret_type.value, .body = body };
}

fn Function Parser.parseFunction(&self)
{
	Token t = self.peek();
	if (t.type == TokenType.TOKEN_ASM)
	{
		AsmFunction asm_fn = self.parseAsmFunction();
		return (Function) { .kind = FunctionKind.FUNC_ASM, .asm_fn = asm_fn };
	}
	else if (t.type == TokenType.TOKEN_FN)
	{
		FnFunction fn_fn = self.parseFnFunction();
		return (Function) { .kind = FunctionKind.FUNC_FN, .fn_fn = fn_fn };
	}
	io::printfn("Unknown function type at %d:%d", t.line, t.col);
	return (Function) { .kind = FunctionKind.FUNC_ASM, .asm_fn = self.parseAsmFunction() };
}

fn List{Function} Parser.parseModule(&self)
{
	List{Function} funcs;
	while (self.peek().type != TokenType.TOKEN_EOF)
	{
		Token t = self.peek();
		if (t.type == TokenType.TOKEN_IMPORT)
		{
			self.next();
			Token module_name = self.expect(TokenType.TOKEN_IDENTIFIER);
			self.expect(TokenType.TOKEN_SEMICOLON);
			List{Function} imported = self.loadModule(module_name.value);
			foreach (f : imported) {
				funcs.push(f);
			}
		}
		else if (t.type == TokenType.TOKEN_MODULE)
		{
			self.next();
			self.expect(TokenType.TOKEN_IDENTIFIER);
			self.expect(TokenType.TOKEN_SEMICOLON);
		}
		else
		{
			funcs.push(self.parseFunction());
		}
	}
	return funcs;
}

fn List{Function} Parser.loadModule(&self, String module_name)
{
	DString path;
	path.append("stdlib/");
	path.append(module_name);
	path.append(".sl");
	
	File f = file::open(path.str_view(), "r")!!;
	char[] content = io::read_fully(tmem, &f)!!;
	(void)f.close();
	
	Lexer lexer = newLexer((String)content);
	List{Token} tokens = lexer.tokenize();
	
	Parser sub_parser = newParser(tokens);
	return sub_parser.parseModule();
}
