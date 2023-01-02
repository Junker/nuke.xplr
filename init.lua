local archive_mime_types = {
	"application/x-tar",
	"application/x-bzip2",
	"application/gzip",
	"application/x-lzma",
	"application/x-xz",
	"application/x-compress",
	"application/zstd",
	"application/x-7z-compressed",
	"application/x-gtar",
	"application/zip",
	"application/x-lzop",
	"application/x-lzip",
	"application/java-archive",
	"application/x-rar-compressed",
	"application/x-lzh",
	"application/x-alz-compressed",
	"application/x-ace-compressed",
	"application/x-archive",
	"application/x-arj",
	"application/x-freearc",
	"application/x-rpm",
	"application/vnd.debian.binary-package",
	"application/vnd.ms-cab-compressed",
	"application/x-cpio"
};


local open_document_mime_types = {
	"application/vnd.oasis.opendocument.presentation",
	"application/vnd.oasis.opendocument.spreadsheet",
	"application/vnd.oasis.opendocument.text"
}

local pager = "less -R"
local open_custom_commands = {}
local smart_custom_commands = {}
local run_executables = true
local show_line_numbers = false

local nuke_mode = {
	name = "nuke",
	key_bindings = {
		on_key = {
			["o"] = {
				help = "open",
				messages = {
					{ CallLuaSilently = "custom.nuke_open" },
					"PopMode",

				},
			},
			["v"] = {
				help = "view",
				messages = {
					{ CallLuaSilently = "custom.nuke_view" },
					"PopMode",

				},
			},
			["s"] = {
				help = "smart view",
				messages = {
					{ CallLuaSilently = "custom.nuke_smart_view" },
					"PopMode",
				},
			},
			["h"] = {
				help = "hex view",
				messages = {
					{ CallLuaSilently = "custom.nuke_hex_view" },
					"PopMode",
				},
			},
			["i"] = {
				help = "info view",
				messages = {
					{ CallLuaSilently = "custom.nuke_info_view" },
					"PopMode",
				},
			},
			esc = {
				help = "cancel",
				messages = {
					"PopMode",
				},
			},
		},
	},
}

local function _if(bool, arg1, arg2)
	if bool then return arg1 else return arg2 end
end

local function _case(case, cases)
	local fn = cases[case]
	if (fn) then
		return fn()
	end
end

local function has_value (t, val)
    for index, value in ipairs(t) do
        if value == val then
            return true
        end
    end

    return false
end

local function table_to_string(t, delimiter)
	local str = ""
	for i,v in ipairs(t) do
		str = str .. v
		if t[i+1] ~= nil then
			str = str .. delimiter
		end
	end

	return str
end

local function program_exists(p)
	return (os.execute("type " .. p .. " > /dev/null 2>&1") == 0)
end


local function exec(command, node, ...)
	return {{ Call = {command = command, args = {node.absolute_path, ...}} }}
end

local function exec_paging(command, node, ...)
	local args = {...}
	local str_args = ""

	str_args = table_to_string(args, " ")

	return {{ BashExec = string.format('%s %s "%s" | %s', command, str_args, node.absolute_path, pager) }}
end

local function exec_waiting(command, node, ...)
	local args = {...}
	local str_args = ""

	str_args = table_to_string(args, " ")

	return {{ BashExec = string.format('%s %s "%s" && read -p "[enter to continue]"', command, str_args, node.absolute_path) }}
end

local function exec_paging_html(command, node, ...)
	local args = {...}
	local str_args = ""
	local dumper = nil

	str_args = table_to_string(args, " ")

	if program_exists("w3m") then
		dumper = 'w3m -T text/html -dump'
	elseif program_exists("elinks") then
		dumper = 'elinks -dump'
	elseif program_exists("lynx") then
		dumper = 'lynx -dump -stdin'
	end

	if dumper then
		return {{ BashExec = string.format('%s %s "%s" | %s | %s', command, str_args, node.absolute_path, dumper, pager) }}
	end
end

local function exec_custom(command, node)
	command = command:gsub("{}", '"' .. node.absolute_path .. '"')

	return {{ BashExec = command }}
end


local function program_exists(p)
	return (os.execute("type " .. p .. " > /dev/null 2>&1") == 0)
end

local function get_node_extension(node)
	return node.relative_path:match("^.+%.(.+)$")
end

