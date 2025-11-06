#!/bin/sh

# LARS: wenn dein shellcheck failed, mach ihn am besten ganz aus. Ansonsten kannst du einfach die Shell Selection entfernen, den shebang zurück auf #!/bin/bash setzen, und dann "git update-index --assume-unchanged zip.sh", dann ignoriert git deine lokalen Änderungen (außer es gibt eine Änderung Upstream, dann manuelles merge)

# needed packages: isutf8 from moreutils, autopep8, flake8, cbfmt, mdformat (myst flavour) (nix: mdformat-wrapped)
# install on debian based systems: 
#sudo apt install moreutils python3-autopep8 flake8 pipx cargo; pipx install mdformat; pipx inject mdformat mdformat-myst; cargo install cbfmt
# You may skip cbfmt and mdformat (plus dependencies like cargo and pipx) but you have to manually remove the calls to those in the find commands below. I would strongly advise against ignoring the other tools but again you can remove them from the find commands

if [ -n "$ZSH_VERSION" ] || [ -n "$BASH_VERSION" ] || [ -n "$KSH_VERSION" ]; then # test if we are using either bash, ksh or zsh already
	:
else # if not, find a compatible shell
	if command -v zsh >/dev/null; then 
			exec zsh "$0" "$@"
	elif command -v bash >/dev/null; then
			exec bash "$0" "$@"
	elif command -v ksh >/dev/null|| command -v mksh >/dev/null; then
			exec ksh "$0" "$@"
	else
		echo Needs a bash compatible shell. ZSH is suggested.
	fi
fi

ZETTEL="$1" # Get Folder name from first argument
ZETTELINDEX="${ZETTEL/#Z/}" # Transform into Index by removing Z
WORKING_DIR="./.tmp"

FOLDERNAME="_$(cut -d "," -f 1 mitglieder.txt|sed -z -e 's/\n/_/g' -e 's/_$//')" # Extract Folder Name from mitglieder.txt and convert it into required format


if [ -z "$ZETTEL" ]; then
	echo "Missing Folderpath! (Needs to be \"Z\" + No. of the Zettel). See Readme -> Folderstructure"
	exit 1
fi
if [ -f "$ZETTEL"$FOLDERNAME.zip ]; then # If the zip already exists, deal with it. Previously we just deleted it, but it seems prudent to keep at least one copy as backup
	mv "$ZETTEL"$FOLDERNAME.zip  ."$ZETTEL"$FOLDERNAME.zip.old
fi


rm -rf "$WORKING_DIR" # Clean up the temp dir if it wasn't deleted before (script crash). Uses -f just to not throw an error if it doesn't exist. Other ways to suppress such an error do not stop shellcheck
mkdir "$WORKING_DIR" # This would again fail if the dir existed. Either way, we need a clean working dir
cp -r "$ZETTEL"/* "$WORKING_DIR"/ # Copy all files into the working dir with structure
cp ./mitglieder.txt "$WORKING_DIR"/ # Copy the global mitglieder.txt into our working dir

cd "$WORKING_DIR"


find . -type d -name "__pycache__" -exec rm -rf {} \; # Delete pycache files
find . -type d -name ".pytest_cache" -exec rm -rf {} \; # Delete pytest cache files

find . -type f -exec sh -c "isutf8 {} || echo UTF-8 Error in {}" \; # Check for valid utf8 (for positive output: && echo Valid UTF-8 )

find . -name "*.py" -exec sed -i '/#--/,/#--/{d;}' {} \; -exec autopep8 -i {} \; -exec flake8 {} \; -exec diff --color=auto -u --minimal ../"$ZETTEL"/{} {} \; # [First we remove comments, though i implore you to not use them in source code files because this might not be stable. Due to our syntax, it should never accidentally trigger. If it does, please raise an Issue in our github. Then] autopep, flake and diff all py files against sources -> fix any remaining errors (Just use Linters and Formatters), check it again (even though it should never find an error after autopep), then show the differences. This prevents hidden changes and allows you to ensure no changes are made that change the logic.

find . -name "*.md" -exec sed -i '/--#/,/--#/{d;}' {} \; -exec cp {} {}.old \; -exec mdformat {} \; -exec cbfmt -w {} \; -exec diff --color=auto -u --minimal {}.old {} \; # remove comments from markdowns, then use mdformat both to format it, and also clean up whitespace errors from the comment removal
# The command -exec sed -i 's/\\\\/\\/g' {} \; was previously used after mdformat to un-escape backslashes in LaTeX. Since we are using mdformat-myst now this is no longer necessary.
# cbfmt is used to apply our usual formatters to any code blocks with specified language. (Markdown Syntax technically only considers a ``` 3-tick code block valid with specified language. Also, python is used regardless of version. Inline Code is not affected). If cbfmt does not interact with a file at all, it will print [Same], 0/1 files written, don't be confused, this is not an error.


for dir in */; # unpack subfolders because some people do not follow logical ordering conventions...
do
	dir="${dir%/}" # remove trailing slash from */ match
	if [[ "$dir" =~ ^k[0-9]+(\.[0-9]+)*[a-zA-Z0-9]*$ ]] # if folder is prefixed with k, keep it but remove the k
	then
		mv $dir "${dir/#k/}"
	elif [[ "$dir" =~ ^[0-9]+(\.[0-9]+)*[a-zA-Z0-9]*$ ]] # Matches Subdirs that are only in the Form of Number... or Number.Subnumber... . However it is not intended for Subdirs to have any other name than 1.1 2.3 etc. If a subdir does not start with a number, we expect it to be intentionally placed (maybe due to requirements in the specific exercise) and do not interact with it
	then
		cp -r "$dir"/* .
		rm -r "$dir"
	fi
done


zip -r ../"$ZETTELINDEX"$FOLDERNAME.zip ./* -x@../exclude.lst # Zip all files excluding the ones in our exclude.lst. Add any temp or versioning syntax you use like .[name] suffixes for different approaches. By default only .old files are ignored. Prefer this over comments within source code files.

cd ..
rm -r "$WORKING_DIR"
