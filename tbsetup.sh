#!/bin/bash

# webanz / anzweb.net@gmail.com 
# https://github.com/webanz/taskbuster-setup

# See  
# https://github.com/mineta/taskbuster-boilerplate

# TODO # 
#  Add proper cmd argument handling 
#  Use a generated random secret 

  

if [ "$#" -ne 4 ]; then
    echo "Usage : ./tbsetup.sh  project_name  env_prefix python_path pip_command"
    echo "Example : ./tbsetup.sh mydjango  myd  /usr/bin/python3  pip3  " 
    exit 1
fi


#Do  not run as root
if [[ $EUID -eq 0 ]]; then
   echo "This script must not be run as root" 1>&2
   exit 1
fi

venvSh=`env | grep virtualenvwrapper.sh  | awk -F= '{print $2}'`

# Source virtualenvwrapper
if [ -z $venvSh ];then
   echo 'Unable to source virtualenvwrapper.sh'
   exit 1
fi

source $venvSh

# Checks whether a virtualenv exist or not
existVenv() {
 envName=$1
 envRes=`lsvirtualenv -b | grep '^'$envName'$'`
 if [ "$envRes" == "$envName" ] ; then
    return 0
 else
    return 1
 fi
}



# Taskbuster
repoUrl='https://github.com/mineta/taskbuster-boilerplate'
tb_bp='taskbuster-boilerplate'
tb_proj='taskbuster'

declare  -A Ev
Ev=(['_dev']='development' ['_test']='testing')

# Command Line Arguments
project_name=$1
env_prefix=$2
python=$3
pip=$4

# TODO Generate
secret=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`

# clone Repo
if [ -d  ${tb_bp} ]; then
    echo -e "$(tput setaf 1)Directory ${tb_bp} exist. Not cloning  $repoUrl . Abort. $(tput sgr0) "
    exit 1
fi

git clone  $repoUrl

if [ $? -ne  0 ]; then
    echo  -e "$(tput setaf 1)Error clonig ${repoUrl}. Abort. $(tput sgr0)"
    exit 1
fi

project_dir=${project_name}'_project'

if [ -d $project_dir ] ; then
    echo  -e "$(tput setaf 1)${project_dir} exist. Abort.$(tput sgr0)"
    exit 1
fi


# create virtualenv and postactivate, predeactivate files
for k in ${!Ev[@]}
do
  if existVenv $env_prefix$k ; then
      echo "$(tput setaf 1)Virtualenv $env_prefix$k  already exist. Abort.$(tput sgr0)"
      exit 1
  fi
  mkvirtualenv  -p $python $env_prefix$k
  echo $VIRTUAL_ENV

  echo 'export DJANGO_SETTINGS_MODULE="'$project_name.settings.${Ev[$k]}'"'  > ${VIRTUAL_ENV}/bin/postactivate
  echo 'export SECRET_KEY="'$secret'"' >> ${VIRTUAL_ENV}/bin/postactivate
  echo 'unset SECRET_KEY'  > ${VIRTUAL_ENV}/bin/predeactivate

  deactivate
  echo $VIRTUAL_ENV
done

# Move taskbuster-boilerplate to target dir
mv ${tb_bp} ${project_dir}
# rename project
mv ${project_dir}/${tb_proj}  ${project_dir}/${project_name}


urls="'"${project_name}.urls"'"
wsgi="'"${project_name}.wsgi.application"'"
settings="${project_name}.settings"

sed  -i "s/ROOT_URLCONF = 'taskbuster.urls'/ROOT_URLCONF = ${urls}/g" \
    ${project_dir}/${project_name}/settings/base.py
sed  -i "s/WSGI_APPLICATION = 'taskbuster.wsgi.application'/WSGI_APPLICATION = ${wsgi}/g" \
    ${project_dir}/${project_name}/settings/base.py

sed -i 's/os.environ.setdefault("DJANGO_SETTINGS_MODULE", "taskbuster.settings")/os.environ.setdefault("DJANGO_SETTINGS_MODULE","'${settings}'")/g' \
        ${project_dir}/${project_name}/wsgi.py

sed -i 's/os.environ.setdefault("DJANGO_SETTINGS_MODULE", "taskbuster.settings")/os.environ.setdefault("DJANGO_SETTINGS_MODULE","'${settings}'")/g' \
                ${project_dir}/manage.py


workon ${env_prefix}_dev
$pip install -r ${project_dir}/requirements/development.txt
deactivate

workon ${env_prefix}_test
$pip install -r  ${project_dir}/requirements/testing.txt
deactivate

mv  ${project_dir}  .. #