local function open_image(node)
	if program_exists("viu") then
		return exec_waiting("viu", node)
	elseif program_exists("timg") then
		return exec_waiting("timg", node)
	elseif program_exists("chafa") then
		return exec_waiting("chafa", node)
	elseif program_exists("cacaview") then
		return exec_paging("cacaview", node)
	end
end

local function open_video(node)
	if program_exists("mpv") then
		return exec("mpv", node, "--vo=tct", "--quiet")
	elseif program_exists("mplayer") then
		return {{ BashExec = 'CACA_DRIVER=ncurses mplayer -vo caca -quiet "' .. node.absolute_path .. '"' }}
	end
end

local function open_audio(node)
	if program_exists("mpv") then
		return exec("mpv", node)
	elseif program_exists("mplayer") then
		return exec("mplayer", node, "-vo null")
	end
end

local function open_pdf(node)
	if program_exists("termpdf") and os.getenv("TERM") == "xterm-kitty" then
		return exec("termpdf", node)
	elseif program_exists("pdftotext") then
		return {{ BashExec = 'pdftotext -l 10 -nopgbrk -q -- "' .. node.absolute_path .. '" - | ' .. pager }}
	end
end

local function open_djvu(node)
	if program_exists("termpdf") and os.getenv("TERM") == "xterm-kitty" then
		return exec("termpdf", node)
	end
end

local function open_text(node)
	if program_exists(os.getenv("EDITOR")) then
		return exec(os.getenv("EDITOR"), node)
	end
end

local function open_executable(node)
	return {{ BashExec = node.absolute_path .. ' ; read -p "[enter to continue]"' }}
end


local function open(ctx)
	local node = ctx.focused_node
	local node_mime = node.mime_essence

	if node.is_dir or (node.is_symlink and node.symlink.is_dir) then
		return {"Enter"}
	end

	if node.is_dir == false or (node.is_symlink and node.symlink.is_dir == false) then
		for _,entry in ipairs(open_custom_commands) do
			local command = entry["command"]
			if command ~= nil then
				if get_node_extension(node) == entry["extension"] then
					return exec_custom(command, node)
				end
				if node_mime == entry["mime"] then
					return exec_custom(command, node)
				end
				if entry["mime_regex"] ~= nil and node_mime:match(entry["mime_regex"]) then
					return exec_custom(command, node)
				end
			end
		end

		if node_mime == "image/vnd.djvu" then
			return open_djvu(node)
		elseif node_mime:match("^image/.*") then
			return open_image(node)
		elseif node_mime:match("^video/.*") then
			return open_video(node)
		elseif node_mime:match("^audio/.*") then
			return open_audio(node)
		elseif node_mime == "application/pdf" then
			return open_pdf(node)
		elseif node_mime:match("^text/.*") or
			(node_mime:match("^application/.*") and
				not (node_mime == "application/ogg"
					or node_mime == "application/msword"
					or node_mime == "application/epub+zip"
					or node_mime:match("^application/vnd.*")
					or has_value(archive_mime_types, node_mime))) then
			return open_text(node)
		end

		if run_executables and node.permissions.user_execute or node.permissions.group_execute or node.permissions.other_execute then
			return open_executable(node)
		end
	end
end


local function hex_view(ctx)
	local node = ctx.focused_node

	if node.is_dir == false or (node.is_symlink and node.symlink.is_dir == false) then
		if program_exists("hx") then
			return exec_paging("hx", node, "-t 1")
		elseif program_exists("hexyl") then
			return exec_paging("hexyl", node)
		elseif program_exists("huxd") then
			return exec_paging("huxd", node, "-C always", "-P never")
		elseif program_exists("hxl") then
			return exec_paging("hxl", node)
		elseif program_exists("hexdump") then
			return exec_paging("hexdump", node)
		end
	end
end

local function view_node(node)
	if program_exists("bat") then
		return exec_paging("bat", node, "--color always", "--paging never", _if(show_line_numbers, "--style=plain,numbers", "--style=plain"))
	end
	if program_exists("pygmentize") then
		return exec_paging("pygmentize", node, "-g")
	end

	return exec_paging("less", node, _if(show_line_numbers, "-N", ""))
end

local function view(ctx)
	local node = ctx.focused_node

	if node.is_dir == false or (node.is_symlink and node.symlink.is_dir == false) then
		return view_node(node)
	end
end


local function info_view_node(node)
	if program_exists("exiftool") then
		return exec_paging("exiftool", node)
	end

	return exec_paging("file", node)
end

local function info_view_image(node)
	if program_exists("mediainfo") then
		return exec_paging("mediainfo", node)
	end

	return info_view_node(node)
