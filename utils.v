module main

fn is_alpha(ch u8) bool {
	return (ch >= `a` && ch <= `z`) || (ch >= `A` && ch <= `Z`) || ch == `_`
}

fn is_digit(ch u8) bool {
	return ch >= `0` && ch <= `9`
}

fn is_alphanumeric(ch u8) bool {
	return is_alpha(ch) || is_digit(ch)
}
