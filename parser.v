module main

type Argument = RegisterOperand | ImmediateOperand
type Statement = FunctionCall | ReturnStatement | IfStatement
type Expression = BinaryExpression | string | NumberLiteral | CharLiteral | IfExpression
type Function = LowlevelFunction | NormalFunction

struct RegisterOperand {
	name string
}

struct ImmediateOperand {
	value int
}

struct FunctionCall {
	name string
	args []Argument
}

struct Parameter {
	name     string
	typ      string
	register string
}

struct Receiver {
	name   string
	typ    string
	is_mut bool
}

struct NormalFunction {
	name        string
	receiver    ?Receiver // Optional - null if freestanding
	params      []Parameter
	return_type string
	body        []Statement
}

struct ReturnStatement {
	value Expression
}

struct BinaryExpression {
	left  string
	op    string // "+", "-", "*", "/"
	right string
}

struct IfExpression {
	condition  Expression
	then_value Expression // For inline: just the expression
	else_value Expression
}

struct IfStatement {
	condition  Expression
	then_block []Statement
	else_block []Statement
}

struct NumberLiteral {
	value int
}

struct CharLiteral {
	value int
}

struct LowlevelFunction {
	name            string
	params          []Parameter
	return_register string
	body            []Statement
}

struct StructField {
	name string
	typ  string
}

struct StructDef {
	name   string
	fields []StructField
}

struct Module {
	structs   []StructDef
	functions []Function
}

struct OpcodeInfo {
	min_args int
	max_args int
}

fn get_opcode_info(name string) ?OpcodeInfo {
	opcodes := {
		'mov':  OpcodeInfo{2, 2}
		'push': OpcodeInfo{1, 1}
		'pop':  OpcodeInfo{1, 1}
		'add':  OpcodeInfo{2, 2}
		'sub':  OpcodeInfo{2, 2}
		'ret':  OpcodeInfo{0, 0}
		'call': OpcodeInfo{1, 1}
		'in':   OpcodeInfo{2, 2}
		'out':  OpcodeInfo{2, 2}
	}

	return opcodes[name] or { return none }
}

struct Parser {
mut:
	tokens []Token
	pos    int
}

fn new_parser(tokens []Token) Parser {
	return Parser{
		tokens: tokens
		pos:    0
	}
}

fn (p Parser) peek() Token {
	if p.pos >= p.tokens.len {
		return Token{
			typ:   .eof
			value: ''
			line:  0
			col:   0
		}
	}

	return p.tokens[p.pos]
}

fn (mut p Parser) next() Token {
	if p.pos >= p.tokens.len {
		return Token{
			typ:   .eof
			value: ''
			line:  0
			col:   0
		}
	}
	token := p.tokens[p.pos]
	p.pos++
	return token
}

fn (mut p Parser) expect(expected TokenType) !Token {
	current := p.peek()

	if current.typ != expected {
		eprintln('Expected ${expected} but got ${current.typ} at ${current.line}:${current.col}!')
		return error('Unexpected token')
	}

	return p.next()
}

fn (mut p Parser) parse_parameter() Parameter {
	// Get the name
	name_token := p.expect(.identifier) or { panic(err) }
	name := name_token.value

	// Expect colon
	p.expect(.colon) or { panic(err) }

	// Get the type
	type_token := p.expect(.identifier) or { panic(err) }
	typ := type_token.value

	// Register is OPTIONAL (only for lowlevel functions)
	mut register := ''

	if p.peek().typ == .arrow {
		p.expect(.arrow) or { panic(err) }
		register = p.parse_register()
	}

	return Parameter{
		name:     name
		typ:      typ
		register: register // Empty string if not specified
	}
}

fn (mut p Parser) parse_parameters() []Parameter {
	mut params := []Parameter{}

	// Check if empty params
	if p.peek().typ == .rparen {
		return params
	}

	// Parse first parameter
	params << p.parse_parameter()

	// Parse remaining parameters (comma-separated)
	for p.peek().typ == .comma {
		p.expect(.comma) or { panic(err) }
		params << p.parse_parameter()
	}

	return params
}

