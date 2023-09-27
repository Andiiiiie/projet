#!/bin/bash


# pull
git clone https://github.com/Andiiiiie/projet.git
cd ./projet


# find all java files and compile them
export TOMCAT_DIR=/opt/homebrew/Cellar/tomcat/10.1.13/libexec/
export TOMCAT_LIB="$TOMCAT_DIR"lib/*
export TOMCAT_WEBAPP="$TOMCAT_DIR"webapps
export CLASSPATH=./*:"$TOMCAT_LIB"

function compile {
  source_directory=$1
  out_directory=$2
  classpath=$3
  source_files=($(find "$source_directory" -type f -name "*.java")) # get all java files
  reminding_files=${#source_files[@]}
  while [ ${#source_files[@]} -ne 0 ]; do # while there are files to compile (boucle because of other class dependencies)
    for i in "${!source_files[@]}"; do
      # echo -cp "$classpath":"$out_directory" -d "$out_directory" "${source_files[i]}"
      javac -parameters -cp "$classpath":"$out_directory" -d "$out_directory" "${source_files[i]}" 2>compilation.log
      compilation=$(<compilation.log) # ignore error dependency
      if [ ${#compilation[0]} -eq 0  ]; then # remove compiled files
        unset "source_files[$i]"
      fi
    done
    if [ ${#source_files[@]} -eq "$reminding_files" ]; then # if no file has been compiled
      echo -e "${COLOR_RED}ERROR: Compilation failed due to unresolved dependencies or mistakes in the code ${COLOR_RESET}"
      cat compilation.log
      rm -rf compilation.log
      exit 1
    fi
    reminding_files=${#source_files[@]}
  done
  rm -rf compilation.log
}

compile ./java ./temp/WEB-INF/classes "$CLASSPATH"

# copy web app content
cp -R ./webapp/* ./temp/

# create jar
jar -cvf ./projet.jar -C ./temp .

# move webapp
mv projet.jar "$TOMCAT_WEBAPP"

# launch tomcat
"$TOMCAT_DIR"bin/catalina.sh stop
"$TOMCAT_DIR"bin/catalina.sh run

rm -rf ./temp
rm -rf projet.jar

