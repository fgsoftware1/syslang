module main

const sysv_arg_registers = ['rdi', 'rsi', 'rdx', 'rcx', 'r8', 'r9']

struct CodeGen {
mut:
	output          []string          // Lines of assembly
	param_registers map[string]string // Maps parameter names to registers
	label_counter   int               // 	Number of labels to be created(for control flow)
}

fn new_codegen() CodeGen {
	return CodeGen{
		output:          []string{}
		param_registers: map[string]string{}
		label_counter:   0
	}
}

fn (mut cg CodeGen) emit(line string) {
	cg.output << line
}

fn (cg CodeGen) to_string() string {
	return cg.output.join('\n')
}

fn (mut cg CodeGen) generate_function(func Function) {
	match func {
		LowlevelFunction {
			cg.generate_lowlevel_function(func)
		}
		NormalFunction {
			cg.generate_normal_function(func)
		}
	}
}

fn (mut cg CodeGen) generate_lowlevel_function(func LowlevelFunction) {
	// Your existing generate_function code
	cg.emit('global ${func.name}')
	cg.emit('')
	cg.emit('${func.name}:')
	cg.emit('    push rbp')
	cg.emit('    mov rbp, rsp')

	for stmt in func.body {
		cg.generate_statement(stmt)
	}

	cg.emit('    mov rsp, rbp')
	cg.emit('    pop rbp')
	cg.emit('    ret')
}

fn (mut cg CodeGen) generate_normal_function(func NormalFunction) {
	// Build parameter -> register mapping
	cg.param_registers = map[string]string{}

	for i, param in func.params {
		if i < sysv_arg_registers.len {
			cg.param_registers[param.name] = sysv_arg_registers[i]
		} else {
			panic('More than 6 parameters not supported yet')
		}
	}

	// Function prologue
	cg.emit('global ${func.name}')
	cg.emit('')
	cg.emit('${func.name}:')
	cg.emit('    push rbp')
	cg.emit('    mov rbp, rsp')

	// Generate body
	for stmt in func.body {
		cg.generate_statement(stmt)
	}

	// Epilogue
	cg.emit('    mov rsp, rbp')
	cg.emit('    pop rbp')
	cg.emit('    ret')

	// Clear the mapping after function
	cg.param_registers = map[string]string{}
}

fn (mut cg CodeGen) generate_return(stmt ReturnStatement) {
	cg.generate_expression_to_rax(stmt.value)
}

fn (mut cg CodeGen) generate_condition_jump(expr Expression, label string) {
	match expr {
		BinaryExpression {
			comparison_ops := ['>', '<', '>=', '<=', '==', '!=']
			if comparison_ops.contains(expr.op) {
				left_str := cg.expression_value_to_string(expr.left)
				right_str := cg.expression_value_to_string(expr.right)

				cg.emit('    cmp ${left_str}, ${right_str}')

				jump_instr := match expr.op {
					'>' { 'jle' } // Jump if left <= right (condition false)
					'<' { 'jge' } // Jump if left >= right (condition false)
					'>=' { 'jl' } // Jump if left < right (condition false)
					'<=' { 'jg' } // Jump if left > right (condition false)
					'==' { 'jne' } // Jump if not equal (condition false)
					'!=' { 'je' } // Jump if equal (condition false)
					else { panic('Unhandled comparison operator: ${expr.op}') }
				}
				cg.emit('    ${jump_instr} ${label}')
			} else {
				cg.generate_expression_to_rax(expr)
				cg.emit('    test rax, rax')
				cg.emit('    jz ${label}')
			}
		}
		else {
			cg.generate_expression_to_rax(expr)
			cg.emit('    test rax, rax')
			cg.emit('    jz ${label}')
		}
	}
}

fn (mut cg CodeGen) generate_if_statement(stmt IfStatement) {
	// Generate unique labels
	else_label := 'else_${cg.label_counter}'
	end_label := 'end_${cg.label_counter}'
	cg.label_counter++

	// Evaluate condition and jump
	cg.generate_condition_jump(stmt.condition, else_label) // Jump to else if false

	// Generate then block
	for s in stmt.then_block {
		cg.generate_statement(s)
	}
	cg.emit('    jmp ${end_label}') // Skip else block

	// Generate else block
	cg.emit('${else_label}:')
	for s in stmt.else_block {
		cg.generate_statement(s)
	}

	// End label
	cg.emit('${end_label}:')
}

fn (mut cg CodeGen) generate_statement(stmt Statement) {
	match stmt {
		FunctionCall {
			mut args_parts := []string{}
			for arg in stmt.args {
				args_parts << cg.argument_to_string(arg)
			}
			args_joined := args_parts.join(', ')
			instruction := '    ${stmt.name} ${args_joined}'
			cg.emit(instruction)
		}
		ReturnStatement {
			cg.generate_return(stmt)
		}
		IfStatement {
			cg.generate_if_statement(stmt)
		}
	}
}

fn (mut cg CodeGen) generate_expression_to_rax(expr Expression) {
	match expr {
		BinaryExpression {
			left_reg := cg.param_registers[expr.left]
			right_reg := cg.param_registers[expr.right]

			cg.emit('    mov rax, ${left_reg}')

			// Now handle the operator
			match expr.op {
				'+' { cg.emit('    add rax, ${right_reg}') }
				'-' { cg.emit('    sub rax, ${right_reg}') }
				'*' { cg.emit('    imul rax, ${right_reg}') }
				'/' { cg.emit('    idiv ${right_reg}') }
				else { panic('Unknown operator: ${expr.op}') }
			}
		}
		NumberLiteral {
			cg.emit('    mov rax, ${expr.value}')
		}
		CharLiteral {
			cg.emit('    mov rax, ${u8(expr.value)}')
		}
		else {
			panic('Unsupported expression in generate_expression_to_rax: ${expr}')
		}
	}
}

fn (_ CodeGen) argument_to_string(arg Argument) string {
	match arg {
		RegisterOperand {
			return arg.name
		}
		ImmediateOperand {
			return arg.value.str()
		}
	}
}

fn (cg CodeGen) expression_value_to_string(expr Expression) string {
	match expr {
		string {
			return cg.param_registers[expr]
		}
		else {
			return error('No valid ASCII value!').str()
		}
	}
}
