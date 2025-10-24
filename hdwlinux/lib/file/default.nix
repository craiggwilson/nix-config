{
  withConfirmOverwrite = file: script: ''
    out=${file}
    if [ -f $out ]; then                                                                                               
        read -rp "File $out already exists, overwrite it? (Y/n): " input
        if [[ $input =~ ^no?$ ]]; then 
            exit 2
        fi
    fi 

    ${script}
  '';
}
