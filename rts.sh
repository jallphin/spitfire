#!/usr/bin/env bash

# First things first, elevate to root:
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"


### THE CODE BELOW THIS LINE IS COPYRIGHT Aristocratos (jakob@qvantnet.com) EXCEPT THE BANNER CODE FOR RTS, MODIFIED UNDER THE TERMS OF THE APACHE 2.0 LICENSE UNDER DERITIVE WORK######
# Copyright 2020 Aristocratos (jakob@qvantnet.com)
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#        http://www.apache.org/licenses/LICENSE-2.0
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

declare -x LC_MESSAGES="C" LC_NUMERIC="C" LC_ALL=""

#* Fail if running on unsupported OS
case "$(uname -s)" in
	Linux*)  system=Linux;;
	*BSD)	 system=BSD;;
	Darwin*) system=MacOS;;
	CYGWIN*) system=Cygwin;;
	MINGW*)  system=MinGw;;
	*)       system="Other"
esac
if [[ ! $system =~ Linux|MacOS|BSD ]]; then
	echo "This version of RTS does not support $system platform."
	exit 1
fi

#* Fail if Bash version is below 4.4
bash_version_major=${BASH_VERSINFO[0]}
bash_version_minor=${BASH_VERSINFO[1]}
if [[ "$bash_version_major" -lt 4 ]] || [[ "$bash_version_major" == 4 && "$bash_version_minor" -lt 4 ]]; then
	echo "ERROR: Bash 4.4 or later is required (you are using Bash $bash_version_major.$bash_version_minor)."
	exit 1
fi

shopt -qu failglob nullglob
shopt -qs extglob globasciiranges globstar

#* Check for UTF-8 locale and set LANG variable if not set
if [[ ! $LANG =~ UTF-8 ]]; then
	if [[ -n $LANG && ${LANG::1} != "C" ]]; then old_lang="${LANG%.*}"; fi
	for set_lang in $(locale -a); do
		if [[ $set_lang =~ utf8|UTF-8 ]]; then
			if [[ -n $old_lang && $set_lang =~ ${old_lang} ]]; then
				declare -x LANG="${set_lang/utf8/UTF-8}"
				set_lang_search="found"
				break
			elif [[ -z $first_lang ]]; then
				first_lang="${set_lang/utf8/UTF-8}"
				set_lang_first="found"
			fi
			if [[ -z $old_lang ]]; then break; fi
		fi
	done
	if [[ $set_lang_search != "found" && $set_lang_first != "found" ]]; then
		echo "ERROR: No UTF-8 locale found!"
		exit 1
	elif [[ $set_lang_search != "found" ]]; then
			declare -x LANG="${first_lang/utf8/UTF-8}"
	fi
	unset old_lang set_lang first_lang set_lang_search set_lang_first
fi

declare -a banner banner_colors

banner=(
"██████╗     ████████╗    ███████╗ "
"██╔══██╗    ╚══██╔══╝    ██╔════╝ "
"██████╔╝       ██║       ███████╗ "
"██╔══██╗       ██║       ╚════██║ "
"██║  ██║       ██║       ███████║ "
"╚═╝  ╚═╝       ╚═╝       ╚══════╝ ")

#* Get latest version of BashTOP from https://github.com/aristocratos/bashtop

