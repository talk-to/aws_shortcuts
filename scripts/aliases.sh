#!/usr/bin/env bash


read -r project ec2 ec2f s3 s3f lambdas lambdasf params paramsf<<< $(echo $1 $2 $3 $4 $5 $6 $7 $8 $9)
shift 9
read -r get_param dns dnsf get_domain lb lbf cf cff<<< $(echo $1 $2 $3 $4 $5 $6 $7 $8)

store="$HOME/.$project"
project_path="$store/$project"
alias_file="$store/.aliases"

import_project="import sys;sys.path.append('$project_path');from services import aws, common, driver"

echo """
$ec2() {
    grep -i \"\$1\" \"$store/$ec2f.txt\"
}

$s3() {
    grep -i \"\$1\" \"$store/$s3f.txt\"
}

$lambdas() {
    grep -i \"\$1\" \"$store/$lambdasf.txt\"
}

$params() {
    grep -i \"\$1\" \"$store/$paramsf.txt\"
}

$get_param() {
    if [ ! -z \"\$1\" ]
    then
         python -c \"$import_project; aws.get_ssm_parameter_value('\$1')\"
    fi
}

$dns() {
    grep -i \"\$1\" \"$store/$dnsf.txt\"
}

$get_domain() {
    if [ ! -z \"\$1\" ]
    then
         python -c \"$import_project; common.get_domain('\$1')\"
    fi
}


$lb() {
    grep -i \"\$1\" \"$store/$lbf.txt\"
}

$cf() {
    grep -i \"\$1\" \"$store/$cff.txt\"
}

awss() {
case \"\$1\" in
	"configure")
		python -c \"$import_project;common.configure_project_commands();common.create_alias_functions()\"
		source "$alias_file"
		;;
	"update")
		$project_path/scripts/cron.sh
		;;
	"upgrade")
		git clone --quiet https://github.com/sunil-saini/"$project".git "$store/temp" >/dev/null
		cp $project_path/resources/commands.properties $project_path/resources/commands.properties.bak
		cp -r "$store/temp"/{resources,scripts,services,requirements.txt,awss.py} $project_path
		rm -rf "$store/temp"
		python -m pip install --ignore-installed -q -r "$project_path"/requirements.txt --user
		python -c \"$import_project;common.merge_properties_file();common.create_alias_functions()\"
		source "$alias_file"
		awss update
		awss
		;;
	*)
		python -c \"$import_project;common.read_project_current_commands()\"
		;;
esac
}""" > "$alias_file"