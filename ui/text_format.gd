class_name TextFormat
extends RefCounted
## Converts question text with `inline code` into BBCode for RichTextLabel.


static func escape(text: String) -> String:
	return text.replace("[", "[lb]")


## `code` -> [code] with accent colour; everything else escaped.
static func inline_code(text: String) -> String:
	var parts := text.split("`")
	var out := ""
	for i in parts.size():
		var p := escape(parts[i])
		if i % 2 == 1:
			out += "[color=#ffb347][code]%s[/code][/color]" % p
		else:
			out += p
	return out