declare banner_width=${#banner[0]}
banner_colors=("#E62525" "#CD2121" "#B31D1D" "#9A1919" "#801414")

#* Set correct names for GNU tools depending on OS
if [[ $system != "Linux" ]]; then tool_prefix="g"; fi
for tool in "dd" "df" "stty" "tail" "realpath" "wc" "rm" "mv" "sleep" "stdbuf" "mkfifo" "date" "kill" "sed"; do
	declare -n set_tool="${tool}"
	set_tool="${tool_prefix}${tool}"
done

if ! command -v ${dd} >/dev/null 2>&1; then
	echo "ERROR: Missing GNU coreutils!"
	exit 1
elif ! command -v ${sed} >/dev/null 2>&1; then
	echo "ERROR: Missing GNU sed!"
	exit 1
fi

read tty_height tty_width < <(${stty} size)
color_theme="Default"
#declare -A cpu mem swap proc net box theme disks
#declare -a cpu_usage cpu_graph_a cpu_graph_b color_meter color_temp_graph color_cpu color_cpu_graph cpu_history color_mem_graph color_swap_graph
#declare -a mem_history swap_history net_history_download net_history_upload mem_graph swap_graph proc_array download_graph upload_graph trace_array
#declare resized=1 size_error clock tty_width tty_height hex="16#" cpu_p_box swap_on=1 draw_out esc_character boxes_out last_screen clock_out update_string
#declare -a options_array=("color_theme" "update_ms" "use_psutil" "proc_sorting" "proc_tree" "check_temp" "draw_clock" "background_update" "custom_cpu_name"
#	"proc_per_core" "proc_reversed" "proc_gradient" "disks_filter" "hires_graphs" "net_totals_reset" "update_check" "error_logging")
#declare -a save_array=(${options_array[*]/net_totals_reset/})
#declare -a sorting=( "pid" "program" "arguments" "threads" "user" "memory" "cpu lazy" "cpu responsive")
#declare -a detail_graph detail_history detail_mem_history disks_io
#declare -A pid_history
#declare time_left timestamp_start timestamp_end timestamp_input_start timestamp_input_end time_string mem_out proc_misc prev_screen pause_screen filter input_to_filter
#declare no_epoch proc_det proc_misc2 sleeping=0 detail_mem_graph proc_det2 proc_out curled git_version has_iostat sensor_comm failed_pipes=0 py_error
#declare esc_character tab backspace sleepy late_update skip_process_draw winches quitting theme_int notifier saved_stty nic_int net_misc skip_net_draw
#declare psutil_disk_fail
#declare -a disks_free disks_total disks_name disks_free_percent saved_key themes nic_list old_procs
printf -v esc_character "\u1b"
printf -v tab "\u09"
printf -v backspace "\u7F" #? Backspace set to DELETE
printf -v backspace_real "\u08" #? Real backspace
#printf -v enter_key "\uA"
printf -v enter_key "\uD"
printf -v ctrl_c "\u03"
printf -v ctrl_z "\u1A"

hide_cursor='\033[?25l'		#* Hide terminal cursor
show_cursor='\033[?25h'		#* Show terminal cursor
alt_screen='\033[?1049h'	#* Switch to alternate screen
normal_screen='\033[?1049l'	#* Switch to normal screen
clear_screen='\033[2J'		#* Clear screen
nocolor='\e[0m'

##* Symbols for graphs
#declare -a graph_symbol
#graph_symbol=(" " "⡀" "⣀" "⣄" "⣤" "⣦" "⣴" "⣶" "⣷" "⣾" "⣿")
#graph_symbol+=( " " "⣿" "⢿" "⡿" "⠿" "⠻" "⠟"  "⠛" "⠙" "⠉" "⠈")
#declare -A graph_symbol_up='(
#	[0_0]=⠀ [0_1]=⢀ [0_2]=⢠ [0_3]=⢰ [0_4]=⢸
#	[1_0]=⡀ [1_1]=⣀ [1_2]=⣠ [1_3]=⣰ [1_4]=⣸
#	[2_0]=⡄ [2_1]=⣄ [2_2]=⣤ [2_3]=⣴ [2_4]=⣼
#	[3_0]=⡆ [3_1]=⣆ [3_2]=⣦ [3_3]=⣶ [3_4]=⣾
#	[4_0]=⡇ [4_1]=⣇ [4_2]=⣧ [4_3]=⣷ [4_4]=⣿
#)'
#declare -A graph_symbol_down='(
#	[0_0]=⠀ [0_1]=⠈ [0_2]=⠘ [0_3]=⠸ [0_4]=⢸
#	[1_0]=⠁ [1_1]=⠉ [1_2]=⠙ [1_3]=⠹ [1_4]=⢹
#	[2_0]=⠃ [2_1]=⠋ [2_2]=⠛ [2_3]=⠻ [2_4]=⢻
#	[3_0]=⠇ [3_1]=⠏ [3_2]=⠟ [3_3]=⠿ [3_4]=⢿
#	[4_0]=⡇ [4_1]=⡏ [4_2]=⡟ [4_3]=⡿ [4_4]=⣿
#)'
declare -A graph
#box[boxes]="cpu mem net processes"

#cpu[threads]=0

#* Symbols for subscript function
subscript=("₀" "₁" "₂" "₃" "₄" "₅" "₆" "₇" "₈" "₉")

#* Symbols for create_box function
box[single_hor_line]="─"
box[single_vert_line]="│"
box[single_left_corner_up]="┌"
box[single_right_corner_up]="┐"
box[single_left_corner_down]="└"
box[single_right_corner_down]="┘"
box[single_title_left]="├"
box[single_title_right]="┤"

box[double_hor_line]="═"
box[double_vert_line]="║"
box[double_left_corner_up]="╔"
box[double_right_corner_up]="╗"
box[double_left_corner_down]="╚"
box[double_right_corner_down]="╝"
box[double_title_left]="╟"
box[double_title_right]="╢"

print() {	#? Print text, set true-color foreground/background color, add effects, center text, move cursor, save cursor position and restore cursor postion
			#? Effects: [-fg, -foreground <RGB Hex>|<R Dec> <G Dec> <B Dec>] [-bg, -background <RGB Hex>|<R Dec> <G Dec> <B Dec>] [-rs, -reset] [-/+b, -/+bold] [-/+da, -/+dark]
			#? [-/+ul, -/+underline] [-/+i, -/+italic] [-/+bl, -/+blink] [-f, -font "sans-serif|script|fraktur|monospace|double-struck"]
			#? Manipulation: [-m, -move <line> <column>] [-l, -left <x>] [-r, -right <x>] [-u, -up <x>] [-d, -down <x>] [-c, -center] [-sc, -save] [-rc, -restore]
			#? [-jl, -justify-left <width>] [-jr, -justify-right <width>] [-jc, -justify-center <width>] [-rp, -repeat <x>]
			#? Text: [-v, -variable "variable-name"] [-stdin] [-t, -text "string"] ["string"]

	#* Return if no arguments is given
	if [[ -z $1 ]]; then return; fi

	#* Just echo and return if only one argument and not a valid option
	if [[ $# -eq 1 && ${1::1} != "-"  ]]; then echo -en "$1"; return; fi

	local effect color add_command text text2 esc center clear fgc bgc fg_bg_div tmp tmp_len bold italic custom_font val var out ext_var hex="16#"
	local justify_left justify_right justify_center repeat r_tmp trans


	#* Loop function until we are out of arguments
	until (($#==0)); do

		#* Argument parsing
		until (($#==0)); do
			case $1 in
				-t|-text) text="$2"; shift 2; break;;																#? String to print
				-stdin) text="$(</dev/stdin)"; shift; break;;																				#? Print from stdin
				-fg|-foreground)	#? Set text foreground color, accepts either 6 digit hexadecimal "#RRGGBB", 2 digit hex (greyscale) or decimal RGB "<0-255> <0-255> <0-255>"
					if [[ ${2::1} == "#" ]]; then
						val=${2//#/}
						if [[ ${#val} == 6 ]]; then fgc="\e[38;2;$((${hex}${val:0:2}));$((${hex}${val:2:2}));$((${hex}${val:4:2}))m"; shift
						elif [[ ${#val} == 2 ]]; then fgc="\e[38;2;$((${hex}${val:0:2}));$((${hex}${val:0:2}));$((${hex}${val:0:2}))m"; shift
						fi
					elif is_int "${@:2:3}"; then fgc="\e[38;2;$2;$3;$4m"; shift 3
					fi
					;;
				-bg|-background)	#? Set text background color, accepts either 6 digit hexadecimal "#RRGGBB", 2 digit hex (greyscale) or decimal RGB "<0-255> <0-255> <0-255>"
					if [[ ${2::1} == "#" ]]; then
						val=${2//#/}
						if [[ ${#val} == 6 ]]; then bgc="\e[48;2;$((${hex}${val:0:2}));$((${hex}${val:2:2}));$((${hex}${val:4:2}))m"; shift
						elif [[ ${#val} == 2 ]]; then bgc="\e[48;2;$((${hex}${val:0:2}));$((${hex}${val:0:2}));$((${hex}${val:0:2}))m"; shift
						fi
					elif is_int "${@:2:3}"; then bgc="\e[48;2;$2;$3;$4m"; shift 3
					fi
					;;
				-c|-center) center=1;;								#? Center text horizontally on screen
				-rs|-reset) effect="0${effect}${theme[main_bg]}";;				#? Reset text colors and effects
				-b|-bold) effect="${effect}${effect:+;}1"; bold=1;;				#? Enable bold text
				+b|+bold) effect="${effect}${effect:+;}21"; bold=0;;				#? Disable bold text
				-da|-dark) effect="${effect}${effect:+;}2";;					#? Enable dark text
				+da|+dark) effect="${effect}${effect:+;}22";;					#? Disable dark text
				-i|-italic) effect="${effect}${effect:+;}3"; italic=1;;				#? Enable italic text
				+i|+italic) effect="${effect}${effect:+;}23"; italic=0;;			#? Disable italic text
				-ul|-underline) effect="${effect}${effect:+;}4";;				#? Enable underlined text
				+ul|+underline) effect="${effect}${effect:+;}24";;				#? Disable underlined text
				-bl|-blink) effect="${effect}${effect:+;}5";;					#? Enable blinking text
				+bl|+blink) effect="${effect}${effect:+;}25";;					#? Disable blinking text
				-f|-font) if [[ $2 =~ ^(sans-serif|script|fraktur|monospace|double-struck)$ ]]; then custom_font="$2"; shift; fi;;			#? Set custom font
				-m|-move) add_command="${add_command}\e[${2};${3}f"; shift 2;;			#? Move to postion "LINE" "COLUMN"
				-l|-left) add_command="${add_command}\e[${2}D"; shift;;				#? Move left x columns
				-r|-right) add_command="${add_command}\e[${2}C"; shift;;			#? Move right x columns
				-u|-up) add_command="${add_command}\e[${2}A"; shift;;				#? Move up x lines
				-d|-down) add_command="${add_command}\e[${2}B"; shift;;				#? Move down x lines
				-jl|-justify-left) justify_left="${2}"; shift;;					#? Justify string left within given width
				-jr|-justify-right) justify_right="${2}"; shift;;				#? Justify string right within given width
				-jc|-justify-center) justify_center="${2}"; shift;;				#? Justify string center within given width
				-rp|-repeat) repeat=${2}; shift;;						#? Repeat next string x number of times
				-sc|-save) add_command="\e[s${add_command}";;					#? Save cursor position
				-rc|-restore) add_command="${add_command}\e[u";;				#? Restore cursor position
				-trans) trans=1;;								#? Make whitespace transparent
				-v|-variable) local -n var=$2; ext_var=1; shift;;				#? Send output to a variable, appending if not unset
				*) text="$1"; shift; break;;							#? Assumes text string if no argument is found
			esac
			shift
		done

		#* Repeat string if repeat is enabled
		if [[ -n $repeat ]]; then
			printf -v r_tmp "%${repeat}s" ""
			text="${r_tmp// /$text}"
		fi

		#* Set correct placement for screen centered text
		if ((center==1 & ${#text}>0 & ${#text}<tty_width-4)); then
			add_command="${add_command}\e[${tty_width}D\e[$(( (tty_width/2)-(${#text}/2) ))C"
		fi

		#* Convert text string to custom font if set and remove non working effects
		if [[ -n $custom_font ]]; then
			unset effect
			text=$(set_font "${custom_font}${bold:+" bold"}${italic:+" italic"}" "${text}")
		fi

		#* Set text justification if set
		if [[ -n $justify_left ]] && ((${#text}<justify_left)); then
			printf -v text "%s%$((justify_left-${#text}))s" "${text}" ""
		elif [[ -n $justify_right ]] && ((${#text}<justify_right)); then
			printf -v text "%$((justify_right-${#text}))s%s" "" "${text}"
		elif [[ -n $justify_center ]] && ((${#text}<justify_center)); then
			printf -v text "%$(( (justify_center/2)-(${#text}/2) ))s%s" "" "${text}"
			printf -v text "%s%-$((justify_center-${#text}))s" "${text}" ""
		fi

		if [[ -n $trans ]]; then
			text="${text// /'\e[1C'}"
		fi

		#* Create text string
		if [[ -n $effect ]]; then effect="\e[${effect}m"; fi
		out="${out}${add_command}${effect}${bgc}${fgc}${text}"
		unset add_command effect fgc bgc center justify_left justify_right justify_center custom_font text repeat trans justify
	done

	#* Print the string to stdout if variable out hasn't been set
	if [[ -z $ext_var ]]; then echo -en "$out"
	else var="${var}${out}"; fi

}
draw_banner() { #? Draw banner, usage: draw_banner <line> [output variable]
	local y letter b_color x_color xpos ypos=$1 banner_out
	if [[ -n $2 ]]; then local -n banner_out=$2; fi
	xpos=$(( (tty_width/2)-(banner_width/2) ))

	for banner_line in "${banner[@]}"; do
		print -v banner_out -rs -move $((ypos+++y)) $xpos -t "${banner_line}"
	done

	if [[ -z $2 ]]; then echo -en "${banner_out}"; fi
}
init() { #? Collect needed information and set options before startig main loop
	if [[ -z $1 ]]; then
		local i stx=0
		#* Set terminal options, save and clear screen
		saved_stty="$(${stty} -g)"
		echo -en "${alt_screen}${hide_cursor}${clear_screen}"
		echo -en "\033]0;${TERMINAL_TITLE} :=([RTS - Red Team Server)=:\a"
		${stty} -echo

		#* Wait for resize if terminal size is smaller then 80x24
		if (($tty_width<80 | $tty_height<24)); then resized; echo -en "${clear_screen}"; fi

		#* Draw banner to banner array
		local letter b_color banner_line y=0
		local -a banner_out
		#print -v banner_out[0] -t "\e[0m"
		for banner_line in "${banner[@]}"; do
			#* Read banner array letter by letter to set correct color for filled vs outline characters
			while read -rN1 letter; do
				if [[ $letter == "█" ]]; then b_color="${banner_colors[$y]}"
				else b_color="#$((80-y*6))"; fi
				if [[ $letter == " " ]]; then
					print -v banner_out[y] -r 1
				else
					print -v banner_out[y] -fg ${b_color} "${letter}"
				fi
			done <<<"$banner_line"
			((++y))
		done
		banner=("${banner_out[@]}")

		#* Draw banner to screen and show status while running init
		draw_banner $((tty_height/2-10))

fi
	#* Get theme and set colors
	#print -bg "#00" -fg "#30ff50" -r 1 -t "√"
	#print -m $(( (tty_height/2-3)+stx++ )) 0 -b -c "Generating colors for theme..."
	#color_init_
}
quit_() { #? Clean exit
	#* Restore terminal options and screen
	if [[ $use_psutil == true && $2 != "psutil" ]]; then
		py_command quit
		sleep 0.1
		rm -rf "${pytmpdir}"
	fi
	echo -en "${clear_screen}${normal_screen}${show_cursor}"
	${stty} "${saved_stty}"
	echo -en "\033]0;\a"

	if [[ $1 == "restart" ]]; then exec "$(${realpath} "$0")"; fi

	exit ${1:-0}
}
is_hex() { #? Check if value(s) is hexadecimal
	local param
	for param; do
		if [[ ! ${param//#/} =~ ^[0-9a-fA-F]*$ ]]; then return 1; fi
	done
}
spaces() { #? Prints back spaces, usage: spaces "number of spaces"
	printf "%${1}s" ""
}
is_int() { #? Check if value(s) is integer
	local param
	for param; do
		if [[ ! $param =~ ^[\-]?[0-9]+$ ]]; then return 1; fi
	done
}
is_float() { #? Check if value(s) is floating point
	local param
	for param; do
		if [[ ! $param =~ ^[\-]?[0-9]*[,.][0-9]+$ ]]; then return 1; fi
	done
}
color_init_() { #? Check for theme file and set colors
	local main_bg="" main_fg="#cc" title="#ee" hi_fg="#90" inactive_fg="#40" cpu_box="#3d7b46" mem_box="#8a882e" net_box="#423ba5" proc_box="#923535" proc_misc="#0de756" selected_bg="#7e2626" selected_fg="#ee"
	local temp_start="#4897d4" temp_mid="#5474e8" temp_end="#ff40b6" cpu_start="#50f095" cpu_mid="#f2e266" cpu_end="#fa1e1e" div_line="#30"
	local free_start="#223014" free_mid="#b5e685" free_end="#dcff85" cached_start="#0b1a29" cached_mid="#74e6fc" cached_end="#26c5ff" available_start="#292107" available_mid="#ffd77a" available_end="#ffb814"
	local used_start="#3b1f1c" used_mid="#d9626d" used_end="#ff4769" download_start="#231a63" download_mid="#4f43a3" download_end="#b0a9de" upload_start="#510554" upload_mid="#7d4180" upload_end="#dcafde"
	local hex2rgb color_name array_name this_color main_fg_dec sourced theme_unset
	local -i i y
	local -A rgb
	local -a dec_test
	local -a convert_color=("main_bg" "temp_start" "temp_mid" "temp_end" "cpu_start" "cpu_mid" "cpu_end" "upload_start" "upload_mid" "upload_end" "download_start" "download_mid" "download_end" "used_start" "used_mid" "used_end" "available_start" "available_mid" "available_end" "cached_start" "cached_mid" "cached_end" "free_start" "free_mid" "free_end" "proc_misc" "main_fg_dec")
	local -a set_color=("main_fg" "title" "hi_fg" "div_line" "inactive_fg" "selected_fg" "selected_bg" "cpu_box" "mem_box" "net_box" "proc_box")

	for theme_unset in ${!theme[@]}; do
		unset 'theme[${theme_unset}]'
	done

	#* Check if theme set in config exists and source it if it does
	if [[ -n ${color_theme} && ${color_theme} != "Default" && ${color_theme} =~ (themes/)|(user_themes/) && -e "${config_dir}/${color_theme%.theme}.theme" ]]; then
		# shellcheck source=/dev/null
		source "${config_dir}/${color_theme%.theme}.theme"
		sourced=1
	else
		color_theme="Default"
	fi

	main_fg_dec="${theme[main_fg]:-$main_fg}"
	theme[main_fg_dec]="${main_fg_dec}"

	#* Convert colors for graphs and meters from rgb hexadecimal to rgb decimal if needed
	for color_name in ${convert_color[@]}; do
		if [[ -n $sourced ]]; then hex2rgb="${theme[${color_name}]}"
		else hex2rgb="${!color_name}"; fi

		hex2rgb=${hex2rgb//#/}

		if [[ ${#hex2rgb} == 6 ]] && is_hex "$hex2rgb"; then hex2rgb="$((${hex}${hex2rgb:0:2})) $((${hex}${hex2rgb:2:2})) $((${hex}${hex2rgb:4:2}))"
		elif [[ ${#hex2rgb} == 2 ]] && is_hex "$hex2rgb"; then hex2rgb="$((${hex}${hex2rgb:0:2})) $((${hex}${hex2rgb:0:2})) $((${hex}${hex2rgb:0:2}))"
		else
			dec_test=(${hex2rgb})
			if [[ ${#dec_test[@]} -eq 3 ]] && is_int "${dec_test[@]}"; then hex2rgb="${dec_test[*]}"
			else unset hex2rgb; fi
		fi

		theme[${color_name}]="${hex2rgb}"
	done

	#* Set background color if set, otherwise use terminal default
	if [[ -n ${theme[main_bg]} ]]; then theme[main_bg_dec]="${theme[main_bg]}"; theme[main_bg]=";48;2;${theme[main_bg]// /;}"; fi

	#* Set colors from theme file if found and valid hexadecimal or integers, otherwise use default values
	for color_name in "${set_color[@]}"; do
		if [[ -z ${theme[$color_name]} ]] || ! is_hex "${theme[$color_name]}" && ! is_int "${theme[$color_name]}"; then theme[${color_name}]="${!color_name}"; fi
	done

	box[cpu_color]="${theme[cpu_box]}"
	box[mem_color]="${theme[mem_box]}"
	box[net_color]="${theme[net_box]}"
	box[processes_color]="${theme[proc_box]}"

	#* Create color arrays from one, two or three color gradient, 100 values in each
	for array_name in "temp" "cpu" "upload" "download" "used" "available" "cached" "free"; do
		local -n color_array="color_${array_name}_graph"
		local -a rgb_start=(${theme[${array_name}_start]}) rgb_mid=(${theme[${array_name}_mid]}) rgb_end=(${theme[${array_name}_end]})
		local pf_calc middle=1

		rgb[red]=${rgb_start[0]}; rgb[green]=${rgb_start[1]}; rgb[blue]=${rgb_start[2]}

		if [[ -z ${rgb_mid[*]} ]] && ((rgb_end[0]+rgb_end[1]+rgb_end[2]>rgb_start[0]+rgb_start[1]+rgb_start[2])); then
			rgb_mid=( $(( rgb_start[0]+( (rgb_end[0]-rgb_start[0])/2) )) $((rgb_start[1]+( (rgb_end[1]-rgb_start[1])/2) )) $((rgb_start[2]+( (rgb_end[2]-rgb_start[2])/2) )) )
		elif [[ -z ${rgb_mid[*]} ]]; then
			rgb_mid=( $(( rgb_end[0]+( (rgb_start[0]-rgb_end[0])/2) )) $(( rgb_end[1]+( (rgb_start[1]-rgb_end[1])/2) )) $(( rgb_end[2]+( (rgb_start[2]-rgb_end[2])/2) )) )
		fi

		for((i=0;i<=100;i++,y=0)); do

			if [[ -n ${rgb_end[*]} ]]; then
				for this_color in "red" "green" "blue"; do
					if ((i==50)); then rgb_start[y]=${rgb[$this_color]}; fi

					if ((middle==1 & rgb[$this_color]<rgb_mid[y])); then
						printf -v pf_calc "%.0f" "$(( i*( (rgb_mid[y]-rgb_start[y])*100/50*100) ))e-4"

					elif ((middle==1 & rgb[$this_color]>rgb_mid[y])); then
						printf -v pf_calc "%.0f" "-$(( i*( (rgb_start[y]-rgb_mid[y])*100/50*100) ))e-4"

					elif ((middle==0 & rgb[$this_color]<rgb_end[y])); then
						printf -v pf_calc "%.0f" "$(( (i-50)*( (rgb_end[y]-rgb_start[y])*100/50*100) ))e-4"

					elif ((middle==0 & rgb[$this_color]>rgb_end[y])); then
						printf -v pf_calc "%.0f" "-$(( (i-50)*( (rgb_start[y]-rgb_end[y])*100/50*100) ))e-4"

					else
						pf_calc=0
					fi

					rgb[$this_color]=$((rgb_start[y]+pf_calc))
					if ((rgb[$this_color]<0)); then rgb[$this_color]=0
					elif ((rgb[$this_color]>255)); then rgb[$this_color]=255; fi

					y+=1
					if ((i==49 & y==3 & middle==1)); then middle=0; fi
				done
			fi
			color_array[i]="${rgb[red]} ${rgb[green]} ${rgb[blue]}"
		done

	done

}

### THE CODE ABOVE THIS LINE IS COPYRIGHT Aristocratos (jakob@qvantnet.com) MODIFIED FOR THIS PROJECT "RTS" BY THE TERMS OF THE APACHE 2.0 LICENSE UNDER DERITIVE WORKS ######
# Regular Colors
black='\e[0;30m'        # Black
red='\e[0;31m'          # Red
green='\e[0;32m'        # Green
yellow='\e[0;33m'       # Yellow
blue='\e[0;34m'         # Blue
purple='\e[0;35m'       # Purple
cyan='\e[0;36m'         # Cyan
white='\e[0;37m'        # White

# Bold
bblack='\e[1;30m'       # Black
bred='\e[1;31m'         # Red
bgreen='\e[1;32m'       # Green
byellow='\e[1;33m'      # Yellow
bblue='\e[1;34m'        # Blue
bpurple='\e[1;35m'      # Purple
bcyan='\e[1;36m'        # Cyan
bwhite='\e[1;37m'       # White

# Underline
ublack='\e[4;30m'       # Black
ured='\e[4;31m'         # Red
ugreen='\e[4;32m'       # Green
uyellow='\e[4;33m'      # Yellow
ublue='\e[4;34m'        # Blue
upurple='\e[4;35m'      # Purple
ucyan='\e[4;36m'        # Cyan
uwhite='\e[4;37m'       # White


set -o pipefail

nextcloud_db_user=nextcloud
nextcloud_db_host=nextcloud-db
nextcloud_db_pass=rtspassw0rd
rts_password="rtspassw0rd"
gitea_db_host=gitea-db
gitea_db_type=postgres
gitea_db_user=gitea
gitea_db_pass=gitea
initial_working_dir="$(pwd)/setup"
initial_user=$(whoami)
install_path="/opt/rts"
log="/tmp/rts.log"
red="#ff0000"
green="#19e448"
grey="#b3b3b3"
auth_token=""
static_auth_token=""

declare -A packages=( [matrix server]=1 [matrix web]=1 [IVRE]=1 [gitea]=1 [nextcloud]=1 [cyberchef]=1 [portainer.io]=1 [pentest collab framework]=1 [hastebin]=1 [guacamole]=1 )
declare -A references=( [lolbas/gtfobins]=1 [hacktricks]=1 [payload all the things]=1 [cheatsheets]=1 [pentest standards]=1 [MITRE att&ck navigator]=0 [MITRE att&ck reference]=0 )
declare -A auxiliary=( [cobalt strike community kit]=1 [seclists]=1 [hatecrack]=1 [slowloris]=1 [ghostpack]=1 [veil]=1 [cobalt strike elevate kit]=1 [cobalt strike c2 profiles]=1 [cobalt strike arsenal]=1 )
declare -A c2frameworks=( [covenant]=1 [MITRE caldera]=0 [sliver]=1 [powershell empire/starkiller]=1 )

ip_address=$(ip route get 1 | awk '{print $(NF-2);exit}')

docker_compose_preamble="IyBQb3J0cyBNYXBwaW5nCiMgPS09LT0tPS09LT0tPS09LT0tPS09LT0tPS09LT0tPS0gCiMgMjIJIC0gbG9jYWwgc3NoCiMgODAJIC0gbmdpbngtcHJveHkKIyAyMjIJIC0gZ2l0ZWEgc3NoCiMgNDQzCSAtIGNvdmVuYW50CiMgMjAyMCAgIC0gcmVjb25tYXBkICh0aGlzIGFjdHVhbGx5IHJ1biBsb2NhbGx5IGJlY2F1c2Ugb2YgaXNzdWVzIHdpdGggZG9ja2VyLCBjaGVjayBydHMtc2V0dXAuc2gpCiMgMzMwNiAgIC0gcm1hcC1zcWwKIyA1MDAwCSAtIFBDRiAoUGVuZXRyYXRpb24gVGVzdGluZyBGcmFtZXdvcmspCiMgNTUxMAkgLSBybWFwLWFnZW50CiMgNjM3OQkgLSBybWFwLXJlZGlzCiMgNzQ0MwkgLSBjb3ZlbmFudAojIDgwODAJIC0gY292ZW5hbnQKIyA5MDAwCSAtIHRoZS1oaXZlNCBkaXNhYmxlZAojIDkwMDEJIC0gY29ydGV4IChwYXJ0IG9mIHRoZSBoaXZlKSBkaXNhYmxlZAojIDkwMDAJIC0gcG9ydGFpbmVyCiMgODg4OCAgIC0gY2FsZGVyYQojIDg0NDMgICAtIGNhbGRlcmEKIyA3MDEwICAgLSBjYWxkZXJhICAgIAojIDcwMTEgICAtIGNhbGRlcmEKIyA3MDEyICAgLSBjYWxkZXJhCiMgODg1MyAgIC0gY2FsZGVyYQojIDgwMjIgICAtIGNhbGRlcmEKIyAyMjIyICAgLSBjYWxkZXJhCiMgNTQzMiAgIC0gbWV0YXNwbG9pdCAvIHBvc3RncmVxbCBpbnRlZ3JhdGlvbgoKCnZlcnNpb246ICczJwoKdm9sdW1lczoKICBuZXh0Y2xvdWQ6CiAgbmV4dGNsb3VkX2RiOgogIHN5bmFwc2UtZGF0YToKICBwb3N0Z3Jlcy1kYXRhOgoKc2VydmljZXM6CiMjIyMgV2Vic2l0ZSAjIyMjCiAgcnRzLXdlYjoKICAgIGNvbnRhaW5lcl9uYW1lOiBydHMtd2ViCiAgICBpbWFnZTogdHJhZmV4L3BocC1uZ2lueAogICAgdm9sdW1lczoKICAgICAtIC4vd2Vic2l0ZTovdmFyL3d3dy9odG1sOnJvCiAgICAgLSAvdmFyL3J1bi9kb2NrZXIuc29jazovdmFyL3J1bi9kb2NrZXIuc29jawogICAgI2NvbW1hbmQ6IHNoIC1jICdhcGsgYWRkIGJhc2ggJiYgYXBrIGFkZCBkb2NrZXInCiAgICBwb3J0czoKICAgICAgLSA4MDgwCiAgICBlbnZpcm9ubWVudDoKICAgICAgLSBWSVJUVUFMX0hPU1Q9d3d3LnJ0cy5sYW4KICAgICAgLSBWSVJUVUFMX1BPUlQ9ODA4MAo="
docker_compose_nginx_proxy="IyMjIyMgTkdJTlggUFJPWFkgIyMjIyMKICBuZ2lueC1wcm94eToKICAgIGltYWdlOiBuZ2lueHByb3h5L25naW54LXByb3h5CiAgICBjb250YWluZXJfbmFtZTogbmdpbngtcHJveHkKICAgIHBvcnRzOgogICAgICAtICI4MDo4MCIKICAgIHZvbHVtZXM6CiAgICAgIC0gL3Zhci9ydW4vZG9ja2VyLnNvY2s6L3RtcC9kb2NrZXIuc29jazpybwo="
docker_compose_nextcloud="IyMjIyMgTkVYVENMT1VEICMjIyMjCiAgbmV4dGNsb3VkX2RiOiAjIyMjIyMjbmV4dGNsb3VkX2RiIGlzIHRoZSBzZXJ2ZXIgbmFtZSEhIQogICAgaW1hZ2U6IG1hcmlhZGIKICAgIGNvbnRhaW5lcl9uYW1lOiBuZXh0Y2xvdWRfZGIKICAgIGNvbW1hbmQ6IC0tdHJhbnNhY3Rpb24taXNvbGF0aW9uPVJFQUQtQ09NTUlUVEVEIC0tYmlubG9nLWZvcm1hdD1ST1cgLS1pbm5vZGItZmlsZS1wZXItdGFibGU9MSAtLXNraXAtaW5ub2RiLXJlYWQtb25seS1jb21wcmVzc2VkCiAgICByZXN0YXJ0OiBhbHdheXMKICAgIHZvbHVtZXM6CiAgICAgIC0gbmV4dGNsb3VkX2RiOi92YXIvbGliL215c3FsCiAgICBlbnZpcm9ubWVudDoKICAgICAgLSBNWVNRTF9ST09UX1BBU1NXT1JEPXJ0c19wYXNzdzByZAogICAgICAtIE1ZU1FMX1BBU1NXT1JEPXJ0c19wYXNzdzByZAogICAgICAtIE1ZU1FMX0RBVEFCQVNFPW5leHRjbG91ZAogICAgICAtIE1ZU1FMX1VTRVI9bmV4dGNsb3VkCiAgbmV4dGNsb3VkX2FwcDoKICAgIGltYWdlOiBuZXh0Y2xvdWQKICAgIGNvbnRhaW5lcl9uYW1lOiBuZXh0Y2xvdWRfYXBwCiAgICBsaW5rczoKICAgICAgLSBuZXh0Y2xvdWRfZGIKICAgIHZvbHVtZXM6CiAgICAgIC0gbmV4dGNsb3VkOi92YXIvd3d3L2h0bWwKICAgICAgLSAuL3JlZC1zaGFyZTovcmVkLXNoYXJlICN0aGlzIGlzIGFuIGlzc3VlIGJlY2F1c2UgSSBhc2sgdGhlIHVzZXIgd2hlcmUgdGhleSB3YW50IHRvIGluc3RhbGwgYW5kIGJyZWFrIHNvbWUgc2hpdC4gTmVlZCB0byBmaXggdGhpcy4gUHJvYmFibHkgbWFrZSBhIGxvY2FsIGRpcmVjdG9yeSBhbmQgY29weSB0byBwcm9wZXIgbG9jYXRpb24KICAgIHJlc3RhcnQ6IGFsd2F5cwogICAgZW52aXJvbm1lbnQ6CiAgICAgIC0gVklSVFVBTF9IT1NUPW5leHRjbG91ZC5ydHMubGFuCg=="
docker_compose_matrix_chat="IyMjIyMjIyBTWU5BUFNFIE1BVFJJWCBDSEFUICMjIyMjIyMjIyMjCiAgc3luYXBzZToKICAgIGNvbnRhaW5lcl9uYW1lOiBzeW5hcHNlCiAgICBob3N0bmFtZTogbWF0cml4LnJ0cy5sYW4KICAgIGltYWdlOiBkb2NrZXIuaW8vbWF0cml4ZG90b3JnL3N5bmFwc2U6bGF0ZXN0CiAgICByZXN0YXJ0OiB1bmxlc3Mtc3RvcHBlZAogICAgZW52aXJvbm1lbnQ6CiAgICAgIC0gU1lOQVBTRV9TRVJWRVJfTkFNRT1tYXRyaXgucnRzLmxhbgogICAgICAtIFNZTkFQU0VfUkVQT1JUX1NUQVRTPXllcwogICAgICAtIFNZTkFQU0VfTk9fVExTPTEKICAgICAgLSBTWU5BUFNFX1JFR0lTVFJBVElPTl9TSEFSRURfU0VDUkVUPTEyMzQ1NgogICAgICAtIFBPU1RHUkVTX0RCPXN5bmFwc2UKICAgICAgLSBQT1NUR1JFU19IT1NUPXN5bmFwc2UtZGIKICAgICAgLSBQT1NUR1JFU19VU0VSPXN5bmFwc2UKICAgICAgLSBQT1NUR1JFU19QQVNTV09SRD1zeW5hcHNlX3Bhc3N3MHJkCiAgICAgIC0gVklSVFVBTF9IT1NUPW1hdHJpeC5ydHMubGFuCiAgICAgIC0gVklSVFVBTF9QT1JUPTgwMDgKICAgIHZvbHVtZXM6CiAgICAgIC0gc3luYXBzZS1kYXRhOi9kYXRhCiAgICAgIC0gIi4vaG9tZXNlcnZlci55YW1sOi9kYXRhL2hvbWVzZXJ2ZXIueWFtbCIKICAgIGRlcGVuZHNfb246CiAgICAgIC0gc3luYXBzZS1kYgogICAgZXhwb3NlOgogICAgICAtIDgwMDgKICBzeW5hcHNlLWRiOgogICAgY29udGFpbmVyX25hbWU6IHN5bmFwc2UtZGIKICAgIGltYWdlOiBkb2NrZXIuaW8vcG9zdGdyZXM6MTAtYWxwaW5lCiAgICBlbnZpcm9ubWVudDoKICAgICAgLSBQT1NUR1JFU19EQj1zeW5hcHNlCiAgICAgIC0gUE9TVEdSRVNfVVNFUj1zeW5hcHNlCiAgICAgIC0gUE9TVEdSRVNfUEFTU1dPUkQ9c3luYXBzZV9wYXNzdzByZAogICAgdm9sdW1lczoKICAgICAgLSBwb3N0Z3Jlcy1kYXRhOi92YXIvbGliL3Bvc3RncmVzcWwvZGF0YQo="
docker_compose_gitea="IyMjIyBHSVRFQSAjIyMjIwogIGdpdGVhLXNlcnZlcjoKICAgIGltYWdlOiBnaXRlYS9naXRlYTpsYXRlc3QKICAgIGNvbnRhaW5lcl9uYW1lOiBnaXRlYS1zZXJ2ZXIKICAgIGVudmlyb25tZW50OgogICAgICAtIFVTRVJfVUlEPTEwMDAKICAgICAgLSBVU0VSX0dJRD0xMDAwCiAgICAgIC0gREJfVFlQRT1wb3N0Z3JlcwogICAgICAtIERCX0hPU1Q9Z2l0ZWEtZGI6NTQzMgogICAgICAtIERCX05BTUU9Z2l0ZWEKICAgICAgLSBEQl9VU0VSPWdpdGVhCiAgICAgIC0gREJfUEFTU1dEPWdpdGVhCiAgICAgIC0gVklSVFVBTF9IT1NUPWdpdGVhLnJ0cy5sYW4KICAgICAgLSBWSVJUVUFMX1BPUlQ9MzAwMAogICAgcmVzdGFydDogYWx3YXlzCiAgICB2b2x1bWVzOgogICAgICAtIC4vZ2l0ZWEvZ2l0ZWE6L2RhdGEKICAgICAgLSAvZXRjL3RpbWV6b25lOi9ldGMvdGltZXpvbmU6cm8KICAgICAgLSAvZXRjL2xvY2FsdGltZTovZXRjL2xvY2FsdGltZTpybwogICAgcG9ydHM6CiAgICAgIC0gIjIyMjoyMiIKICAgIGV4cG9zZToKICAgICAgLSAzMDAwCiAgICBkZXBlbmRzX29uOgogICAgICAtIGdpdGVhLWRiCiAgZ2l0ZWEtZGI6CiAgICBpbWFnZTogcG9zdGdyZXM6OS42CiAgICBjb250YWluZXJfbmFtZTogZ2l0ZWEtZGIKICAgIHJlc3RhcnQ6IGFsd2F5cwogICAgZW52aXJvbm1lbnQ6CiAgICAgIC0gUE9TVEdSRVNfVVNFUj1naXRlYQogICAgICAtIFBPU1RHUkVTX1BBU1NXT1JEPWdpdGVhCiAgICAgIC0gUE9TVEdSRVNfREI9Z2l0ZWEKICAgIHZvbHVtZXM6CiAgICAgIC0gLi9naXRlYS9wb3N0Z3JlczovdmFyL2xpYi9wb3N0Z3Jlc3FsL2RhdGEK"
docker_compose_ivre="IyMjIyMgSVZSRSAjIyMjIyMKICBpdnJlZGI6CiAgICBpbWFnZTogaXZyZS9kYgogICAgY29udGFpbmVyX25hbWU6IGl2cmVkYgogICAgdm9sdW1lczoKICAgICAgLSAuL2l2cmUvdmFyX2xpYl9tb25nb2RiOi92YXIvbGliL21vbmdvZGIKICAgICAgLSAuL2l2cmUvdmFyX2xvZ19tb25nb2RiOi92YXIvbG9nL21vbmdvZGIKICAgIHJlc3RhcnQ6IGFsd2F5cwogIGl2cmV3ZWI6CiAgICBpbWFnZTogaXZyZS93ZWIKICAgIGNvbnRhaW5lcl9uYW1lOiBpdnJld2ViCiAgICByZXN0YXJ0OiBhbHdheXMKICAgIGVudmlyb25tZW50OgogICAgICAtIFZJUlRVQUxfSE9TVD1pdnJlLnJ0cy5sYW4KICAgIGV4cG9zZToKICAgICAgLSA4MAogICAgZGVwZW5kc19vbjoKICAgICAgLSBpdnJlZGIKICBpdnJlY2xpZW50OgogICAgaW1hZ2U6IGl2cmUvY2xpZW50CiAgICBjb250YWluZXJfbmFtZTogaXZyZWNsaWVudAogICAgY29tbWFuZDogdGFpbCAtRiBhbnl0aGluZwogICAgdm9sdW1lczoKICAgICAgLSAuL3JlZC1zaGFyZTovcmVkLXNoYXJlICAKICAgIGRlcGVuZHNfb246CiAgICAgIC0gaXZyZWRiCiAgaXZyZWFnZW50OgogICAgaW1hZ2U6IGl2cmUvYWdlbnQKICAgIGNvbnRhaW5lcl9uYW1lOiBpdnJlYWdlbnQKICAgIHJlc3RhcnQ6IGFsd2F5cwogICAgZGVwZW5kc19vbjoKICAgICAgLSBpdnJlZGIK"
docker_compose_hastebin="IyMjIyMgSEFTVEVCSU4gIyMjIyMKICBoYXN0ZWJpbndlYjoKICAgIGNvbnRhaW5lcl9uYW1lOiBoYXN0ZWJpbndlYgogICAgYnVpbGQ6IC4vaGFzdGViaW4vLgogICAgZXhwb3NlOgogICAgICAtIDc3NzcKICAgIHJlc3RhcnQ6IGFsd2F5cwogICAgdm9sdW1lczoKICAgICAgLSAuL2hhc3RlYmluL2RhdGE6L29wdC9oYXN0ZS9kYXRhCiAgICBlbnZpcm9ubWVudDoKICAgICAgLSBWSVJUVUFMX0hPU1Q9aGFzdGViaW4ucnRzLmxhbgo="
docker_compose_caldera="IyMjIyMgTUlUUkUgQ0FMREVSQSAjIyMjIyMKICBjYWxkZXJhOgogICAgYnVpbGQ6CiAgICAgIGNvbnRleHQ6IC4vY2FsZGVyYS8KICAgICAgZG9ja2VyZmlsZTogRG9ja2VyZmlsZQogICAgICBhcmdzOgogICAgICAgIFRaOiAiVVRDIiAjVFogc2V0cyB0aW1lem9uZSBmb3IgdWJ1bnR1IHNldHVwCiAgICAgICAgV0lOX0JVSUxEOiAidHJ1ZSIgI1dJTl9CVUlMRCBpcyB1c2VkIHRvIGVuYWJsZSB3aW5kb3dzIGJ1aWxkIGluIHNhbmRjYXQgcGx1Z2luCiAgICBpbWFnZTogY2FsZGVyYTpsYXRlc3QKICAgIHBvcnRzOgogICAgICAtICI4ODg4Ojg4ODgiCiAgICAgIC0gIjg0NDM6ODQ0MyIKICAgICAgLSAiNzAxMDo3MDEwIgogICAgICAtICI3MDExOjcwMTEvdWRwIgogICAgICAtICI3MDEyOjcwMTIiCiAgICAgIC0gIjg4NTM6ODg1MyIKICAgICAgLSAiODAyMjo4MDIyIgogICAgICAtICIyMjIyOjIyMjIiCiAgICB2b2x1bWVzOgogICAgICAtIC4vY2FsZGVyYTovdXNyL3NyYy9hcHAKICAgIGNvbW1hbmQ6IC0taW5zZWN1cmUgLS1sb2cgREVCVUcKICAgIGVudmlyb25tZW50OgogICAgICAtIFZJUlRVQUxfSE9TVD1jYWxkZXJhLnJ0cy5sYW4KICAgICAgLSBWSVJUVUFMX1BPUlQ9ODg4OAo="
docker_compose_element="IyMjIyBFTEVNRU5UIFdFQiBDSEFUIENMSUVOVCBGT1IgTUFUUklYICMjIyMKICBlbGVtZW50LXdlYjoKICAgIGNvbnRhaW5lcl9uYW1lOiBlbGVtZW50LXdlYgogICAgaW1hZ2U6IGdoY3IuaW8vYnVidW50dXgvZWxlbWVudC13ZWIKICAgIGV4cG9zZToKICAgICAgLSA4MAogICAgZW52aXJvbm1lbnQ6CiAgICAgIC0gVklSVFVBTF9IT1NUPWVsZW1lbnQucnRzLmxhbgo="
docker_compose_wetty="IyMjIyMgd2V0dHkgLSB0ZXJtaW5hbCBiYXNlZCBzc2ggIyMjIyMgIAogIHdldHR5OgogICAgZXhwb3NlOgogICAgICAtIDgwCiAgICBpbWFnZTogd2V0dHlvc3Mvd2V0dHkKICAgIGNvbW1hbmQ6IC0tc3NoLWhvc3Q9IiR7cnRzX2lwX2FkZHJlc3N9IiAtLXNzaC11c2VyPXJ0cwogICAgZW52aXJvbm1lbnQ6CiAgICAgIC0gVklSVFVBTF9IT1NUPXNzaC5ydHMubGFuCiAgICAgIC0gVklSVFVBTF9QT1JUPTMwMDAK"
docker_compose_covenant="IyMjIyMgQ09WRU5BTlQgQzIgIyMjIyMjIyMjIyAtIGNvbmZpZ3VyZWQgZm9yIGh0dHBzIG9uIHBvcnQgNzQ0Mywgbm90IHByb3hpZWQsIGh0dHAgbGlzdGVuZXJzIHRvIDgwLCBodHR0cHMgbGlzdGVuZXJzIHRvIDQ0MwogIGNvdmVuYW50OgogICAgYnVpbGQ6IC4vY292ZW5hbnQvLgogICAgY29udGFpbmVyX25hbWU6IGNvdmVuYW50CiAgICBlbnZpcm9ubWVudDoKICAgICAgLSBUWj1QYWNpZmljL0xvc19BbmdlbGVzCiAgICBwb3J0czoKICAgICAgLSA3NDQzOjc0NDMKICAgICAgLSA0NDM6NDQzCiAgICAgIC0gODA4MDo4MAogICAgcmVzdGFydDogdW5sZXNzLXN0b3BwZWQK"
docker_compose_portainer="ICBwb3J0YWluZXI6CiAgICBpbWFnZTogcG9ydGFpbmVyL3BvcnRhaW5lci1jZTpsYXRlc3QKICAgIGNvbnRhaW5lcl9uYW1lOiBwb3J0YWluZXIKICAgIHJlc3RhcnQ6IHVubGVzcy1zdG9wcGVkCiAgICBzZWN1cml0eV9vcHQ6CiAgICAgIC0gbm8tbmV3LXByaXZpbGVnZXM6dHJ1ZQogICAgdm9sdW1lczoKICAgICAgLSAvZXRjL2xvY2FsdGltZTovZXRjL2xvY2FsdGltZTpybwogICAgICAtIC92YXIvcnVuL2RvY2tlci5zb2NrOi92YXIvcnVuL2RvY2tlci5zb2NrOnJvCiAgICAgIC0gLi9wb3J0YWluZXItZGF0YTovZGF0YQogICAgcG9ydHM6CiAgICAgIC0gOTAwMDo5MDAwCiAgICBlbnZpcm9ubWVudDoKICAgICAgLSBWSVJUVUFMX0hPU1Q9cG9ydGFpbmVyLnJ0cy5sYW4KICAgICAgLSBWSVJUVUFMX1BPUlQ9OTAwMAo="
docker_compose_pcf="ICBwY2Y6CiAgICAgYnVpbGQ6IC4vcGNmLy4KICAgICBjb250YWluZXJfbmFtZTogcGNmCiAgICAgcG9ydHM6CiAgICAgICAtIDUwMDA6NTAwMAogICAgIHZvbHVtZXM6CiAgICAgICAtIC4vcGNmOi9wY2YKICAgICBlbnZpcm9ubWVudDoKICAgICAgIC0gVklSVFVBTF9IT1NUPXBjZi5ydHMubGFuCg=="
docker_compose_attacknav="ICBhdHRhY2stbmF2LW5vZGU6CiAgICBjb250YWluZXJfbmFtZTogYXR0YWNrLW5hdi1ub2RlCiAgICBidWlsZDoKICAgICAgY29udGV4dDogLi9hdHRhY2stbmF2aWdhdG9yCiAgICAgIGRvY2tlcmZpbGU6IERvY2tlcmZpbGUKICAgIHBvcnRzOgogICAgICAtIDQyMDAKICAgIGVudmlyb25tZW50OgogICAgICAtIFZJUlRVQUxfSE9TVD1hdHRhY2stbmF2LnJ0cy5sYW4KICAgICAgLSBWSVJUVUFMX1BPUlQ9NDIwMAo="
docker_compose_attackweb="ICBhdHRhY2std2ViOgogICAgY29udGFpbmVyX25hbWU6IGF0dGFjay13ZWIKICAgIGJ1aWxkOiAuL2F0dGFjay13ZWJzaXRlCiAgICBleHBvc2U6CiAgICAgIC0gODAKICAgIGVudmlyb25tZW50OgogICAgICAtIFZJUlRVQUxfSE9TVD1hdHRhY2sucnRzLmxhbgo="
docker_compose_cyberchef="ICBjeWJlcmNoZWY6CiAgICBpbWFnZTogbXBlcHBpbmcvY3liZXJjaGVmOmxhdGVzdAogICAgY29udGFpbmVyX25hbWU6IGN5YmVyY2hlZgogICAgcG9ydHM6CiAgICAgIC0gODAwMAogICAgZW52aXJvbm1lbnQ6CiAgICAgIC0gVklSVFVBTF9IT1NUPWN5YmVyY2hlZi5ydHMubGFuCiAgICAgIC0gVklSVFVBTF9QT1JUPTgwMDAK"
docker_compose_lolbas="ICBsb2xiYXM6CiAgICBidWlsZDoKICAgICAgY29udGV4dDogLi9sb2xiYXMKICAgICAgZG9ja2VyZmlsZTogbG9sYmFzLURvY2tlcmZpbGUKICAgIHBvcnRzOgogICAgICAtICcxMDA1MDoxMDA1MCcKICAgICAgLSAnMTAwNjA6MTAwNjAnCiAgICBjb21tYW5kOiA+CiAgICAgIC9iaW4vc2ggLWMgJ2NkIC9vcHQvTE9MQkFTICYmCiAgICAgICggYnVuZGxlIGV4ZWMgamVreWxsIHNlcnZlIC0taG9zdCAwLjAuMC4wIC1QIDEwMDUwICYpICYmCiAgICAgIGNkIC9vcHQvZ3Rmb2JpbnMgJiYKICAgICAgYnVuZGxlIGV4ZWMgamVreWxsIHNlcnZlIC0taG9zdCAwLjAuMC4wIC1QIDEwMDYwJwo="
# Cobalt Strike Community kit has its own setup script, which we'll need to replicate for our local gitea instance. Best way is probably to download the tracked_repos.txt from gitea, and then use a for loop to clone those bad boys. Thing is, they are tracked...
# so mirroring is good to keep the list up to date, but how to pull the rest of the repos? something to ponder later, I guess.
# So after some thought, ask the user if he wants to download the community kit, and if so clone all of them locally using the script. A simple clone from Internet -> execute script -> done.
# If a team needs them, they can just scp or copy them from RTS to whatever host they need. To be honest, if Im going to use CS Im going to the team server on RTS anyways.
# then you can write a script to copy all the contents out of the cloned directories into one final folder containing all the scripts.

# Or better yet, if you want to mirror them all in gitea:
# pull the community kit file down: community_kit_projects="https://raw.githubusercontent.com/Cobalt-Strike/community_kit/main/tracked_repos.txt"
# then do a similar for loop in the setup script to iterate through the these with the above curl commands, mirroring all of them. That way the team can just clone them. Make sure to ask the user if they are ok with that, as it is a lot of them. 
#nuclei=$(go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest)

# simple spinner
spin[0]="-"
spin[1]="\\"
spin[2]="|"
spin[3]="/"

#echo regular
es() {
	echo -e "${bcyan}[*] $1${nocolor}" | elog
}
print_line() {
	# print a nice line
	print -rp 30 "─"
	print "\n"
}
#echo errors
ee() {
	echo -e "${bred}[!!!] $1${nocolor}" | elog
}
#echo warnings
ew() {
	echo -e "${byellow}[***] $1${nocolor}" | elog
}
#echo completed
ec() {
	echo -e "${bgreen}[**] $1${nocolor}" | elog
}
check_exit_code() {
	if [ $1 -eq 0 ]; then
		ec "$2 install successful."
		sleep 2
	else
		ee "$2 install failed, exiting. Check your internet connectivity or github access"
		exit
	fi
}
rawurlencode() {
	local string="${1}"
	local strlen=${#string}
	local encoded=""
	local pos c o
	for (( pos=0 ; pos<strlen ; pos++ )); do
    	c=${string:$pos:1}
    		case "$c" in
        		[-_.~a-zA-Z0-9] ) o="${c}" ;;
        		* )     printf -v o '%%%02x' "'$c"
     		esac
     	encoded+="${o}"
	done
	echo "${encoded}"    # You can either set a return variable (FASTER)
	REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}
check_installed() {
	# check to see if an application is installed, and if not, install it.
	es "checking if '${1}' is installed"
	dpkg -s $1 2>&1 | slog
	if [ $? -eq 0 ]; then
    	ec "${1} is installed."
	else
    	ew "${1} is not installed, installing from repo."
    	apt install ${1} -y 2>&1 | slog
    	# Verify package is now installe
    	dpkg -s ${1} 2>&1 | slog
    		if [ $? -ne 0 ]; then
       			ee "{1} installation failed, check logs. Exiting."
        		exit 1
    		fi
	fi
	sleep 1.5
	clear_menu "2"
}
add_hosts() {
	if grep -qF "${ip_address} ${1}" /etc/hosts; then
  		ec "${1} found."
	else
  		ew "adding in ${1} with ip ${ip_address} into /etc/hosts"
  	echo "${ip_address} ${1}" >> /etc/hosts
	fi
}
slog() {
	# silent log
	tee -a $log > /dev/null 2>&1
}
elog() {
	#echo log
	tee -a $log
}
clear_menu() {
  print -u $1
  for i in $(seq 1 $1)
    do
		echo '                                                                              '
		#echo
	done
  print -u $1
}
main_menu() {
  print "[1] Select Packages\n"
  print "[2] Select References\n"
  print "[3] Select Auxiliary Modules\n"
  print "[4] Select C2 Frameworks\n"
  print "[5] List Packages\n"
  print "[6] Change Install Location ($install_path)\n"
  print "[7] Set Password ($rts_password)\n"
  print "[8] Install\n"
  print "[x] Exit\n"
  read -p "rts (main) > " a
    case $a in
      "1") clear_menu "10"; select_packages "${!packages[@]}";;
      "2") clear_menu "10"; select_references ;;
      "3") clear_menu "10"; select_aux ;;
	  "4") clear_menu "10"; select_c2_frameworks ;;
      "5") clear_menu "10"; list_packages ;;
      "7") clear_menu "10"; install_location ;;
      "7") clear_menu "10"; set_passwords ;;
      "8") clear_menu "10"; install ;;
      "x") quit_ ;;
        *) echo -e "[*] Use the menu."; sleep 5; clear_menu "10"; main_menu;;
    esac
}
author() {
  print -fg "$red" -c "Author: James Allphin\n"
  print -c "Adversarial Cyber Team\n"
  print -c "NIWC Pacific San Diego, CA\n"
  print -c "\n"
  print -c "Version: 3.0"
  print -c "\n\n\n"
  print -c -fg "$grey"
  print -c "\n"
  print -c "  Red Team Server Setup Script\n"
  print -c -rp 30 "─"
  print -c "\n"
}
disabled_item() {
  print -fg "$grey" "["
  print -fg "$red" "*"
  print -fg "$grey" "] "
}
enabled_item() {
  print -fg "$grey" "["
  print -fg "$green" "*"
  print -fg "$grey" "] "
}
list_packages() { 
  print "Listing All Packages\n"
  disabled_item
  print -fg "$grey" "= Disabled "
  enabled_item
  print -fg "$grey" "= Enabled\n"
  print_line
  for key in "${!packages[@]}"
    do
      if [[ ${packages[$key]} -ne 1 ]]; then
        disabled_item
	print  "$key\n"
      else
        enabled_item
        print  "$key\n"
      fi
    done
  print -fg "$grey"
  print_line
    for key in "${!references[@]}"
    do
      if [[ ${references[$key]} -ne 1 ]]; then
        disabled_item
	print  "$key\n"
      else
        enabled_item
        print  "$key\n"
      fi
    done
  print -fg "$grey"
  print_line
    for key in "${!auxiliary[@]}"
    do
      if [[ ${auxiliary[$key]} -ne 1 ]]; then
        disabled_item
	print  "$key\n"
      else
        enabled_item
        print  "$key\n"
      fi
    done
  print -fg "$grey"
  print_line
  read -p "Press enter to continue"
  clear_menu "35"
  main_menu
}
select_packages() {
  local array_index=()
  KEYS=("${!packages[@]}")
  # List the initial set of packages that can be enabled/disabled
  disabled_item
  print -fg "$grey" "= Disabled "
  enabled_item
  print -fg "$grey" "= Enabled\n"
  print_line
  # Neat trick to display stars along with itemized list of software array, and we track the list by putting them into another standard
  # array_index that we can track and update accordingly.
  # I'm not sure how it actually works.
  for (( i=o; $i < ${#packages[@]}; i+=1 ))
    do
      KEY=${KEYS[$i]}
        if [[ ${packages[$KEY]} -ne 1 ]]; then
          print "$i) "
          disabled_item
          print  "$KEY\n"
        else
          print "$i) "
          enabled_item
          print  "$KEY\n"
        fi
      array_index+=("$KEY")
    done
  print "x) Back to main\n"
  read -p "rts (main\select) > " select_choice
  ## Case statement that checks to see if the software package is enabled/disabled and if so, flips the toggle.
  case $select_choice in
    "0")	
        choice=${array_index[0]}
		if [[ ${packages[$choice]} -ne 0 ]]; then packages[$choice]=0; else packages[$choice]=1; fi;;
    "1")
		choice=${array_index[1]}
        if [[ ${packages[$choice]} -ne 0 ]]; then packages[$choice]=0; else packages[$choice]=1; fi;;
    "2")
		choice=${array_index[2]}
        if [[ ${packages[$choice]} -ne 0 ]]; then packages[$choice]=0; else packages[$choice]=1; fi;;
    "3")
		choice=${array_index[3]}
        if [[ ${packages[$choice]} -ne 0 ]]; then packages[$choice]=0; else packages[$choice]=1; fi;;
    "4")
		choice=${array_index[4]}
        if [[ ${packages[$choice]} -ne 0 ]]; then packages[$choice]=0; else packages[$choice]=1; fi;;
    "5")
		choice=${array_index[5]}
        if [[ ${packages[$choice]} -ne 0 ]]; then packages[$choice]=0; else packages[$choice]=1; fi;;
    "6")
		choice=${array_index[6]}
        if [[ ${packages[$choice]} -ne 0 ]]; then packages[$choice]=0; else packages[$choice]=1; fi;;
    "7")
		choice=${array_index[7]}
        if [[ ${packages[$choice]} -ne 0 ]]; then packages[$choice]=0; else packages[$choice]=1; fi;;
    "8")
		choice=${array_index[8]}
        if [[ ${packages[$choice]} -ne 0 ]]; then packages[$choice]=0; else packages[$choice]=1; fi;;
    "9")
		choice=${array_index[9]}
        if [[ ${packages[$choice]} -ne 0 ]]; then packages[$choice]=0; else packages[$choice]=1; fi;;
    #"10")
	#	choice=${array_index[10]}
    #    if [[ ${packages[$choice]} -ne 0 ]]; then packages[$choice]=0; else packages[$choice]=1; fi;;
    "x")
		clear_menu "14"; main_menu ;;
    *)
		echo "[*] Use the menu."; sleep 5; clear_menu "15"; select_packages;;
  esac
  clear_menu "14"
  select_packages
}
select_references() {
  local array_index=()
  KEYS=("${!references[@]}")
  # List the initial set of packages that can be enabled/disabled
  disabled_item
  print -fg "$grey" "= Disabled "
  enabled_item
  print -fg "$grey" "= Enabled\n"
  print_line
  # Neat trick to display stars along with itemized list of software array, and we track the list by putting them into another standard
  # array_index that we can track and update accordingly.
  # I'm not sure how it actually works.
  for (( i=o; $i < ${#references[@]}; i+=1 ))
    do
      KEY=${KEYS[$i]}
        if [[ ${references[$KEY]} -ne 1 ]]; then
          print "$i) "
          disabled_item
          print  "$KEY\n"
        else
          print "$i) "
          enabled_item
          print  "$KEY\n"
        fi
      array_index+=("$KEY")
      #echo "index: $i, value: ${array_index[@]}"
    done
  print "x) Back to main\n"
  read -p "rts (main\ref) > " select_choice
  ## Case statement that checks to see if the software package is enabled/disabled and if so, flips the toggle.
  case $select_choice in
    "0")	
        choice=${array_index[0]}
		if [[ ${references[$choice]} -ne 0 ]]; then references[$choice]=0; else references[$choice]=1; fi ;;
    "1")
		choice=${array_index[1]}
        if [[ ${references[$choice]} -ne 0 ]]; then references[$choice]=0; else references[$choice]=1; fi ;;
    "2")
		choice=${array_index[2]}
        if [[ ${references[$choice]} -ne 0 ]]; then references[$choice]=0; else references[$choice]=1; fi ;;
    "3")
		choice=${array_index[3]}
        if [[ ${references[$choice]} -ne 0 ]]; then references[$choice]=0; else references[$choice]=1; fi ;;
    "4")
		choice=${array_index[4]}
        if [[ ${references[$choice]} -ne 0 ]]; then references[$choice]=0; else references[$choice]=1; fi ;;
    "5")
		choice=${array_index[5]}
        if [[ ${references[$choice]} -ne 0 ]]; then references[$choice]=0; else references[$choice]=1; fi ;;
    "6")
		choice=${array_index[6]}
        if [[ ${references[$choice]} -ne 0 ]]; then references[$choice]=0; else references[$choice]=1; fi ;;
	"7")
		choice=${array_index[7]}
		if [[ ${references[$choice]} -ne 0 ]]; then references[$choice]=0; else references[$choice]=1; fi ;;
    "x")
		clear_menu "11"; main_menu ;;
    *)
		echo "[*] Use the menu."; sleep 5; clear_menu "11"; select_references;;
  esac
  clear_menu "11"
  select_references
}
select_aux() {
  local array_index=()
  KEYS=("${!auxiliary[@]}")
  # List the initial set of packages that can be enabled/disabled
  disabled_item
  print -fg "$grey" "= Disabled "
  enabled_item
  print -fg "$grey" "= Enabled\n"
  print_line
  # Neat trick to display stars along with itemized list of software array, and we track the list by putting them into another standard
  # array_index that we can track and update accordingly.
  # I'm not sure how it actually works.
  for (( i=o; $i < ${#auxiliary[@]}; i+=1 ))
    do
      KEY=${KEYS[$i]}
        if [[ ${auxiliary[$KEY]} -ne 1 ]]; then
          print "$i) "
          disabled_item
          print  "$KEY\n"
        else
          print "$i) "
          enabled_item
          print  "$KEY\n"
        fi
      array_index+=("$KEY")
      #echo "index: $i, value: ${array_index[@]}"
    done
  print "x) Back to main\n"
  read -p "rts (main\aux) > " select_choice
  ## Case statement that checks to see if the software package is enabled/disabled and if so, flips the toggle.
  case $select_choice in
    "0")	
        choice=${array_index[0]}
		if [[ ${auxiliary[$choice]} -ne 0 ]]; then auxiliary[$choice]=0; else auxiliary[$choice]=1; fi ;;
    "1")
		choice=${array_index[1]}
        if [[ ${auxiliary[$choice]} -ne 0 ]]; then auxiliary[$choice]=0; else auxiliary[$choice]=1; fi ;;
    "2")
		choice=${array_index[2]}
        if [[ ${auxiliary[$choice]} -ne 0 ]]; then auxiliary[$choice]=0; else auxiliary[$choice]=1; fi ;;
    "3")
		choice=${array_index[3]}
        if [[ ${auxiliary[$choice]} -ne 0 ]]; then auxiliary[$choice]=0; else auxiliary[$choice]=1; fi ;;
    "4")
		choice=${array_index[4]}
        if [[ ${auxiliary[$choice]} -ne 0 ]]; then auxiliary[$choice]=0; else auxiliary[$choice]=1; fi ;;
    "5")
		choice=${array_index[5]}
        if [[ ${auxiliary[$choice]} -ne 0 ]]; then auxiliary[$choice]=0; else auxiliary[$choice]=1; fi ;;
    "6")
		choice=${array_index[6]}
        if [[ ${auxiliary[$choice]} -ne 0 ]]; then auxiliary[$choice]=0; else auxiliary[$choice]=1; fi ;;
	"7")
		choice=${array_index[7]}
        if [[ ${auxiliary[$choice]} -ne 0 ]]; then auxiliary[$choice]=0; else auxiliary[$choice]=1; fi ;;
    "8")
		choice=${array_index[8]}
        if [[ ${auxiliary[$choice]} -ne 0 ]]; then auxiliary[$choice]=0; else auxiliary[$choice]=1; fi ;;
    "x")
		clear_menu "13"; main_menu ;;
    *)
		echo "[*] Use the menu."; sleep 5; clear_menu "14"; select_aux;;
  esac
  clear_menu "13"
  select_aux
}
select_c2_frameworks() {
	  local array_index=()
  KEYS=("${!c2frameworks[@]}")
  # List the initial set of packages that can be enabled/disabled
  disabled_item
  print -fg "$grey" "= Disabled "
  enabled_item
  print -fg "$grey" "= Enabled\n"
  print_line
  # Neat trick to display stars along with itemized list of software array, and we track the list by putting them into another standard
  # array_index that we can track and update accordingly.
  # I'm not sure how it actually works.
  for (( i=o; $i < ${#c2frameworks[@]}; i+=1 ))
    do
      KEY=${KEYS[$i]}
        if [[ ${c2frameworks[$KEY]} -ne 1 ]]; then
          print "$i) "
          disabled_item
          print  "$KEY\n"
        else
          print "$i) "
          enabled_item
          print  "$KEY\n"
        fi
      array_index+=("$KEY")
    done
  print "x) Back to main\n"
  read -p "rts (main\c2) > " select_choice
  ## Case statement that checks to see if the software package is enabled/disabled and if so, flips the toggle.
  case $select_choice in
    "0")	
        choice=${array_index[0]}
		if [[ ${c2frameworks[$choice]} -ne 0 ]]; then c2frameworks[$choice]=0; else c2frameworks[$choice]=1; fi;;
    "1")
		choice=${array_index[1]}
        if [[ ${c2frameworks[$choice]} -ne 0 ]]; then c2frameworks[$choice]=0; else c2frameworks[$choice]=1; fi;;
    "2")
		choice=${array_index[2]}
        if [[ ${c2frameworks[$choice]} -ne 0 ]]; then c2frameworks[$choice]=0; else c2frameworks[$choice]=1; fi;;
    "3")
		choice=${array_index[3]}
        if [[ ${c2frameworks[$choice]} -ne 0 ]]; then c2frameworks[$choice]=0; else c2frameworks[$choice]=1; fi;;
    "x")
		clear_menu "8"; main_menu ;;
    *)
		echo "[*] Use the menu."; sleep 5; clear_menu "9"; select_packages;;
  esac
  clear_menu "8"
  select_c2_frameworks
}
install_location() {
  print "Install Location\n"    
  print_line
  print "Current Location $install_path\n"
  print_line
  read -p "rts (main\install) New Location? > " a
  if [ -z "$a" ]; then print "Cannot be blank."; clear_menu "5"; install_location; fi;
  install_path=$a
  read -p "Press enter to continue"
  clear_menu "6"
  main_menu
}
set_passwords() {
  print "Change RTS Password\n"    
  print_line
  print "This password will be used for:\n"
  print "ssh (as rts user)\n"
  print "nextcloud\n"
  print "gitea\n"
  print_line
  read -p "rts (main\password) New password? > " a
  if [ -z "$a" ]; then print "Cannot be blank."; clear_menu "8"; set_passwords; fi;
  rts_password=$a
  read -p "Press enter to continue"
  clear_menu "9"
  main_menu
}
install_package() {
	# this is our main install function 
	# check to make sure key isn't blank
	if [[ -z "$1" ]]; then print "Error"; return; fi ;
	# This is where the main install instructions go for each package enabled. This includes docker-compose echoing
	# any additional set up that must occur. I need to include logic to check to make sure gitea is enabled if any references are enabled, probably before we get here.
	# As we can't clone anything if gitea is not enabled. 
	# Also, need to add additional logic to make sure we get the gitea auth token. 
	# This is taken care of by how I call main -> aux -> ref order. gitea is installed as a main package, and the code checks to make sure gitea is included if any aux packages are selected.
	# so when we install gitea, we will grab the auth_token required to clone into gitea during aux package install. 
	# ----------------------
	# About dynamic webpage linkage
	# If I do it here, I can't control the order in which packages are linked to the webpage. This could result in non-standard link order. 
	# If I do it in a function, I might be able to control the order...depending on a couple factors. 
	# We silent log (slog) the builds, but do not silent log the pulls, so we can get status updates. Builds are too noisy. 
	case $1 in 
		"matrix server")
			es "installing matrix synapse server"
			sudo -u rts echo $docker_compose_matrix_chat | base64 -d >> ${install_path}/docker-compose.yml | slog
			sudo -u rts docker-compose -f ${install_path}/docker-compose.yml pull synapse synapse-db 2>&1
			sudo -u rts docker-compose -f ${install_path}/docker-compose.yml run --rm -e SYNAPSE_SERVER_NAME=matrix.rts.lan synapse generate 2>&1 | slog
			check_exit_code "$?" "matrix synapse server" | slog
			add_hosts "matrix.rts.lan"
			sleep 5
			clear_menu "4"
			;;
		"matrix web")
			es "installing matrix web client"
			sudo -u rts echo $docker_compose_element | base64 -d >> ${install_path}/docker-compose.yml | slog
			sudo -u rts docker-compose -f ${install_path}/docker-compose.yml pull element-web 2>&1
			sed -i '/<!-- mainsed -->/a <a href="http://element.rts.lan" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">matrix chat</a>' ${install_path}/website/index.html
			check_exit_code "$?" "matrix web client" | slog
			add_hosts "element.rts.lan"
			sleep 5
			clear_menu "3"
			;;
		"IVRE")
			es "installing IVRE"
			sudo -u rts echo $docker_compose_ivre | base64 -d >> ${install_path}/docker-compose.yml | slog
			sudo -u rts docker-compose -f ${install_path}/docker-compose.yml pull ivredb ivreweb ivreclient ivreagent 2>&1
			sed -i '/<!-- mainsed -->/a <a href="http://ivre.rts.lan" class="w3-button w3-bar-item w3-center" target="_blank" rel="noopener noreferrer">IVRE</a>' ${install_path}/website/index.html
			check_exit_code "$?" "IVRE" | slog
			add_hosts "ivre.rts.lan"
			sleep 5
			clear_menu "6"
			;;
		"covenant")
			es "installing covenant" 
			sudo -u rts echo $docker_compose_covenant | base64 -d >> ${install_path}/docker-compose.yml | slog
			sudo -u rts docker-compose -f ${install_path}/docker-compose.yml build covenant 2>&1 | slog
			sed -i '/<!-- mainsed -->/a <a href="https://rts.lan:7443" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">covenant</a>' ${install_path}/website/index.html
			check_exit_code "$?" "covenant" | slog
			add_hosts "covenant.rts.lan"
			sleep 5
			clear_menu "2"
			;;
		"gitea")
			es "installing gitea"
			sudo -u rts echo $docker_compose_gitea | base64 -d >> ${install_path}/docker-compose.yml | slog
			sudo -u rts docker-compose -f ${install_path}/docker-compose.yml pull gitea-server gitea-db 2>&1
			sed -i '/<!-- mainsed -->/a <a href="http://gitea.rts.lan" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">gitea</a>' ${install_path}/website/index.html
			check_exit_code "$?" "gitea" | slog
			add_hosts "gitea.rts.lan"
			sudo -u rts docker-compose -f ${install_path}/docker-compose.yml up -d gitea-db gitea-server 2>&1 | slog
			es "configuring gitea"
			sleep 30 # 30 seconds to initialize
			curl -s 'http://gitea.rts.lan/' \
  			-H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0' \
  			-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
  			-H 'Accept-Language: en-US,en;q=0.5' \
  			-H 'Connection: keep-alive' \
 			-H 'Cache-Control: max-age=0' \
 			-H 'Origin: null' \
  			-H 'Upgrade-Insecure-Requests: 1' \
  			-H 'DNT: 1' \
  			-H 'Content-Type: application/x-www-form-urlencoded' \
  			-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.55 Safari/537.36 Edg/96.0.1054.41' \
  			-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  			-H 'Accept-Language: en-US,en;q=0.9' \
  			-H 'Cookie: i_like_gitea=63542a430923887a; gitea_awesome=rts; gitea_incredible=5d08bd126b945c61dec7e1ec09bde03f8f0ac2865321719d63d04596fb91f8; lang=en-US; _csrf=KuOvKkDGWFXDe67yuX5yzfXXxPQ6MTY0OTAwMjY2NjA2MDAyNDc5MQ' \
  			--data-raw "db_type=postgres&db_host=gitea-db%3A5432&db_user=gitea&db_passwd=gitea&db_name=gitea&ssl_mode=disable&db_schema=&charset=utf8&db_path=%2Fdata%2Fgitea%2Fgitea.db&app_name=RTS+The+Red+Team+Server&repo_root_path=%2Fdata%2Fgit%2Frepositories&lfs_root_path=%2Fdata%2Fgit%2Flfs&run_user=git&domain=localhost&ssh_port=22&http_port=3000&app_url=http%3A%2F%2Fgitea.rts.lan&log_root_path=%2Fdata%2Fgitea%2Flog&smtp_host=&smtp_from=&smtp_user=&smtp_passwd=&enable_federated_avatar=on&enable_open_id_sign_in=on&enable_open_id_sign_up=on&default_allow_create_organization=on&default_enable_timetracking=on&no_reply_address=noreply.localhost&password_algorithm=pbkdf2&admin_name=rts&admin_passwd=$url_encoded_pass&admin_confirm_passwd=$url_encoded_pass&admin_email=root%40localhost" \
  			--compressed \
  			--insecure | slog
			if [ $? -eq 0 ]; then ec "gitea configured."; else ee "gitea configuration failed, please post an issue on the RTS github. exiting."; fi
			# if this is a reinstall, we need to delete the old token and get a new one. This is a just in case to make sure gitea works. 
			sleep 30 # 30 seconds to allow configuration above to kick in before we request user token. 
			delete_token=$(curl -s -X DELETE -H "Content-Type: application/json"  -k -d '{"name":"rts"}' -u rts:$url_encoded_pass http://gitea.rts.lan/api/v1/users/rts/tokens/rts > /dev/null)
			token_delete=$delete_token
			sleep 1
			auth_token=$(curl -s -X POST -H "Content-Type: application/json"  -k -d '{"name":"rts"}' -u rts:$url_encoded_pass http://gitea.rts.lan/api/v1/users/rts/tokens | jq -e '.sha1' | tr -d '"')
			static_auth_token=$auth_token
			sleep 1
			clear_menu "7"
			;;
		"nextcloud")
			es "installing nextcloud"
			sudo -u rts echo $docker_compose_nextcloud | base64 -d >> ${install_path}/docker-compose.yml | slog
			sudo -u rts docker-compose -f ${install_path}/docker-compose.yml pull nextcloud_db nextcloud_app 2>&1
			sed -i '/<!-- mainsed -->/a <a href="http://nextcloud.rts.lan" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">nextcloud</a>' ${install_path}/website/index.html
			check_exit_code "$?" "nextcloud" | slog
			add_hosts "nextcloud.rts.lan"
			sudo -u rts docker-compose -f ${install_path}/docker-compose.yml up -d nextcloud_db nextcloud_app 2>&1 | slog
			es "configuring nextcloud - sleeping 30 seconds to allow init"
			sleep 30 # this is to allow nextcloud docker container to init - if it's too fast it won't roger up over curl. 
			# the below creates an admin user, to get around the skeleton crap. So we'll create our rts user after setup is complete.
			curl -s 'http://nextcloud.rts.lan/index.php' \
  			-H 'Connection: keep-alive' \
  			-H 'Cache-Control: max-age=0' \
  			-H 'Origin: null' \
  			-H 'Upgrade-Insecure-Requests: 1' \
  			-H 'DNT: 1' \
  			-H 'Content-Type: application/x-www-form-urlencoded' \
  			-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.55 Safari/537.36 Edg/96.0.1054.41' \
  			-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  			-H 'Accept-Language: en-US,en;q=0.9' \
  			-H 'Cookie: oc_sessionPassphrase=TW1ohzxK%2F%2BlaWyuMxN10G30%2BKZSH9YcDelpA%2FO7ncW7i2cGitpSwsqc5d5yNUnvcqj2xHo7bx%2FqLQQX2yDggDJZYBrZ6TUmfwe582pJ7m1fyFvAH9Jfw%2FUAbjsjPHVDz; nc_sameSiteCookielax=true; nc_sameSiteCookiestrict=true; ocuu9t7omn5d=38cf0357ac05e30828f9d6dcb39e1d82; ocrd4rn7yqen=7ce9f122acf91070eb391860acac1b11; ocgourudt1gn=6acb12044fd9615cc3d83cf3742559c8; octp6wai7af2=ddac7c044bc04517cacf9a2fcf6644fd' \
  			--data-raw "install=true&adminlogin=admin&adminpass=$url_encoded_pass&adminpass-clone=$url_encoded_pass&directory=%2Fvar%2Fwww%2Fhtml%2Fdata&dbtype=mysql&dbuser=nextcloud&dbpass=rts_passw0rd&dbpass-clone=rts_passw0rd&dbname=nextcloud&dbhost=nextcloud_db&install-recommended-apps=on" \
  			--compressed \
  			--insecure \
  			--keepalive-time 300 | slog
			sudo -u rts docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ config:system:set skeletondirectory | slog
			sudo -u rts docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ app:enable files_external 2>&1 | slog
			sudo -u rts docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ files_external:create --config datadir=/red-share -- red-share local null::null 2>&1 | slog
			sudo -u rts docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ files_external:option 1 enable_sharing true | slog
			sudo -u rts docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ files_external:option 1 previews true | slog
			sudo -u rts docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ files_external:option 1 filesystem_check_changes 1 | slog
			sudo -u rts docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ app:enable breezedark | slog
			sudo -u rts docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ config:app:set breezedark theme_automatic_activation_enabled --value=1 | slog
			sudo -u rts docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ config:app:set breezedark theme_enabled --value=1 | slog
			sudo -u rts docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ app:install contacts | slog
			sudo -u rts docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ app:install calendar | slog
			sudo -u rts docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ app:install mail | slog
			#sudo -u rts docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ app:install richdocuments | slog #### This is causing massive delays on disconnected standalone networks
			#sudo -u rts docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ app:install richdocumentscode | slog #### This is causing massive delays on disconnected standalone networks
			sudo -u rts docker exec -e OC_PASS="${rts_password}" -t nextcloud_app runuser -u www-data -- /var/www/html/occ user:add --password-from-env --display-name="rts" --group="admin" rts | slog
			if [ $? -eq 0 ]; then ec "nextcloud init completed."; else ee "initial nextcloud setup failed, please post an issue on the RTS github."; fi
			sleep 5
			clear_menu "6"
			;;
		"cyberchef")
			es "installing cyberchef"
			sudo -u rts echo $docker_compose_cyberchef | base64 -d >> ${install_path}/docker-compose.yml | slog
			sudo -u rts docker-compose -f ${install_path}/docker-compose.yml pull cyberchef 2>&1
			sed -i '/<!-- mainsed -->/a <a href="http://cyberchef.rts.lan" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">cyberchef</a>' ${install_path}/website/index.html
			check_exit_code "$?" "cyberchef" | slog
			add_hosts "cyberchef.rts.lan"
			sleep 5
			clear_menu "3"
			;;
		"portainer.io")
			es "installing portainer.io"
			sudo -u rts echo $docker_compose_portainer| base64 -d >> ${install_path}/docker-compose.yml | slog
			sudo -u rts docker-compose -f ${install_path}/docker-compose.yml pull portainer 2>&1
			sed -i '/<!-- mainsed -->/a <a href="http://portainer.rts.lan" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">portainer</a>' ${install_path}/website/index.html
			check_exit_code "$?" "portainer.io" | slog
			add_hosts "portainer.rts.lan"
			sleep 5
			clear_menu "3"
			;;
		"MITRE caldera")
			es "installing MITRE caldera (long install)" 
			sudo -u rts echo $docker_compose_caldera | base64 -d >> ${install_path}/docker-compose.yml | slog
			if [ -d "${install_path}/caldera" ]; then sudo -u rts git -C ${install_path}/caldera/ pull 2>&1 | slog; else sudo -u rts git clone https://github.com/mitre/caldera.git --recursive ${install_path}/caldera 2>&1 | slog; fi
			sudo -u rts docker-compose -f ${install_path}/docker-compose.yml build caldera 2>&1 | slog
			sed -i '/<!-- mainsed -->/a <a href="http://caldera.rts.lan" class="w3-button w3-bar-item w3-center" target="_blank" rel="noopener noreferrer">caldera</a>' ${install_path}/website/index.html
			check_exit_code "$?" "caldera" | slog
			add_hosts "caldera.rts.lan"
			sleep 5
			clear_menu "2"
			;;
		"pentest collab framework")
			es "installing pentest collaboration framework (long install)"
			sudo -u rts echo $docker_compose_pcf | base64 -d >> ${install_path}/docker-compose.yml
			if [ -d "${install_path}/pcf" ]; then sudo -u rts git -C ${install_path}/pcf/ pull 2>&1 | slog; else sudo -u rts git clone https://gitlab.com/invuls/pentest-projects/pcf.git ${install_path}/pcf 2>&1 | slog; fi
			sudo -u rts docker-compose -f ${install_path}/docker-compose.yml build pcf 2>&1 | slog
			sed -i '/<!-- mainsed -->/a <a href="http://pcf.rts.lan" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">PCF</a>' ${install_path}/website/index.html
			check_exit_code "$?" "pcf" | slog
			add_hosts "pcf.rts.lan"
			sleep 5
			clear_menu "3"
			;;
		"lolbas/gtfobins")
			es "installing lolbas/gtfobins"
			sudo -u rts echo $docker_compose_lolbas | base64 -d >> ${install_path}/docker-compose.yml
			sudo -u rts docker-compose -f ${install_path}/docker-compose.yml build lolbas 2>&1 | slog
			sed -i '/<!-- refsed -->/a <a href="http://rts.lan:10050/" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">lolbas</a>' ${install_path}/website/index.html
			sed -i '/<!-- refsed -->/a <a href="http://rts.lan:10060" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">gtfobins</a>' ${install_path}/website/index.html
			check_exit_code "$?" "lolbas/gtfobins" | slog
			sleep 5
			clear_menu "3"
			;;
		"hacktricks")
			es "installing hacktricks"
			hacktricks="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/carlospolop/hacktricks.git\", \"description\": \"hacktricks.xyz\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"hacktricks\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
			eval $hacktricks
			sed -i '/<!-- refsed -->/a <a href="http://gitea.rts.lan/rts/hacktricks" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">hacktricks</a>' ${install_path}/website/index.html
			clear_menu "1"
			;;
		"payload all the things")
			es "installing payload all the things"
			payload_all_the_things="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/swisskyrepo/PayloadsAllTheThings.git\", \"description\": \"A list of useful payloads\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"payload_all_the_things\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
			eval $payload_all_the_things 
			sed -i '/<!-- refsed -->/a <a href="http://gitea.rts.lan/rts/payload_all_the_things" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">payload all the things</a>' ${install_path}/website/index.html
			clear_menu "1"
			;;
		"cheatsheets")
			es "installing cheatsheets"
			sed -i '/<!-- refsed -->/a <a href="http://www.rts.lan/cheatsheets" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">cheatsheets</a>' ${install_path}/website/index.html
			clear_menu "1"
			;;
		"pentest standards")
			es "installing pentest standards"
			sed -i '/<!-- refsed -->/a <a href="http://www.rts.lan/ptes" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">PTES</a>' ${install_path}/website/index.html
			clear_menu "1"
			;;
		"cobalt strike community kit")
			es "installing cobalt strike community kit"
			cobalt_strike_community_kit="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/Cobalt-Strike/community_kit.git\", \"description\": \"Cobalt Strike Community Kit\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"cobalt_strike_community_kit\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
			eval $cobalt_strike_community_kit
			git clone http://gitea.rts.lan/rts/cobalt_strike_community_kit.git ${install_path}/cobalt_strike_community_kit/ > /dev/null 2>&1  | slog
			chmod +x /opt/rts/cobalt_strike_community_kit/community_kit_downloader.sh | slog
			/opt/rts/cobalt_strike_community_kit/community_kit_downloader.sh | slog
			sed -i '/<!-- auxsed -->/a <a href="http://gitea.rts.lan/rts/cobalt_strike_community_kit" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">cs community kit</a>' ${install_path}/website/index.html
			clear_menu "1"
			;;
		"seclists")
			es "installing seclists"
			seclists="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/danielmiessler/SecLists.git\", \"description\": \"SecLists\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"SecLists\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
			eval $seclists
			sed -i '/<!-- auxsed -->/a <a href="http://gitea.rts.lan/rts/seclists" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">seclists</a>' ${install_path}/website/index.html
			clear_menu "1"
			;;
		"hastebin")
			es "installing hastebin"
			sudo -u rts echo $docker_compose_hastebin | base64 -d >> ${install_path}/docker-compose.yml
			sudo -u rts docker-compose -f ${install_path}/docker-compose.yml build hastebinweb 2>&1 | slog
			sed -i '/<!-- mainsed -->/a <a href="http://hastebin.rts.lan" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">hastebin</a>' ${install_path}/website/index.html
			check_exit_code "$?" "hastebin" | slog
			add_hosts "hastebin.rts.lan"
			sleep 5
			clear_menu "2"
			;;
		"hatecrack")
			es "installing hatecrack"
			hatecrack="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/trustedsec/hate_crack.git\", \"description\": \"TrustedSec HateCrack\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"hatecrack\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
			eval $hatecrack
			sed -i '/<!-- auxsed -->/a <a href="http://gitea.rts.lan/rts/hatecrack" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">hatecrack</a>' ${install_path}/website/index.html
			clear_menu "1"
			;;
		"slowloris")
			es "installing slowloris"
			slowloris="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/gkbrk/slowloris.git\", \"description\": \"Slowloris DOS\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"slowloris\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
			eval $slowloris
			sed -i '/<!-- auxsed -->/a <a href="http://gitea.rts.lan/rts/slowloris" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">slowloris</a>' ${install_path}/website/index.html 
			clear_menu "1"
			;;
		"ghostpack")
			es "installing ghostpack"
			ghostpack="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/r3motecontrol/Ghostpack-CompiledBinaries.git\", \"description\": \"Ghostpacks C# Binaries\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"ghostpack\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
			eval $ghostpack
			sed -i '/<!-- auxsed -->/a <a href="http://gitea.rts.lan/rts/ghostpack" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">ghostpack</a>' ${install_path}/website/index.html
			clear_menu "1"
			;;
		"veil")
			es "installing veil evasion framework"
			veil="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/Veil-Framework/Veil.git\", \"description\": \"Veil Evasion Framework\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"veil-evasion\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
			eval $veil
			sed -i '/<!-- auxsed -->/a <a href="http://gitea.rts.lan/rts/veil-evasion" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">veil evasion</a>' ${install_path}/website/index.html
			clear_menu "1"
			;;
		"cobalt strike elevate kit")
			es "installing cobalt strike elevate kit"
			cobalt_strike_elevate="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/Cobalt-Strike/ElevateKit.git\", \"description\": \"Cobalt Strike Elevate Kit\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"cobalt_strike_elevate\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
			eval $cobalt_strike_elevate
			sed -i '/<!-- auxsed -->/a <a href="http://gitea.rts.lan/rts/cobalt_strike_elevate" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">cs elevate kit</a>' ${install_path}/website/index.html
			clear_menu "1"
			;;
		"cobalt strike c2 profiles")
			es "installing cobalt strike c2 profiles"
			cobalt_strike_c2_profiles="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/Cobalt-Strike/Malleable-C2-Profiles.git\", \"description\": \"Cobalt Strike Malleable C2 Profiles\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"cobalt_strike_malleable-c2\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
			eval $cobalt_strike_c2_profiles
			sed -i '/<!-- auxsed -->/a <a href="http://gitea.rts.lan/rts/cobalt_strike_malleable-c2" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">cs c2 profiles</a>' ${install_path}/website/index.html
			clear_menu "1"
			;;
		"cobalt strike arsenal")
			es "installing cobalt strike arsenal"
			cobalt_strike_arsenal="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/mgeeky/cobalt-arsenal.git\", \"description\": \"Cobalt Strike Battle Tested Arsenal\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"cobalt_strike_arsenal\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
			eval $cobalt_strike_arsenal
			sed -i '/<!-- auxsed -->/a <a href="http://gitea.rts.lan/rts/cobalt_strike_arsenal" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">cs arsenal</a>' ${install_path}/website/index.html
			clear_menu "1"
			;;
		"MITRE att&ck navigator")
			es "installing mitre att&ck navigator"
			sudo -u rts echo $docker_compose_attacknav | base64 -d >> ${install_path}/docker-compose.yml
			if [ -d "${install_path}/attack-navigator" ]; then sudo -u rts git -C ${install_path}/attack-navigator/ pull 2>&1 | slog; else sudo -u rts git clone https://github.com/mitre-attack/attack-navigator.git ${install_path}/attack-navigator 2>&1 | slog; fi
			sudo -u rts mv ${install_path}/attacknav-Dockerfile ${install_path}/attack-navigator/Dockerfile
			sudo -u rts docker-compose -f ${install_path}/docker-compose.yml build attack-nav-node 2>&1 | slog
			sed -i '/<!-- refsed -->/a <a href="http://attack-nav.rts.lan" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">att&ck navigator</a>' ${install_path}/website/index.html
			check_exit_code "$?" "mitre attack navigator" | slog
			add_hosts "attack-nav.rts.lan"
			sleep 5
			clear_menu "2"
			;;
		"MITRE att&ck reference")
			es "installing MITRE att&ck ref (long install)"
			sudo -u rts echo $docker_compose_attackweb | base64 -d >> ${install_path}/docker-compose.yml
			if [ -d "${install_path}/attack-website" ]; then sudo -u rts git -C ${install_path}/attack-website/ pull 2>&1 | slog; else sudo -u rts git clone https://github.com/mitre-attack/attack-website.git ${install_path}/attack-website 2>&1 | slog; fi
			sudo -u rts docker-compose -f ${install_path}/docker-compose.yml build attack-web 2>&1 | slog
			sed -i '/<!-- refsed -->/a <a href="http://attack.rts.lan" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">att&ck reference</a>' ${install_path}/website/index.html
			check_exit_code "$?" "mitre attack ref" | slog
			add_hosts "attack.rts.lan"
			sleep 5
			clear_menu "2"
			;;
		*)
			echo "somethings wrong, cannot contiue" 
			echo "Returning."
			clear_menu "2"
			;;
	esac
	return
}
install() {
	# Next couple lines check to make sure gitea installs if ref & aux modules are supposed to be installed. If not it bails back to main_menu 
	aux_packages_enabled=0
	ref_packages_enabled=0
	url_encoded_pass=$( rawurlencode "$rts_password" )
	for auxkey in "${!auxiliary[@]}"
  	do
    	if [[ ${auxiliary[$auxkey]} -eq 1 ]]; then aux_packages_enabled=1; else aux_packages_enabled=0; fi
  	done
	for refkey in "${!references[@]}"
  	do
    	if [[ ${references[$refkey]} -eq 1 ]]; then ref_packages_enabled=1; else ref_packages_enabled=0; fi
  	done
	if [[ ${packages[gitea]} -ne 1 && $aux_packages_enabled -eq 1 ]] || [[ ${packages[gitea]} -ne 1 && $ref_packages_enabled -eq 1 ]]; then disabled_item; print "gitea must be enabled to install aux & ref modules."; print "\n"; sleep 5; clear_menu "1"; main_menu; fi
	echo "rts_ip_address=${ip_address}" > ./setup/.env
	echo -e "added rts_ip_address=${ip_address} to ./setup/.env" | slog
	es "checking hostname status"
	# check to see if hostname is set correctly
	check_hostname="$(hostname -f)"
	hosts_line="127.0.1.1	rts.lan	  rts"
	if [ "${check_hostname}" != "rts.lan" ]; then
    	ee "hostname is not set correctly (currently set to $check_hostname), setting to rts.lan"
    	hostnamectl set-hostname rts | slog
    	sed -i".bak" "/$check_hostname/d" /etc/hosts | slog
    	echo ${hosts_line} >> /etc/hosts
    	# verify hostname changed
    	if [ "`(hostname -f)`" != "rts.lan" ]; then
        	ee "hostname change did not work, you need to do it manually. Exiting."
        	exit 1
    	fi
    else ec "hostname (${check_hostname}) is correct."; sleep 1.5; clear_menu "2"
	fi
    # ensure ssh is enabled
	es "checking sshd status"
	check_sshd="$(systemctl is-active ssh)"
	if [ "${check_sshd}" = "inactive" ]; then
  		ew "sshd is not running, starting."
  		systemctl start ssh | slog
  		sleep 3
  		check_new_sshd="$(systemctl is-active ssh)"
  		if [ "${check_new_sshd}" = "inactive" ]; then
      		ee "sshd is not starting, check your configuration. Exiting."
			exit 1
  		else es "sshd successfully started." ; sleep 1.5; clear_menu "2"
  		fi
	else ec "ssh is running."; sleep 1.5; clear_menu "2"
	fi
	check_installed docker.io
	check_installed golang
	check_installed golang-go
	check_installed docker-compose
	check_installed jq
	#clear_menu "14"
	#ensure rts user exists on the system, and if not create it.
	es "checking to see if rts user exists"
	getent passwd rts | slog
	if [ $? -eq 0 ]; then
    	ec "'rts' user  exists" ; sleep 1.5; clear_menu "2"
	else
    	ew "'rts' user does not exist, creating.."
    	useradd rts -s /bin/bash -m -g adm -G dialout,cdrom,floppy,sudo,audio,dip,video,plugdev,netdev,bluetooth,wireshark,scanner,kaboxer,docker | slog
    	echo "rts:$rts_password" | chpasswd | slog
    	ec "user created."
		sleep 1.5; clear_menu "3"
	fi
	# check to make sure root belongs to docker group
	es "checking root and rts user permissions for docker"
	check_USER="root"
	check_GROUP="docker"
	if id -nG "$check_USER" | grep -qw "$check_GROUP" ; then
    	ec "$check_USER belongs to $check_GROUP"
	else
    	ew "$check_USER does not belong to $check_GROUP, adding."
    	sudo usermod -a -G $check_GROUP $check_USER | slog
	fi
	check_USER="rts"
	if id -nG "$check_USER" | grep -qw "$check_GROUP" ; then
    	ec "$check_USER belongs to $check_GROUP"
		sleep 1.5; clear_menu "3"
	else
    	ew "$check_USER does not belong to $check_GROUP, adding."
    	sudo usermod -a -G $check_GROUP $check_USER | slog
		sleep 1.5; clear_menu "3"
	fi
	# Check the initial user who ran the script, and setup the working directory.
	if [ "${initial_user}" != "rts" ] || [ "${initial_working_dir}" != "${install_path}" ]; then
		es "copying files from current location to ${install_path}"
        if [ ! -d "${install_path}" ] ; then
            mkdir ${install_path} | slog
            chown -R rts:adm ${install_path} | slog
	   	else
			#rm -rf ${install_path} | slog # I understand this clobbers a previous install directory - but if you already have it installed, why are you running this again? Clean install? 
            #mkdir ${install_path} | slog
            chown -R rts:adm ${install_path} | slog
        fi
		# sudo -u rts cp -R ${initial_working_dir}/. ${install_path}
		sudo -u rts cp -R ${initial_working_dir}/covenant ${install_path} | slog
		sudo -u rts cp -R ${initial_working_dir}/hastebin ${install_path} | slog
		if [ -d "${install_path}/lolbas"]; then rm ${install_path}/lolbas; else mkdir ${install_path}/lolbas; fi
		sudo -u rts cp ${initial_working_dir}/{.env,config.json,docker-compose.yml,watchdog.sh,environment.js,homeserver.yaml,nuke-docker.sh,scan.sh,nuke-ivre.sh,nuke.sh,attacknav-Dockerfile,lolbas-Dockerfile} ${install_path} | slog
		sudo -u rts mv ${install_path}/lolbas-Dockerfile ${install_path}/lolbas/
		es "changing working directory to ${install_path}"
    	cd ${install_path}
        pwd
        ec "assuming rts user level."; sleep 1.5; clear_menu "4"
	else ec "user and path look good to go."; sleep 1.5; clear_menu "3"
	fi
	#check for internet access
	es "checking for internet access"
	if nc -zw1 google.com 443; then
  		ec "internet connectivity checks successful."; sleep 1.5; clear_menu "2"
	else ee "internet connectivity is *REQUIRED* to build RTS. Fix, and restart script." ; exit 1
	fi
	sudo_1=$(sudo -u rts whoami)
	sudo_2=$(sudo -u rts pwd)
	es "dropping priveleges down to rts user account." 
	if [ "${sudo_1}" = "rts" ]; then
   		es "user privs look good."
   		if [ "${sudo_2}" = "${install_path}" ]; then
      		es "build path looks good."
   		else
        	ee "something is wrong and we are not in the right path. Exiting."
        	exit 1
   		fi
	else
   		ee "something is wrong and we are not the right user. Exiting."
   		exit 1
	fi
	sleep 1.5; clear_menu "3"
	es "setting up file system structure"
	### Need to add functionality to check and see if directory exists
    sudo -u rts cp -R ${initial_working_dir}/website  ${install_path}/ | slog
	if [ ! -d "${install_path}/red-share" ]; then sudo -u rts mkdir ${install_path}/red-share | slog; fi
	if [ ! -d "${install_path}/red-share/ivre" ]; then sudo -u rts mkdir ${install_path}/red-share/ivre | slog; fi
	sudo -u rts chmod -R 777 ${install_path}/red-share | slog
	chmod 775 /opt/rts/docker-compose.yml
	sleep 1.5; clear_menu "1"
	ew "start crack-a-lackin"
	# Now we need to check the associaitive array to determine which packages are installed.
	# Populate docker-compose preamble
	echo $docker_compose_preamble | base64 -d > ${install_path}/docker-compose.yml
	sudo -u rts docker-compose -f ${install_path}/docker-compose.yml pull rts-web 2>/dev/null
	add_hosts "www.rts.lan"
	sleep 1.5; clear_menu "1"
	echo $docker_compose_nginx_proxy | base64 -d >> ${install_path}/docker-compose.yml
	sudo -u rts docker-compose -f ${install_path}/docker-compose.yml pull nginx-proxy 2>/dev/null
	sleep 1.5
	sudo -u rts docker-compose -f ${install_path}/docker-compose.yml up -d nginx-proxy rts-web 2>/dev/null
	# iterate through first assoc array
    print_line
	ew "installing main packages"
    print_line
	for key in "${!packages[@]}"
    do
    	if [[ ${packages[$key]} -eq 1 ]]; then # If the package is to be installed 
      		#es "installing $key"
			install_package "$key"
    	else # if the package is not to be installed
			es "Skipping $key"
			clear_menu "1"
    	fi
    done
	ew "main packages complete."
	sleep 3
	clear_menu "4"
    print_line
	ew "installing aux packages"
    print_line
	for key in "${!auxiliary[@]}"
	do
		if [[ ${auxiliary[$key]} -eq 1 ]]; then # if the aux is to be installed
			install_package "$key"
		else # if the package is not to be installed
			es "Skipping $key"
			clear_menu "1"
		fi
	done
	ew "aux packages complete."
	sleep 3
	clear_menu "4"
	print_line
	ew "installing references"
	print_line
	for key in "${!references[@]}"
	do
		if [[ ${references[$key]} -eq 1 ]]; then # if the ref is to be installed
			install_package "$key"
		else
			es "Skipping $key"
			clear_menu "1"
		fi
	done
	ec "installation complete."
	sleep 5
	clear_menu "4"
	post_install
	quit_
}
post_install() {
	print_line
	ew "configuring post installation configuration"
	print_line
	export PATH=$PATH:${install_path}
	if grep -q "#RTS Path" /home/rts/.bashrc; then true ; else echo "#RTS Path" >> /home/rts/.bashrc; echo "export PATH=$PATH:${install_path}" >> /home/rts/.bashrc; fi
	if grep -q "#RTS Path" /home/rts/.bashrc; then true ; else echo "#RTS Path" >> /home/rts/.zshrc; echo "export PATH=$PATH:${install_path}" >> /home/rts/.zshrc; fi
	if grep -q "#RTS Path" /home/rts/.profile; then true ; else echo "#RTS Path" >> /home/rts/.profile; echo "export PATH=$PATH:${install_path}" >> /home/rts/.profile; fi
	sudo chmod 777 /etc/samba/smb.conf
	sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
	if grep -Fq "[red-share]" /etc/samba/smb.conf
    then
        es "samba already configured, you are good to go."
		sleep 1
    else
        sudo echo "[red-share]" >> /etc/samba/smb.conf
        sudo echo "comment = Redteam Share" >> /etc/samba/smb.conf
        sudo echo "path = /opt/rts/red-share" >> /etc/samba/smb.conf
        sudo echo "public = yes" >> /etc/samba/smb.conf
        sudo echo "writeable = yes" >> /etc/samba/smb.conf
        sudo systemctl restart smbd.service
        sudo systemctl restart nmbd.service
        echo "samba server configuration complete"
		sleep 1
	fi
	sudo systemctl start smbd.service
    sudo systemctl start nmbd.service
	clear_menu "1"
	mv ${install_path}/nuke.sh ${install_path}/red-share/ivre/
	es "configuring rts services"
	rts_python_web_server="W1VuaXRdCkRlc2NyaXB0aW9uPVJUUyBQeXRob24gU2VydmVyCkFmdGVyPW5ldHdvcmsudGFyZ2V0CgpbU2VydmljZV0KVHlwZT1zaW1wbGUKVXNlcj1yb290CldvcmtpbmdEaXJlY3Rvcnk9L29wdC9ydHMvcmVkLXNoYXJlCkV4ZWNTdGFydD0vdXNyL2Jpbi9weXRob24zIC1tIGh0dHAuc2VydmVyIC1kIC9vcHQvcnRzL3JlZC1zaGFyZSA4MDgxClJlc3RhcnQ9b24tYWJvcnQKCltJbnN0YWxsXQpXYW50ZWRCeT1tdWx0aS11c2VyLnRhcmdldAo="
	rts_watch_dog="W1VuaXRdCkRlc2NyaXB0aW9uPVJlZCBUZWFtIFNlcnZlciBXYXRjaGRvZwoKW1NlcnZpY2VdCkV4ZWNTdGFydD0vb3B0L3J0cy93YXRjaGRvZy5zaAoKW0luc3RhbGxdCldhbnRlZEJ5PW11bHRpLXVzZXIudGFyZ2V0Cg=="
	sudo -u root echo $rts_python_web_server | base64 -d > /etc/systemd/system/rts-web-server.service | slog
	sudo -u root echo $rts_watch_dog | base64 -d > /etc/systemd/system/rts-watchdog.service | slog
	sudo systemctl daemon-reload
	sleep 3
	es "starting rts services"
	sudo systemctl restart rts-web-server.service | slog
	sudo systemctl restart rts-watchdog.service | slog
	sed -i '/<!-- mainsed -->/a <a href="http://rts.lan:8081" class="w3-button w3-bar-item" target="_blank" rel="noopener noreferrer">red-share</a>' ${install_path}/website/index.html | slog
    clear_menu "2"
	sleep 3
	ew "bringing up the environment for initialization"
	sudo -u rts docker-compose -f ${install_path}/docker-compose.yml down --remove-orphans 2>&1 | slog
	sudo -u rts docker-compose -f ${install_path}/docker-compose.yml up -d 2>&1 | slog
	sleep 30
	clear
	if [[ -f "${install_path}/red-share/rts.txt" ]]; then rm ${install_path}/red-share/rts.txt; fi
	echo
	es "[****************************************************]" | tee ${install_path}/red-share/rts.txt
	es "[****************Service Information ****************]" | tee -a ${install_path}/red-share/rts.txt
	es "[****************************************************]" | tee -a ${install_path}/red-share/rts.txt
	es | tee -a ${install_path}/red-share/rts.txt
	es "Linux hosts file:" | tee -a ${install_path}/red-share/rts.txt
	es "/etc/hosts" | tee -a ${install_path}/red-share/rts.txt
	es "Windows hosts file:" | tee -a ${install_path}/red-share/rts.txt
	es "c:\windows\system32\drivers\etc\hosts" | tee -a ${install_path}/red-share/rts.txt
	es | tee -a ${install_path}/red-share/rts.txt
	es "Copy and Paste the following into your respective systems hosts file:" | tee -a ${install_path}/red-share/rts.txt
	cat /etc/hosts | grep -i "\.rts\.lan" | elog | tee -a ${install_path}/red-share/rts.txt
	echo | tee -a ${install_path}/red-share/rts.txt
	echo | tee -a ${install_path}/red-share/rts.txt
	ec "RTS is installed to ${install_path}. Scripts and setup data live here." | tee -a ${install_path}/red-share/rts.txt
	ec "The shared directory for engagement data is ${install_path}/red-share and is accessible from NextCloud, locally, SMB, and even via the website at the link." | tee -a ${install_path}/red-share/rts.txt
	ec "${install_path}/red-share is intended to be the central point for red teams to share data across the team. Please utilize it for artifact, scan, reporting data."| tee -a ${install_path}/red-share/rts.txt
	ec "The username and password for Gitea and Nextcloud are:" | tee -a ${install_path}/red-share/rts.txt
	ew "rts/$rts_password" | tee -a ${install_path}/red-share/rts.txt
	#ec "The username and password for Reconmap is:"
	#ew "admin/admin123"
	es "Log file moved from /tmp/rts.log to ${install_path}/rts.log" | tee -a ${install_path}/red-share/rts.txt
	es "scan.sh -> Scan script to order IVRE to scan a host/network/range." | tee -a ${install_path}/red-share/rts.txt
	es "nuke-ivre.sh -> orders IVRE to completely reset/wipe its database." | tee -a ${install_path}/red-share/rts.txt
	es "nuke-docker.sh -> completely destroys docker environment for fresh install on same box." | tee -a ${install_path}/red-share/rts.txt
	es "sudo systemctl stop rts-watchdog.service to stop the watchdog service" | tee -a ${install_path}/red-share/rts.txt
	es "sudo systemctl stop rts-web-server.service to stop the python http.server on port 8081" | tee -a ${install_path}/red-share/rts.txt
	es "A copy of this text has been placed in ${install_path}/red-share/rts.txt" | tee -a ${install_path}/red-share/rts.txt
	#es "rmap -> Reconmap CLI interface. Refer to its github for instructions."
	ec "This concludes RTS installation." | tee -a ${install_path}/red-share/rts.txt
	mv /tmp/rts.log ${install_path}
	chown rts:adm ${install_path}/rts.log
	read -p "Press any key to continue."
}
# create a fresh log if installation got interrupted
rm -rf /tmp/rts.log | slog
# remove previous rmap config if present
rm -rf /home/rts/.reconmap/config.json | slog
init
${stty} "${saved_stty}"
echo -en "${show_cursor}"
author
main_menu
sleep 5
quit_
clear
