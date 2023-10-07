#!/bin/sh

################################
#                              #
#          CHECKER             #
#                              #
################################

CHECKER_MAC="checker_Mac"
CHECKER_LINUX="checker_linux"
LINK_CHECKER_MAC="https://cdn.intra.42.fr/document/document/18330/$CHECKER_MAC"
LINK_CHECKER_LINUX="https://cdn.intra.42.fr/document/document/18331/$CHECKER_LINUX"

OSTYPE=$(uname -s | tr '[:upper:]' '[:lower:]')

case "$OSTYPE" in
    darwin*)
        CHECKER="$CHECKER_MAC"
        ;;
    linux*)
        CHECKER="$CHECKER_LINUX"
        ;;
    *)
        echo "Unsupported OS"
        exit
        ;;
esac

downloader(){
	if [ -e "$CHECKER" ]
	then
		continue
	else
		printf "Downloading: \033[1m$CHECKER\033[m"
		if [ "$CHECKER" = "$CHECKER_MAC" ]
		then
			LINK_CHECKER=$LINK_CHECKER_MAC
		elif [ "$CHECKER" = "$CHECKER_LINUX" ]
		then
			LINK_CHECKER=$LINK_CHECKER_LINUX
		fi
		ftp $LINK_CHECKER > /dev/null
		if [ $? != 0 ] || [ -z "$CHECKER" ]
		then
			printf "$ERROR_DOWNLOAD"
			exit
		fi
		printf "\rDownloaded: \033[1m$CHECKER\033[m \n"
		chmod +x $CHECKER
	fi
}

################################
#                              #
#         NORMINETTE           #
#                              #
################################

norm_func(){
    printf "\n\033[1mNORMINETTE\033[m\n"
	if [ -z "$(which norminette)" ]
	then
		printf "Norminette not found\n"
	else
		norminette > /dev/null 2>&1
		if [ $? != 0 ]
		then
			printf "\033[38;2;220;20;30;1mKO\033[m\n\n"
			# exit
		else
			printf "\033[38;2;30;220;20;1mOK\033[m\n\n"
		fi
	fi
}

ps_test(){
	ARG=$(printf "%s " "$(seq 1 $1 | sort -R)")
	if [ $((TEST_FLAGS%3)) = 0 ]
	then
		echo -e ARG=
		echo $ARG
	fi
	OPERATIONS=$(./$BIN_MANDATORY $ARG)
	printf "Operation count is \033[1m%d\033[m\n" "$(echo "$OPERATIONS" | tr ' ' '\n' | wc -l)"
	if [ $((TEST_FLAGS%2)) = 0 ]
	then
		echo "\nRunning $BIN_BONUS:"
		echo "$OPERATIONS" | tr ' ' '\n' | ./$BIN_BONUS $ARG
	fi
	echo "Running $CHECKER"
	RESULT=$(echo "$OPERATIONS" | tr ' ' '\n' |  ./$CHECKER $ARG)
	if [ "$RESULT" = "OK" ]
	then
		printf "\033[38;2;30;220;20;1mOK\033[m\n\n"
	elif [ "$RESULT" = "KO" ]
	then
		printf "\033[38;2;220;30;20;1mKO\033[m\n\n"
	fi
}

err_test(){
	echo "\033[1m====================\033[m\n"
	printf "ARG=\"%s\"\n\n" "$1"
	echo $BIN_MANDATORY
	echo ----------
	./$BIN_MANDATORY $1
	EXIT_BIN=$?
	echo "----------\n"
	echo $CHECKER
	echo ----------
	RESULT=$(echo $(./$BIN_MANDATORY $1 2>/dev/null | ./$CHECKER $1))
	echo "----------\n"
	if [ "$RESULT" = "OK" ]
	then
		printf "\033[38;2;30;250;20;1mOK\033[m\n\n"
	elif [ "$RESULT" = "KO" ]
	then
		printf "\033[38;2;250;30;20;1mKO\033[m\n\n"
	elif [ -z "$RESULT" ]
	then
		printf "$BIN_MANDATORY should print an error\n\n"
	fi
}

range="2 3 4 5 10 50 100 300 500"

run_tests(){
    norm_func
	for i in $range
	do
		printf "ARG count is \033[32;1m$i\033[m\n\n"
		loop=0
		while [ "$loop" -le 4 ]
		do
			ps_test "$i"
			loop=$((loop+1))
		done
		echo "\n-----------------------------------------\n"
	done
}

