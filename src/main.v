module main

import os

fn main() {
	if os.args.len < 2 {
		println('Usage: syslang <source_file>')
		exit(1)
	}

	source_file := os.args[1]
	source_code := os.read_file(source_file) or {
		eprintln('Error reading file: ${err}')
		exit(1)
	}

	println('=== SOURCE CODE ===')
	println(source_code)

	// Tokenize
	mut lexer := new_lexer(source_code)
	tokens := lexer.tokenize()

	println('=== TOKENS ===')
	for token in tokens {
		println(token)
	}

	// Parse
	mut parser := new_parser(tokens)
	functions := parser.parse_module().functions

	println('=== AST ===')
	println(functions)

	// Generate assembly
	mut codegen := new_codegen()
	for func in functions {
		codegen.generate_function(func)
	}

	println('=== ASSEMBLY ===')
	println(codegen.to_string())
	asm_output := codegen.to_string()
	os.write_file('./output.asm', asm_output) or { panic(err) }
	println('Assembly written to output.asm')
}