fn (mut p Parser) parse_register() string {
	// Expect '@'
	p.expect(.at) or { panic(err) }

	// Get register name
	register_token := p.expect(.identifier) or { panic(err) }

	return register_token.value
}

fn (mut p Parser) parse_argument() Argument {
	if p.peek().typ == .at {
		tok := p.parse_register()
		return RegisterOperand{
			name: tok
		}
	} else if p.peek().typ == .number {
		tok := p.expect(.number) or { panic(err) }
		return ImmediateOperand{
			value: tok.value.int()
		}
	} else {
		panic('Unexpected error while parsing argument!')
	}
}

fn (mut p Parser) parse_arguments() []Argument {
	mut args := []Argument{}

	// Check if empty args
	if p.peek().typ == .rparen {
		return args
	}

	// Parse first argument
	args << p.parse_argument()

	// Parse remaining arguments (comma-separated)
	for p.peek().typ == .comma {
		p.expect(.comma) or { panic(err) }
		args << p.parse_argument()
	}

	return args
}

fn (mut p Parser) parse_statement() Statement {
	match p.peek().typ {
		.return {
			p.expect(.return) or { panic(err) }

			expr := p.parse_expression()
			p.expect(.semicolon) or { panic(err) }

			return ReturnStatement{
				value: expr
			}
		}
		.if {
			return p.parse_if_statement()
		}
		else {}
	}
	// Get the name
	name_token := p.expect(.identifier) or { panic(err) }
	name := name_token.value

	// Expect '('
	p.expect(.lparen) or { panic(err) }
	// Parse args
	args := p.parse_arguments()
	// Expect ')'
	p.expect(.rparen) or { panic(err) }
	// Expect ';'
	p.expect(.semicolon) or { panic(err) }

	opcode_info := get_opcode_info(name) or { panic('Unknown opcode: ${name}') }

	if args.len < opcode_info.min_args || args.len > opcode_info.max_args {
		panic("Opcode '${name}' requires ${opcode_info.min_args} argument(s), got ${args.len}")
	}

	return FunctionCall{
		name: name
		args: args
	}
}

fn (mut p Parser) parse_if_statement() IfStatement {
	p.expect(.if) or { panic(err) }

	// Parse condition
	condition := p.parse_expression()

	// Expect '{'
	p.expect(.lbrace) or { panic(err) }

	// Parse then block
	mut then_block := []Statement{}
	for p.peek().typ != .rbrace {
		then_block << p.parse_statement()
	}
	p.expect(.rbrace) or { panic(err) }

	// Check for else
	mut else_block := []Statement{}
	if p.peek().typ == .else {
		p.expect(.else) or { panic(err) }
		p.expect(.lbrace) or { panic(err) }

		for p.peek().typ != .rbrace {
			else_block << p.parse_statement()
		}
		p.expect(.rbrace) or { panic(err) }
	}

	return IfStatement{
		condition:  condition
		then_block: then_block
		else_block: else_block
	}
}

fn (mut p Parser) parse_expression() Expression {
	first_token := p.peek()

	match first_token.typ {
		.number {
			tok := p.next()
			return NumberLiteral{
				value: tok.value.int()
			}
		}
		.char {
			tok := p.next()
			// tok.value is the character as a string, get its ASCII value
			return CharLiteral{
				value: tok.value.int() // First char's ASCII value
			}
		}
		.identifier {
			// Could be just an identifier, or start of binary expression
			left_token := p.next()
			left := left_token.value

			// Check for operator
			if p.peek().typ in [.plus, .minus, .star, .slash, .gt, .lt, .gte, .lte, .eq_eq, .not_eq] {
				// Binary expression - existing code
				op_token := p.next()
				right_token := p.expect(.identifier) or { panic(err) }

				return BinaryExpression{
					left:  left
					op:    op_token.value
					right: right_token.value
				}
			} else {
				// Just an identifier
				return left
			}
		}
		else {
			panic('Expected expression, got ${first_token.typ}')
		}
	}
}

fn (mut p Parser) parse_body() []Statement {
	mut statements := []Statement{}

	// Keep parsing statements until we hit '}'
	for p.peek().typ != .rbrace {
		stmt := p.parse_statement()
		statements << stmt
	}

	return statements
}

