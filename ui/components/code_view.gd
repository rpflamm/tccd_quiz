class_name CodeView
extends CodeEdit
## Read-only code snippet with simple syntax highlighting for PHP, YAML, TypoScript, HTML/Fluid, SQL, JSON, JS.

const KEYWORDS := {
	"php": ["namespace", "use", "class", "final", "readonly", "abstract", "interface", "trait", "enum", "extends",
		"implements", "public", "protected", "private", "static", "function", "fn", "return", "new", "if", "else",
		"elseif", "foreach", "as", "for", "while", "match", "throw", "try", "catch", "finally", "declare", "const",
		"null", "true", "false", "self", "parent", "array", "string", "int", "bool", "float", "void", "mixed",
		"never", "iterable", "callable", "instanceof", "yield", "echo", "case", "default", "break", "continue"],
	"js": ["import", "export", "from", "const", "let", "var", "function", "return", "new", "class", "extends",
		"if", "else", "for", "while", "async", "await", "true", "false", "null", "undefined", "this", "default"],
	"sql": ["SELECT", "FROM", "WHERE", "AND", "OR", "NOT", "INSERT", "INTO", "VALUES", "UPDATE", "SET", "DELETE",
		"CREATE", "TABLE", "ALTER", "ADD", "DROP", "INDEX", "PRIMARY", "KEY", "FOREIGN", "REFERENCES", "JOIN",
		"LEFT", "RIGHT", "INNER", "ON", "GROUP", "BY", "ORDER", "HAVING", "LIMIT", "AS", "NULL", "IS", "IN",
		"LIKE", "DISTINCT", "COUNT", "UNIQUE", "DEFAULT", "INT", "VARCHAR", "TEXT", "UNSIGNED", "AUTO_INCREMENT"],
	"typoscript": ["TEXT", "COA", "COA_INT", "USER", "USER_INT", "FLUIDTEMPLATE", "PAGEVIEW", "CONTENT",
		"RECORDS", "PAGE", "EXTBASEPLUGIN", "HMENU", "TMENU", "IMAGE", "FILES", "CASE", "LOAD_REGISTER",
		"@import", "lib", "page", "plugin", "config", "tt_content"],
}

const C_KEYWORD := Color("ff9e64")
const C_STRING := Color("9ece6a")
const C_COMMENT := Color("5f6b8a")
const C_NUMBER := Color("e0af68")
const C_SYMBOL := Color("89ddff")
const C_FUNCTION := Color("7aa2f7")
const C_MEMBER := Color("c0caf5")
const C_TAG := Color("f7768e")


func _init(src: String = "", lang: String = "text") -> void:
	editable = false
	text = src
	gutters_draw_line_numbers = true
	scroll_fit_content_height = true
	scroll_fit_content_width = false
	wrap_mode = TextEdit.LINE_WRAPPING_NONE
	highlight_current_line = false
	draw_tabs = false
	context_menu_enabled = false
	shortcut_keys_enabled = false
	selecting_enabled = true
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	focus_mode = Control.FOCUS_NONE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	syntax_highlighter = make_highlighter(lang)


static func make_highlighter(lang: String) -> CodeHighlighter:
	var h := CodeHighlighter.new()
	h.number_color = C_NUMBER
	h.symbol_color = C_SYMBOL
	h.function_color = C_FUNCTION
	h.member_variable_color = C_MEMBER
	var kw: Array = KEYWORDS.get(lang, [])
	for k in kw:
		h.add_keyword_color(k, C_KEYWORD)
		if lang == "sql":
			h.add_keyword_color(k.to_lower(), C_KEYWORD)
	match lang:
		"php", "js", "json":
			h.add_color_region("'", "'", C_STRING)
			h.add_color_region("\"", "\"", C_STRING)
			h.add_color_region("//", "", C_COMMENT, true)
			h.add_color_region("/*", "*/", C_COMMENT)
			if lang == "php":
				h.add_color_region("#[", "]", C_TAG)
				h.add_color_region("$", " ", C_MEMBER)
		"yaml":
			h.add_color_region("#", "", C_COMMENT, true)
			h.add_color_region("'", "'", C_STRING)
			h.add_color_region("\"", "\"", C_STRING)
		"typoscript", "tsconfig":
			h.add_color_region("#", "", C_COMMENT, true)
			h.add_color_region("//", "", C_COMMENT, true)
			h.add_color_region("/*", "*/", C_COMMENT)
			h.add_color_region("'", "'", C_STRING)
			h.add_color_region("\"", "\"", C_STRING)
		"html", "xml":
			h.add_color_region("<!--", "-->", C_COMMENT)
			h.add_color_region("\"", "\"", C_STRING)
			h.add_color_region("<", ">", C_TAG)
			h.add_color_region("{", "}", C_KEYWORD)
		"sql":
			h.add_color_region("'", "'", C_STRING)
			h.add_color_region("--", "", C_COMMENT, true)
		"bash":
			h.add_color_region("#", "", C_COMMENT, true)
			h.add_color_region("'", "'", C_STRING)
			h.add_color_region("\"", "\"", C_STRING)
	return h
