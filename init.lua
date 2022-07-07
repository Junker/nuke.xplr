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
local custom_commands = {}
local run_executables = true

local function program_exists(p)
	return (os.execute("type " .. p .. " > /dev/null 2>&1") == 0)
end

local function get_node_extension(node)
	return node.relative_path:match("^.+%.(.+)$")
end

local function handle_image(node)
	if program_exists("viu") then
		return {{ BashExec = 'viu "' .. node.absolute_path .. '" && read -n 1 -s && read -k' }}
	end
	if program_exists("timg") then
		return {{ BashExec = 'timg "' .. node.absolute_path .. '" && read -n 1 -s && read -k' }}
	end
	if program_exists("chafa") then
		return {{ BashExec = 'chafa "' .. node.absolute_path .. '" && read -n 1 -s && read -k' }}
	end
	if program_exists("img2txt") then
		return {{ BashExec = 'img2txt --gamma=0.6 -- "' .. node.absolute_path .. '" | ' .. pager }}
	end
end

local function handle_video(node)
	if program_exists("mpv") then
		return {{ Call = {command = "mpv", args = {"--vo=tct", "--quiet", node.absolute_path}} }}
	end
	if program_exists("mplayer") then
		return {{ BashExec = 'CACA_DRIVER=ncurses mplayer -vo caca -quiet "' .. node.absolute_path .. '"' }}
	end
end

local function handle_audio(node)
	if program_exists("mpv") then
		return {{ Call = {command = "mpv", args = {node.absolute_path}} }}
	elseif program_exists("mplayer") then
		return {{ Call = {command = "mplayer", args = {node.absolute_path}} }}
	end
end

local function handle_archive(node)
	if program_exists("atool") then
		return {{ BashExec = 'atool --list -- "' .. node.absolute_path .. '" | ' .. pager }}
	end
	if program_exists("dtrx") then
		return {{ BashExec = 'dtrx -l "' .. node.absolute_path .. '" | ' .. pager }}
	end
	if program_exists("ouch") then
		return {{ BashExec = 'ouch list "' .. node.absolute_path .. '" | ' .. pager }}
	end
end

local function handle_pdf(node)
	if program_exists("termpdf") and os.getenv("TERM") == "xterm-kitty" then
		return {{ Call = {command = "termpdf", args = {node.absolute_path}} }}
	elseif program_exists("pdftotext") then
		return {{ BashExec = 'pdftotext -l 10 -nopgbrk -q -- "' .. node.absolute_path .. '" - | ' .. pager }}
	end
end

local function handle_djvu(node)
	if program_exists("termpdf") and os.getenv("TERM") == "xterm-kitty" then
		return {{ Call = {command = "termpdf", args = {node.absolute_path}} }}
	end
end

local function handle_text(node)
	if program_exists(os.getenv("EDITOR")) then
		return {{ Call = {command = os.getenv("EDITOR"), args = {node.absolute_path}} }}
	end
end

local function handle_open_document(node)
	if program_exists("odt2txt") then
		return {{ BashExec = 'odt2txt "' .. node.absolute_path .. '" | ' .. pager }}
	end
end

local function handle_html(node)
	if program_exists("w3m") then
		return {{ Call = {command = "w3m", args = {"-dump", node.absolute_path}} }}
	elseif program_exists("lynx") then
		return {{ Call = {command = "lynx", args = {"-dump", "--", node.absolute_path}} }}
	elseif program_exists("elinks") then
		return {{ Call = {command = "elinks", args = {"-dump", node.absolute_path}} }}
	end
end


local function handle_markdown(node)
	if program_exists("glow") then
		return {{ BashExec = 'glow -sdark "' .. node.absolute_path .. '" | ' .. pager }}
	elseif program_exists("lowdown") then
		return {{ BashExec = 'lowdown -Tterm "' .. node.absolute_path .. '" | ' .. pager }}
	end
end

local function handle_executable(node)
	if program_exists("dialog") then
		return {{ BashExec = 'dialog --defaultno --yesno "Run executable?" 15 40 && ' .. node.absolute_path .. " ; (read -n 1 -s && read -k)" }}
	end
end

local function handle_custom(node, command)
	command = command:gsub("{}", '"' .. node.absolute_path .. '"')

	return {{ BashExec = command }}
end

local function handle_node(ctx)
	local node = ctx.focused_node
	local node_mime = node.mime_essence

	if node.is_dir or (node.is_symlink and node.symlink.is_dir) then
		return {"Enter"}
	end

	if node.is_dir == false or (node.is_symlink and node.symlink.is_dir == false) then
		for _,entry in ipairs(custom_commands) do
			local command = entry["command"]
			if command ~= nil then
				if get_node_extension(node) == entry["extension"] then
					return handle_custom(node, command)
				end
				if node_mime == entry["mime"] then
					return handle_custom(node, command)
				end
				if entry["mime_regex"] ~= nil and node_mime:match(entry["mime_regex"]) then
					return handle_custom(node, command)
				end
			end
		end

		if run_executables and node.permissions.user_execute or node.permissions.group_execute or node.permissions.other_execute then
			return handle_executable(node)
		end

		if node_mime == "image/vnd.djvu" then
			return handle_djvu(node)
		end

		if node_mime:match("^image/.*") then
			return handle_image(node)
		end

		if node_mime:match("^video/.*") then
			return handle_video(node)
		end

		if node_mime:match("^audio/.*") then
			return handle_audio(node)
		end

		if node_mime == "application/pdf" then
			return handle_pdf(node)
		end

		if node_mime == "text/markdown" then
			return handle_markdown(node)
		end

		if node_mime == "text/html" or node_mime == "application/xhtml+xml" then
			return handle_html(node)
		end

		for _,v in ipairs(archive_mime_types) do
			if node_mime == v then
				return handle_archive(node)
			end
		end

		for _,v in ipairs(open_document_mime_types) do
			if node_mime == v then
				return handle_open_document(node)
			end
		end
	end
end


local function setup(args)
	xplr.fn.custom.nuke_handle_node = handle_node

	if args.pager then
		pager = args.pager
	end

	if args.custom then
		custom_commands = args.custom
	end

	if args.run_executables  then
		run_executables = args.run_executables
	end
end


return { setup = setup }
