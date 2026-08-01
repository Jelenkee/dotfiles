for path in $(mise doctor path); do
	for file in $(ls $path); do
		if [ ! -e "${HOME}/.local/bin/${file}" ]; then
			#ln -s "${path}/${file}" "${HOME}/.local/bin/${file}"
            true
		fi
	done
done
mise doctor path | while read path; do
    #echo $path
done