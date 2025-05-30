class_name GMCUtil

## Traverse a node and find all MPFVariable nodes within it
static func find_variables(n: Node, acc: Array[Node] = []) -> Array[Node]:
	for c in n.get_children():
		if c.get_child_count():
			find_variables(c, acc)
		if c is MPFVariable or c is MPFConditional:
			acc.append(c)
	return acc


static func find_parent_slide(n: Node, allow_widget: bool = false):
	var parent = n
	while parent:
		if parent is MPFSlide:
			return parent
		if allow_widget and parent is MPFWidget:
			return parent
		parent = parent.get_parent()
	if not parent:
		printerr("No parent slide or widget found in for %s" % n.name)
		return

static func find_parent_slide_or_widget(n: Node):
	return find_parent_slide(n, true)

static func find_parent_display(n: Node):
	var parent = n
	while parent:
		if parent is MPFDisplay:
			return parent
		parent = parent.get_parent()
	if not parent:
		printerr("No parent display found for %s" % n.name)
		return

static func find_parent_window(n: Node):
	var parent = n
	while parent:
		if parent is MPFWindow:
			return parent
		parent = parent.get_parent()
	if not parent:
		printerr("No parent window found in for %s" % n.name)
		return

## Receive an integer value and return a comma-separated string
static func comma_sep(n: int) -> String:
	var result := ""
	var i: int = int(abs(n))

	while i > 999:
		result = ",%03d%s" % [i % 1000, result]
		i /= 1000

	return "%s%s%s" % ["-" if n < 0 else "", i, result]

## Receive a string template and an integer, return the string
## formatted with an "s" if the number is anything other than 1
static func pluralize(template: String, val: int, suffix: String = "s") -> String:
	return template % ("" if val == 1 else suffix)

## Receive a number of seconds and return a M:SS formatted string
static func mins_secs(n: int, min_min_digits=1, min_sec_digits=2, include_leading_delim=false) -> String:
	var minutes := n / 60
	var seconds := n % 60
	if minutes or min_min_digits:
		return "%0*d:%0*d" % [min_min_digits, minutes, min_sec_digits, seconds]

	var template := ":%0*d" if include_leading_delim else "%0*d"
	return template % [min_sec_digits, seconds]

static func to_int(x) -> int:
	return int(x)

static func to_float(x) -> float:
	return float(x)

static func no_op(x):
	return x