fn (mut p Parser) parse_function_name() string {
	name_token := p.expect(.identifier) or { panic(err) }
	return name_token.value
}

fn (mut p Parser) parse_function_parameters() []Parameter {
	p.expect(.lparen) or { panic(err) }
	params := p.parse_parameters()
	p.expect(.rparen) or { panic(err) }
	return params
}

fn (mut p Parser) parse_function_body() []Statement {
	p.expect(.lbrace) or { panic(err) }
	body := p.parse_body()
	p.expect(.rbrace) or { panic(err) }
	return body
}

fn (mut p Parser) parse_type() string {
	type_token := p.expect(.identifier) or { panic(err) }
	return type_token.value
}

fn (mut p Parser) parse_function() Function {
	is_lowlevel := p.peek().typ == .lowlevel

	if is_lowlevel {
		p.expect(.lowlevel) or { panic(err) }
	} else {
		p.expect(.fn) or { panic(err) }
	}

	mut receiver := ?Receiver(none)

	if p.peek().typ == .lparen {
		// Has receiver: fn (name: Type)
		p.expect(.lparen) or { panic(err) }

		// Check for 'mut'
		is_mut := p.peek().typ == .mut
		if is_mut {
			p.expect(.mut) or { panic(err) }
		}

		// Parse receiver name and type
		recv_name := p.parse_function_name()
		p.expect(.colon) or { panic(err) }
		recv_type := p.parse_type()
		p.expect(.rparen) or { panic(err) }

		receiver = Receiver{
			name:   recv_name
			typ:    recv_type
			is_mut: is_mut
		}
	}

	name := p.parse_function_name()
	p.expect(.lparen) or { panic(err) }
	params := p.parse_parameters()
	p.expect(.rparen) or { panic(err) }
	p.expect(.arrow) or { panic(err) }

	// Parse return type (different for each)
	mut return_register := ''
	mut return_type := ''

	if is_lowlevel {
		return_register = p.parse_register()
	} else {
		return_type = p.parse_type()
	}

	// Parse body (same for both)
	p.expect(.lbrace) or { panic(err) }
	body := p.parse_body()
	p.expect(.rbrace) or { panic(err) }

	// Return appropriate type
	if is_lowlevel {
		return LowlevelFunction{name, params, return_register, body}
	} else {
		return NormalFunction{name, receiver, params, return_type, body}
	}
}

fn (mut p Parser) parse_functions() []Function {
	mut functions := []Function{}

	// Keep parsing while we see function keywords
	for p.peek().typ in [.lowlevel, .fn] {
		functions << p.parse_function()
	}

	return functions
}

fn (mut p Parser) parse_module() Module {
	mut structs := []StructDef{}
	mut functions := []Function{}

	for p.peek().typ != .eof {
		match p.peek().typ {
			.struct {
				structs << p.parse_struct()
			}
			.lowlevel, .fn {
				functions << p.parse_function()
			}
			else {
				panic('Unexpected token at top level: ${p.peek().typ}')
			}
		}
	}

	return Module{
		structs:   structs
		functions: functions
	}
}

fn (mut p Parser) parse_struct() StructDef {
	p.expect(.struct) or { panic(err) }

	// Struct name
	name_token := p.expect(.identifier) or { panic(err) }
	name := name_token.value

	// Opening brace
	p.expect(.lbrace) or { panic(err) }

	// Parse fields
	mut fields := []StructField{}

	for p.peek().typ != .rbrace {
		field := p.parse_struct_field()
		fields << field

		// Optional trailing comma
		if p.peek().typ == .comma {
			p.next()
		}
	}

	// Closing brace
	p.expect(.rbrace) or { panic(err) }

	return StructDef{
		name:   name
		fields: fields
	}
}

fn (mut p Parser) parse_struct_field() StructField {
	field_name_token := p.expect(.identifier) or { panic(err) }
	field_name := field_name_token.value

	p.expect(.colon) or { panic(err) }

	field_type_token := p.expect(.identifier) or { panic(err) }
	field_type := field_type_token.value

	return StructField{
		name: '${field_name}'
		typ:  '${field_type}'
	}
}
