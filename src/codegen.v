module main

const sysv_arg_registers = ['rdi', 'rsi', 'rdx', 'rcx', 'r8', 'r9']

struct CodeGen {
mut:
	output          []string          // Lines of assembly
	param_registers map[string]string // Maps parameter names to registers
	label_counter   int               // 	Number of labels to be created(for control flow)
	local_variables map[string]int    // Maps variable name -> stack offset
	stack_offset    int               // Current stack position
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

fn (mut cg CodeGen) emit_comment(line string, comment string) {
	cg.output << '    ${line}  ; ${comment}'
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
	cg.emit('global ${func.name}')
	cg.emit('')
	cg.emit('${func.name}:')
	cg.emit_comment('push rbp', 'Save old base pointer')
	cg.emit_comment('mov rbp, rsp', 'Set up stack frame')

	cg.emit('    ; Lowlevel function body')
	for stmt in func.body {
		cg.generate_statement(stmt)
	}

	cg.emit_comment('mov rsp, rbp', 'Restore stack pointer')
	cg.emit_comment('pop rbp', 'Restore base pointer')
	cg.emit_comment('ret', 'Return to caller')
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

	cg.emit('global ${func.name}')
	cg.emit('')
	cg.emit('${func.name}:')
	cg.emit_comment('push rbp', 'Save old base pointer')
	cg.emit_comment('mov rbp, rsp', 'Set up new stack frame')

	// TODO: allocate stack for variables

	cg.emit('    ; Function body')
	for stmt in func.body {
		cg.generate_statement(stmt)
	}

	cg.emit_comment('mov rsp, rbp', 'Restore stack pointer')
	cg.emit_comment('pop rbp', 'Restore base pointer')
	cg.emit_comment('ret', 'Return to caller\n')

	cg.param_registers = map[string]string{}
}

fn (mut cg CodeGen) generate_return(stmt ReturnStatement) {
	cg.emit('    ; Evaluate return value')
	cg.generate_expression_to_rax(stmt.value)
	cg.emit('    ; (Return value now in rax)')
}

fn (mut cg CodeGen) generate_condition_jump(expr Expression, label string) {
	match expr {
		BinaryExpression {
			comparison_ops := ['>', '<', '>=', '<=', '==', '!=']
			if comparison_ops.contains(expr.op) {
				cg.emit('    ; Evaluate comparison for conditional jump')

				cg.emit('    ; Evaluate left side')
				cg.generate_expression_to_rax(expr.left)
				cg.emit_comment('push rax', 'Save left operand')

				cg.emit('    ; Evaluate right side')
				cg.generate_expression_to_rax(expr.right)
				cg.emit_comment('mov rbx, rax', 'Move right to rbx')
				cg.emit_comment('pop rax', 'Restore left to rax')

				cg.emit_comment('cmp rax, rbx', 'Compare left and right')

				// Jump based on comparison (inverted - jump if condition FALSE)
				jump_instr := match expr.op {
					'>' { 'jle' } // Jump if NOT greater (<=)
					'<' { 'jge' } // Jump if NOT less (>=)
					'>=' { 'jl' } // Jump if NOT >= (<)
					'<=' { 'jg' } // Jump if NOT <= (>)
					'==' { 'jne' } // Jump if NOT equal
					'!=' { 'je' } // Jump if NOT not-equal (equal)
					else { panic('Unhandled comparison operator: ${expr.op}') }
				}
				cg.emit_comment('${jump_instr} ${label}', 'Jump to ${label} if condition false')
			}
		}
		else {
			cg.emit('    ; Non-comparison condition - test for zero')
			cg.generate_expression_to_rax(expr)
			cg.emit_comment('test rax, rax', 'Test if zero')
			cg.emit_comment('jz ${label}', 'Jump if zero (false)')
		}
	}
}

fn (mut cg CodeGen) generate_if_statement(stmt IfStatement) {
	cg.emit('    ; --- If statement ---')

	// Generate unique labels
	else_label := 'else_${cg.label_counter}'
	end_label := 'end_${cg.label_counter}'
	cg.label_counter++

	// Evaluate condition and jump to else if false
	cg.emit('    ; Evaluate condition')
	cg.generate_condition_jump(stmt.condition, else_label)

	// Generate then block
	cg.emit('    ; Then block')
	for s in stmt.then_block {
		cg.generate_statement(s)
	}
	cg.emit_comment('jmp ${end_label}', 'Skip else block')

	// Generate else block
	cg.emit('${else_label}:')
	cg.emit('    ; Else block')
	for s in stmt.else_block {
		cg.generate_statement(s)
	}

	// End of if statement
	cg.emit('${end_label}:')
	cg.emit('    ; --- End if ---')
}

fn (mut cg CodeGen) generate_statement(stmt Statement) {
	match stmt {
		FunctionCall {
			cg.emit('    ; Opcode: ${stmt.name}')
			mut args_parts := []string{}
			for arg in stmt.args {
				args_parts << cg.argument_to_string(arg)
			}
			args_joined := args_parts.join(', ')
			instruction := '    ${stmt.name} ${args_joined}'
			cg.emit(instruction)
		}
		ReturnStatement {
			cg.emit('    ; Return statement')
			cg.generate_return(stmt)
		}
		IfStatement {
			cg.generate_if_statement(stmt)
		}
		LetStatement {
			cg.emit('    ; Variable declaration: ${stmt.name}')

			// Allocate stack space (8 bytes for int)
			cg.stack_offset += 8
			cg.local_variables[stmt.name] = cg.stack_offset

			// Evaluate the initializer into rax
			cg.generate_expression_to_rax(stmt.value)

			// Store rax to stack location
			cg.emit_comment('mov [rbp-${cg.stack_offset}], rax', 'Store to ${stmt.name}')
		}
	}
}

fn (mut cg CodeGen) generate_expression_to_rax(expr Expression) {
	match expr {
		BinaryExpression {
			cg.emit('    ; --- Binary expression: ${expr.op} ---')
			cg.emit('    ; Evaluate left operand')
			cg.generate_expression_to_rax(expr.left)
			cg.emit_comment('push rax', 'Save left result on stack')

			cg.emit('    ; Evaluate right operand')
			cg.generate_expression_to_rax(expr.right)
			cg.emit_comment('mov rbx, rax', 'Move right to rbx')
			cg.emit_comment('pop rax', 'Restore left to rax')

			match expr.op {
				'+' {
					cg.emit_comment('add rax, rbx', 'rax = rax + rbx')
				}
				'-' {
					cg.emit_comment('sub rax, rbx', 'rax = rax - rbx')
				}
				'*' {
					cg.emit_comment('imul rax, rbx', 'rax = rax * rbx')
				}
				'/' {
					cg.emit_comment('xor rdx, rdx', 'Clear rdx for division')
					cg.emit_comment('idiv rbx', 'rax = rdx:rax / rbx')
				}
				'>' {
					cg.emit_comment('cmp rax, rbx', 'Compare rax and rbx')
					cg.emit_comment('setg al', 'Set AL to 1 if rax > rbx')
					cg.emit_comment('movzx rax, al', 'Zero-extend AL to RAX')
				}
				'<' {
					cg.emit_comment('cmp rax, rbx', 'Compare rax and rbx')
					cg.emit_comment('setl al', 'Set AL to 1 if rax < rbx')
					cg.emit_comment('movzx rax, al', 'Zero-extend AL to RAX')
				}
				'>=' {
					cg.emit_comment('cmp rax, rbx', 'Compare rax and rbx')
					cg.emit_comment('setge al', 'Set AL to 1 if rax >= rbx')
					cg.emit_comment('movzx rax, al', 'Zero-extend AL to RAX')
				}
				'<=' {
					cg.emit_comment('cmp rax, rbx', 'Compare rax and rbx')
					cg.emit_comment('setle al', 'Set AL to 1 if rax <= rbx')
					cg.emit_comment('movzx rax, al', 'Zero-extend AL to RAX')
				}
				'==' {
					cg.emit_comment('cmp rax, rbx', 'Compare rax and rbx')
					cg.emit_comment('sete al', 'Set AL to 1 if rax == rbx')
					cg.emit_comment('movzx rax, al', 'Zero-extend AL to RAX')
				}
				'!=' {
					cg.emit_comment('cmp rax, rbx', 'Compare rax and rbx')
					cg.emit_comment('setne al', 'Set AL to 1 if rax != rbx')
					cg.emit_comment('movzx rax, al', 'Zero-extend AL to RAX')
				}
				else {
					panic('Unknown operator: ${expr.op}')
				}
			}
		}
		string {
			// Check if it's a parameter
			if expr in cg.param_registers {
				reg := cg.param_registers[expr]
				cg.emit_comment('mov rax, ${reg}', 'Load parameter "${expr}"')
			}
			// Check if it's a local variable
			else if expr in cg.local_variables {
				offset := cg.local_variables[expr]
				cg.emit_comment('mov rax, [rbp-${offset}]', 'Load variable "${expr}"')
			} else {
				panic('Unknown identifier: ${expr}')
			}
		}
		NumberLiteral {
			cg.emit_comment('mov rax, ${expr.value}', 'Load constant ${expr.value}')
		}
		CharLiteral {
			cg.emit_comment('mov rax, ${expr.value}', 'Load character literal (${expr.value})')
		}
		IfExpression {
			panic('If expressions not yet implemented!')
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