end

local function info_view_video(node)
	if program_exists("mediainfo") then
		return exec_paging("mediainfo", node)
	elseif program_exists("mplayer") then
		return exec_paging("mplayer", node, "-identify", "-vo null", "-ao null", "-frames 0")
	end

	return info_view_node(node)
end

local function info_view_audio(node)
	if program_exists("mediainfo") then
		return exec_paging("mediainfo", node)
	elseif program_exists("mplayer") then
		return exec_paging("mplayer", node, "-identify", "-vo null", "-ao null", "-frames 0")
	end

	return info_view_node(node)
end


local function info_view_epub(node)
	if program_exists("einfo") then
		return exec_paging("einfo", node, "-v");
	end
end


local function info_view(ctx)
	local node = ctx.focused_node
	local node_mime = node.mime_essence

	if node.is_dir == false or (node.is_symlink and node.symlink.is_dir == false) then
		if node_mime:match("^image/.*") then
			return info_view_image(node)
		end
		if node_mime:match("^video/.*") then
			return info_view_video(node)
		end
		if node_mime == "application/epub+zip" then
			return info_view_epub(node)
		end

		return info_view_node(node)
	end
end

local function smart_view_archive(node)
	if program_exists("atool") then
		return exec_paging("atool", node, "--list", "--")
	end
end

local function smart_view_open_document(node)
	if program_exists("odt2txt") then
		return exec_paging("odt2txt", node)
	end
end

local function smart_view_man(node)
	return {{ BashExec = 'MANROFFOPT=-c MAN_KEEP_FORMATTING=1 man -P cat "' .. node.absolute_path .. '" | ' .. pager }}
end

local function smart_view_pdf(node)
	if program_exists("pdftotext") then
		return {{ BashExec = 'pdftotext -l 10 -nopgbrk -q -- "' .. node.absolute_path .. '" - | ' .. pager }}
	end
end

local function smart_view_ps(node)
	if program_exists("ps2ascii") then
		return exec_paging("ps2ascii", node);
	end
end

local function smart_view_image(node)
	if program_exists("viu") then
		return exec_paging("viu", node, "-b", "-s");
	elseif program_exists("chafa") then
		return exec_paging("chafa", node, "--animate=false", "--format=symbols");
	elseif program_exists("catimg") then
		return exec_paging("catimg", node);
	elseif program_exists("img2txt") then
		return exec_paging("img2txt", node, "--gamma=0.6", "--")
	end

	return info_view_image(node)
end

local function smart_view_md(node)
	if program_exists("glow") then
		return exec_paging("glow", node, "-sdark")
	elseif program_exists("lowdown") then
		return exec_paging("lowdown", node, "-Tterm")
	elseif program_exists("mdless") then
		return {{ Call = {command="mdless", args={node.absolute_path}} }}
	end
end

local function smart_view_djvu(node)
	if program_exists("djvused") then
		return exec_paging("djvused", node, "-e print-pure-txt");
	end
end

local function smart_view_html(node)
	return exec_paging_html("cat", node)
end

local function smart_view_doc(node)
	if program_exists("antiword") then
		return exec_paging("antiword", node, "-t");
	elseif program_exists("catdoc") then
		return exec_paging("catdoc", node, "-w");
	elseif program_exists("wvWare") then
		return exec_paging_html("wvWare", node)
	end
end

local function smart_view_docx(node)
	if program_exists("pandoc") then
		return exec_paging("pandoc", node, "-o -", "-t plain")
	elseif program_exists("lowriter") then
		return {{ BashExec = 'VIEWRTMP=`mktemp -q -d ${TMPDIR:-/tmp}/xplr-nuke.XXXXXX` && cp "'
					  .. node.absolute_path
					  .. '" $VIEWRTMP/temp.docx && cd $VIEWRTMP && libreoffice --headless --convert-to txt $VIEWRTMP/temp.docx > /dev/null 2>&1 && cat $VIEWRTMP/temp.txt | '
					  .. pager .. ' && rm -rf "$VIEWRTMP"'}}
	end
end