run_error(){
	printf "\033[1mError tests:\033[m\n\n"
	echo "ARG=\n"
	echo $BIN_MANDATORY
	echo ----------
	./$BIN_MANDATORY
	echo "----------\n"
	echo $CHECKER
	echo ----------
	$(./$CHECKER)
	echo "----------\n"
	printf "Nothing should be printed\n\n"
	echo "\033[1m====================\033[m\n"
	echo "ARG=\"\""
	echo $BIN_MANDATORY
	echo ----------
	./$BIN_MANDATORY ""
	echo "----------\n"
	echo $CHECKER
	echo ----------
	./$CHECKER ""
	echo "----------\n"
	printf "$BIN_MANDATORY should print an error\n\n"
	err_test "            "
	err_test "+"
	err_test "4 2 4"
	err_test "1 -0 5"
	err_test "5 3+32 2"
	err_test "4 2 3-3 6 1"
	err_test "4 2 +3 6 1"
	err_test "4 2 --3 6 1"
	err_test "4 2 a 6 1"
	err_test "2147483648 0 -2 1"
	err_test "5 -2147483649 0 -2 1"
	err_test "9223372036854775808 0 -2 1"
	err_test "-9223372036854775809 0 -2 1"
	err_test "1"
	err_test "1 2 3 4 5"
	err_test "$(printf "%s " $(seq 1 50))"
}

CMD_MANDATORY="make all"
CMD_BONUS="make all bonus"

build_program()
{
	if [ $BUILD_FLAGS = 1 ]
	then
		CMD=$CMD_MANDATORY
	elif [ $BUILD_FLAGS = 2 ]
	then
		CMD=$CMD_BONUS
	fi
	printf "Running: \033[1m$CMD\033[m\n"
	$CMD
	if [ $? != 0 ]
	then
		printf "$0: $ERROR_MAKE\n"
		exit
	elif [ -z "$BIN_MANDATORY" ]
	then
		printf "$0: $ERROR_BIN_MANDATORY\n"
		exit;
	fi
	if [ $BUILD_FLAGS = 2 ] && [ -z "$BIN_BONUS" ]
	then
		printf "$0: $ERROR_BIN_BONUS\n"
		exit
	fi
}

MSG_DEFAULT="Try '--help' or '-h' arguments for usage"

MSG_HELP="\
\033[1mARGUMENTS\033[m
  -h, --help               Displays this message

  -m, --mandatory          Will execute the program with different sized and
                           randomized arrays. Each step contains the operation
                           count, then validates the output via $CHECKER

  -b, --bonus              Will follow every step taken in the --mandatory option,
                           but runs the output with $BIN_BONUS and $CHECKER
						   consecutively

  -e, --errors             Will try some erroneous inputs: Some are definitely
                           errors, some are questionable. Just testing

      --download-checker   Tries to download the checker binary for current OS
                           from intra

      --show-args          Same as --mandatory, but before, prints the \$ARG
                           in addition, for the curious ones.

\033[1mNOTES\033[m
	The script will automatically try to download checker binary from intra.
	I assume, it will fail if you are not logged in.
	If this occurs, try again after logging in.
	And if persists, add it manually.

	Multiple arguments will be accepted on the day after tomorrow"

ERROR_MAKE="An error occured while 'make'"
ERROR_BIN_MANDATORY="The executable '$BIN_MANDATORY' can not been found after 'make'"
ERROR_BIN_BONUS="The executable '$BIN_BONUS' can not been found after 'make'"
ERROR_DOWNLOAD="Could not download checker binary"

BUILD_FLAGS=1
TEST_FLAGS=1

BIN_MANDATORY="push_swap"
BIN_BONUS="checker"

if [ $# -gt 1 ]
then
	echo "$0: Multiple arguments are not supported, at least, currently"
	echo "$0: $MSG_DEFAULT"
	exit
elif [ -z "$1" ]
then
	echo "$0: $MSG_DEFAULT"
elif [ "$1" = "-h" ] || [ "$1" = "--help" ]
then
	printf "$MSG_HELP"
elif [ "$1" = "-m" ] || [ "$1" = "--mandatory" ]
then
	downloader
	build_program
	run_tests
	run_error
elif [ "$1" = "-b" ] || [ "$1" = "--bonus" ]
then
	BUILD_FLAGS=2
	TEST_FLAGS=$((TEST_FLAGS*2))
	downloader
	build_program
	run_tests
	run_error
elif [ "$1" = "-e" ] || [ "$1" = "--error" ]
then
	if [ -z "./push_swap" ]
	then
		downloader
		build_program
	fi
	run_error
elif [ "$1" = "--show-arg" ]
then
	TEST_FLAGS=$((TEST_FLAGS*3))
	downloader
	build_program
elif [ "$1" = "--download-checker" ]
then
	downloader
else
	echo "$0: $MSG_DEFAULT"
fi

echo "\n\niyi forumlar"
