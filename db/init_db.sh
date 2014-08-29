#!/bin/bash
# (c) by dev@vn.innovation.co.jp
#
####### DESCRIPTION #######
# ... working name= anhndt
# ... database name= it_trend_anhndt
# ... project directory= /var/www/it-trend.jp/anhndt/
# ... current branch= 1926
# ... sql script file(s)=
# ... ... ...... /var/www/it-trend.jp/anhndt/IT/mysql/m_products_d_1926.sql
# _______
# 
# 1. Change the working name .. ("anhndt"):
# 2. DB "it_trend_anhndt" will be synchronized. Do you want to exec ? [y/N]: y
# .. .. dump DB "test" ...
# .. .. .... .. done, file= /var/www/it-trend.jp/_it_trend_release_20140715.132644.dump
# .. .. restore DB "test_imp" ...
# .. .. ....... .. done
# 2.1. Do you want to remove file DB .dump ? [y/N]: y
# .... .. ... .... done, file= /var/www/it-trend.jp/_it_trend_release_20140715.132644.dump
# 3. DB "test_imp" will be updated. Do you want to exec ? [y/N]: y
# 3.1. Change the working branch .. ("1926"):
# .... ...... exec SQL script file(s) ...
# .... ...... .... ... done, file= /var/www/it-trend.jp/anhndt/IT/mysql/m_products_d_1926.sql
# END.
# 
##### Constants
DB_PREFIX_NAME="it_trend_"
DB_CONNECT_ID="root"
DB_CONNECT_PASWORD="fdtjsECysYFXdy7K"
# -- DEBUG
#DB_MASTER_NAME="test"
#DB_USER_NAME_TEST="test_imp"
# -- PRODUCTION
DB_MASTER_NAME="it_trend_release"

PROJECT_DIR="/var/www/it-trend.jp/"
PROJECT_SQLSCRIPT="IT/mysql"
# defaut user
user_name=$USER
##### Functions
# **
# *
# **
function do_initialization() {
	user_project_dir="$PROJECT_DIR$user_name/"
	cd "$user_project_dir"
	user_db_name=$DB_PREFIX_NAME$user_name
	source_branch_name="master"
	user_sqlscript_dir="$user_project_dir$PROJECT_SQLSCRIPT/"
	# extract git branch
	tmp_var=$(git branch | grep -o -P "^\* \#\d+")
	if [ -n "$tmp_var" ]; then
		tmp_length=${#tmp_var}
		if [ "$tmp_length" == "7" ]; then
			source_branch_name=${tmp_var:3}
		fi
	fi
}

# **
# *
# **
function print_welcome() {
	echo "IT-TREND.JP TOOL - SYNCHRONIZE DB"
	echo "....... [ENTER-key == default]"
	echo "....... "
	echo "....... (description)"
	echo "....... "
}

# **
# *
# **
function print_status() {
	echo "_______"
	echo "... working name= $user_name"
	echo "... database name= $user_db_name"
	echo "... project directory= $user_project_dir"
	echo "... current branch= $source_branch_name"
	echo "... sql script file(s)="
	# extract *.sql script of current branch
	for tmp_var in "$user_sqlscript_dir"*
	do
		if [[ $tmp_var == *$source_branch_name.sql* ]] ; then
			echo "... ... ...... $tmp_var"
		fi
	done
	#
	echo -e "_______\n"
	return 1
}

# **
# *
# **
function change_working_name() {
	do_initialization
	print_status
}

# **
# * Dump from DB it_trend_release to .dump file
# * Restore .dump file to DB it_trend_user
# **
function exec_db_synch() {
	#dump
	now=$(date +"%Y%m%d.%H%M%S")
	user_db_dumpfile="$PROJECT_DIR"
	user_db_dumpfile+="_it_trend_release_$now.dump"
	echo ".. .. dump DB \"$DB_MASTER_NAME\" ..."
	$(mysqldump --opt --user=$DB_CONNECT_ID --password=$DB_CONNECT_PASWORD $DB_MASTER_NAME > $user_db_dumpfile)
	echo ".. .. .... .. done, file= $user_db_dumpfile"
	#restore
	# -- DEBUG
	#user_db_name=$DB_USER_NAME_TEST
	$(mysql --user=$DB_CONNECT_ID --password=$DB_CONNECT_PASWORD $user_db_name < $user_db_dumpfile)
	echo ".. .. restore DB \"$user_db_name\" ..."
	echo ".. .. ....... .. done"
	return 1
}

# **
# * run sql
# **
function exec_db_upgrade() {
	echo ".... ...... exec SQL script file(s) ..."
	# extract *.sql script of current branch
	for tmp_var in "$user_sqlscript_dir"*
	do
		if [[ $tmp_var == *$source_branch_name.sql* ]] ; then
			$(mysql --user=$DB_CONNECT_ID --password=$DB_CONNECT_PASWORD $user_db_name < $tmp_var)
			echo ".... ...... .... ... done, file= $tmp_var"
		fi
	done
	return 1
}

##### main()
##. init & print welcome message
do_initialization
print_welcome
print_status

#1. change working name
read -p "1. Change the working name .. (\"$user_name\"): " tmp_var
if [ -n "$tmp_var" ]; then
	# directory must be exists
	if [ -d "$PROJECT_DIR$tmp_var" ]; then
		# release 
		if [[ $tmp_var == *release* ]] ; then
			echo ".. Working name is invalid ! Please check dir $PROJECT_DIR!"
		else
			user_name=$tmp_var
			change_working_name
		fi
	else
		echo ".. Working name does NOT exists ! Please check dir $PROJECT_DIR!"
	fi

fi

#2. Database will be synchronized, do you want to exec ?
read -p "2. DB \"$user_db_name\" will be synchronized. Do you want to exec ? [y/N]: " tmp_var
if [ "$tmp_var" == "y" ]; then
	exec_db_synch
	#remove dump
	if [ -n "$user_db_dumpfile" ]; then
		read -p "2.1. Do you want to remove file DB .dump ? [y/N]: " tmp_var
		if [ "$tmp_var" == "y" ]; then
			$(rm -f $user_db_dumpfile)
			echo ".... .. ... .... done, file= $user_db_dumpfile"
		fi
	fi
fi

#3. Database will be updated. Do you want to exec ?
read -p "3. DB \"$user_db_name\" will be updated. Do you want to exec ? [y/N]: " tmp_var
if [ "$tmp_var" == "y" ]; then
	read -p "3.1. Change the working branch .. (\"$source_branch_name\"): " tmp_var
	if [ -n "$tmp_var" ]; then
		source_branch_name=$tmp_var
	fi
	exec_db_upgrade
fi
echo "END."