local function smart_view_xlsx(node)
	if program_exists("lowriter") then
		local cmd = 'VIEWRTMP=`mktemp -q -d ${TMPDIR:-/tmp}/xplr-nuke.XXXXXX` && cp "'
			.. node.absolute_path
			.. '" $VIEWRTMP/temp.xlsx && cd $VIEWRTMP && libreoffice --headless --convert-to html $VIEWRTMP/temp.xlsx > /dev/null 2>&1 '
			.. '&& cat $VIEWRTMP/temp.html | %s | ' .. pager
			.. ' && rm -rf "$VIEWRTMP"'

		if program_exists("w3m") then
			return {{ BashExec = string.format(cmd, "w3m -T text/html -dump") }}
		elseif program_exists("elinks") then
			return {{ BashExec = string.format(cmd, "elinks -dump") }}
		elseif program_exists("lynx") then
			return {{ BashExec = string.format(cmd, "lynx -dump -stdin") }}
		end
	end
end

local function smart_view_xls(node)
	if program_exists("xlhtml") then
		return exec_paging_html("xlhtml", node, "-a")
	end

	if program_exists("xls2csv") then
		return exec_paging("xls2csv", node);
	end
end

local function smart_view_epub(node)
	if program_exists("pandoc") then
		return exec_paging("pandoc", node, "-o -", "-t plain")
	end

	return info_view_epub(node)
end

local function smart_view_fb2(node)
	if program_exists("pandoc") then
		return exec_paging("pandoc", node, "-o -", "-t plain")
	end

	return info_view_epub(node)
end

local function smart_view(ctx)
	local node = ctx.focused_node
	local node_mime = node.mime_essence

	if node.is_dir == false or (node.is_symlink and node.symlink.is_dir == false) then

		for _,entry in ipairs(smart_custom_commands) do
			local command = entry["command"]
			if command ~= nil then
				if get_node_extension(node) == entry["extension"] then
					return exec_custom(command, node)
				end
				if node_mime == entry["mime"] then
					return exec_custom(command, node)
				end
				if entry["mime_regex"] ~= nil and node_mime:match(entry["mime_regex"]) then
					return exec_custom(command, node)
				end
			end
		end

		local cases = {
			["application/x-troff-man"] = function() return smart_view_man(node) or view_node(node) end,
			["application/pdf"] = function() return smart_view_pdf(node) end,
			["application/postscript"] = function() return smart_view_ps(node) end,
			["text/markdown"] = function() return smart_view_md(node) or view_node(node) end,
			["text/html"] = function() return smart_view_html(node) or view_node(node) end,
			["application/xhtml+xml"] = function() return smart_view_html(node) or view_node(node) end,
			["image/vnd.djvu"] = function() return smart_view_djvu(node) end,
			["application/msword"] = function() return smart_view_doc(node) end,
			["application/vnd.openxmlformats-officedocument.wordprocessingml.document"] = function() return smart_view_docx(node) end,
			["application/vnd.ms-excel"] = function() return smart_view_xls(node) end,
			["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"] = function() return smart_view_xlsx(node) end,
			["application/epub+zip"] = function() return smart_view_epub(node) end,
		}

		local res = _case(node_mime, cases);
		if res then return res end

		local cases = {
			["fb2"] = function() return smart_view_fb2(node) end,
		}

		local res = _case(get_node_extension(node), cases);
		if res then return res end


		if node_mime:match("^image/.*") then
			return smart_view_image(node)
		elseif node_mime:match("^video/.*") then
			return info_view_video(node)
		elseif node_mime:match("^audio/.*") then
			return info_view_audio(node)
		elseif node_mime:match("^text/.*") then
			return view_node(node)
		end

		for smart_view_,v in ipairs(archive_mime_types) do
			if node_mime == v then
				return smart_view_archive(node)
			end
		end

		for smart_view_,v in ipairs(open_document_mime_types) do
			if node_mime == v then
				return smart_view_open_document(node)
			end
		end

		return info_view_node(node)
	end
end


local function setup(args)
	xplr.config.modes.custom.nuke = nuke_mode
	xplr.fn.custom.nuke_view = view
	xplr.fn.custom.nuke_hex_view = hex_view
	xplr.fn.custom.nuke_info_view = info_view
	xplr.fn.custom.nuke_smart_view = smart_view
	xplr.fn.custom.nuke_open = open
	
	if args == nil then
		args = {}
	end

	if args.pager then
		pager = args.pager
	end

	if args.view then
		if args.view.show_line_numbers then
			show_line_numbers = args.view.show_line_numbers
		end
	end

	if args.open then
		if args.open.custom then
			open_custom_commands = args.open.custom
		end

		if args.open.run_executables  then
			run_executables = args.open.run_executables
		end
	end

	if args.smart_view then
		if args.smart_view.custom then
			smart_custom_commands = args.smart_view.custom
		end
	end
end


return { setup = setup }
