#!/bin/sh

# Copyright 2006 Michael Chaney Consulting Corporation
# All Rights Reserved
#
# 1. Get a list of all files on the source disk.  They will go into /music
#    on the new drive.  These go into source-files.yaml, which includes
#    information on the track and version
#
# 2. Get the list of all tracks, if necessary.
#
# 3. Show any missing music files.
#
# 4. Build xinfo, etc.

usage () {
	cat <<EOF >&2

Usage: ${0} [-t] [-r] msfiles.txt

	msfiles.txt must contain a directory listing of all files obtained on
	a windows system with the command "dir/w/b/s" ran in the root of the
	filesystem containing the music.

	-t - testing - don't create copyme directory and msfull.zip.
	-r - data refresh - force data refresh from web site.  Otherwise,
			data is retained for 12 hours.
EOF
	exit 1
}

exerr () { echo -e "$*" 1>&2 ; exit 1; }

while getopts ":tr" opt; do
	case $opt in
		t ) testing="true" ;;
		r ) refresh_data="true" ;;
		\? ) usage
	esac
done

shift $(($OPTIND - 1))

if [ $# -lt 1 ]; then
	usage
fi

msfiles="${1}"

[ -f "${msfiles}" ] || exerr "File list \"${msfiles}\" does not exist :\("

export TERM=dumb
export SCRIPT_DIR=$( cd $( dirname $0 ) ; pwd )
export PATH=/opt/local/bin:/opt/local/sbin:$PATH:$SCRIPT_DIR

parsed_file_list="source-files.yaml"

cd "${SCRIPT_DIR}" || exerr "Cannot cd to script directory"

# Clean out old directories, make new ones
echo Cleaning out old directories >&2
rm -rf build/ idx/ xinfo/ main.idx.txt lyrics.idx.txt || exerr "Cannot remove old files."
mkdir -p build/lyrics build/main/ idx/lyrics idx/main xinfo || exerr "Cannot write to temp directory"

if [ "${refresh_data}" ]; then
	echo "Getting all tracks, this will take a few minutes..." >&2
	ms-tracks.rb --debug || exerr "Couldn't get all files"
fi

find . -maxdepth 1 -a -name "${parsed_file_list}" -a \! -cnewer "${msfiles}" -delete

if [ ! -s "${parsed_file_list}" ]; then
	echo Getting list of audio files >&2
	parse_msfiles.rb --verbose <"${msfiles}" > "${parsed_file_list}"
fi

# Find out if we have a wav file for each track
echo Performing file check >&2
./file-check.rb --files "${parsed_file_list}"
[ $? -eq 1 ] && exerr "You need to find those missing files before we can continue..."

# Create the xinfo.js file
echo Creating main xinfo.js >&2
./make_xinfo.rb --files "${parsed_file_list}" >../htdocs/js/xinfo.js || exerr "Cannot create xinfo file."

# Create the xsort.js file
echo Creating main xsort.js >&2
./make_xsort.rb >../htdocs/js/xsort.js || exerr "Cannot make xsort file."

# Create the dd_search_strings.js file
echo Creating dd_search_strings.js >&2
./make_dd.rb >../htdocs/js/dd_search_strings.js || exerr "Cannot create dd search strings."

# And all files in xinfo/
echo Creating individual xinfo/ files >&2
./make_xinfo_files.rb --files "${parsed_file_list}" || exerr "Cannot create xinfo files."

# Make lyrics files
echo Creating lyrics files for indexing >&2
./build_lyrics.rb  || exerr "Cannot build lyrics index."

# Make main files
echo Creating main files for indexing >&2
./build_main.rb || exerr "Cannot build index."

# Index the lyrics
echo Indexing lyrics >&2
./idxwords.pl build/lyrics >lyrics.idx.txt || exerr "Cannot index lyrics words."
./idxbtree.pl idx/lyrics lyrics.idx.txt || exerr "Error building lyrics btree."
rm -rf ../htdocs/idx/lyrics || exerr "Cannot remove old lyrics index structure."
mv idx/lyrics ../htdocs/idx/ || exerr "Cannot move lyrics index to htdocs."

# Index the main items
echo Indexing main >&2
./idxwords.pl build/main >main.idx.txt || exerr "Cannot index main words."
./idxbtree.pl idx/main main.idx.txt || exerr "Error building main btree."
rm -rf ../htdocs/idx/main || exerr "Cannot remove old main index structure."
mv idx/main ../htdocs/idx/ || exerr "Cannot move main index to htdocs."

# And put the xinfo files in the main directory
echo Adding xinfo files >&2
rm -rf ../htdocs/xinfo/ || exerr "Cannot remove old xinfo stuff in htdocs."
mv xinfo ../htdocs/ || exerr "Cannot move new xinfo to htdocs."

# Get missing cover images
echo Updating cover images >&2
./get-covers.rb --verbose ../htdocs/images/covers || exerr "Cannot get cover images."

if [ ! "${testing}" ]; then
	echo Copying to copyme directory 1>&2

	# Copy the search engine to "copyme" directory, sans svn stuff
	cd ../
	if [ -d copyme ]; then
		rm -rf copyme/
	fi
	mkdir copyme
	cd htdocs/
	tar --exclude .svn --exclude .DS_Store -cf - * | (cd ../copyme/ ; tar xf -)
	cd ../copyme/ || exerr "Cannot get into copyme directory."
	cp index.html 'Search Engine.html'

	echo Zipping 1>&2

	# zip it up
	rm ../msfull.zip
	zip -q -r ../msfull.zip autorun.inf *.html css/ firefox/ idx/ images/ js/ xinfo/ -x \*/.svn \*/.svn/\* \*/.DS_Store

fi

# Finally, clean up the remaining temp files directory
cd ../work/
rm -rf build idx main.idx.txt lyrics.idx.txt || exerr "Cannot clean up :("

