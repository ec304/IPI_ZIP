# About
This tool is supposed to help with formatting and arranging files as required for the IPI Exercises 2025
## File Cleanup and Checking
For .py files, it runs them through autopep8 and flake8 (though you should use a linter and formatter in your editor to use this tool to its full potential, instead of relying on it), shows you the differences between that version and your input and optionally strips out specially formatted comments for communication with your group members (this feature might not work reliably and you should rather use our file filtering tool)
For .md files it uses mdformat-myst to enable LaTeX (technically KaTeX) as well as normal Markdown styling. It even uses cbfmt to use the python formatters on code blocks within markdown files
## File Filtering and Arranging (Subfolder Flattening)
You can specify file patterns to be excluded from shipping in the exclude.lst files. This allows you to keep old (.old) versions of your files by default, and by adding names as suffixes to create and synchronise different members versions for comparison and reference, without sending them in your "production" code.
Since all files are supposed to be in the root of the archive file, but I prefer order, we also added flattening of subfolders matching specific patterns:
Your directory should be comprised of this script, its dependencies and configs, and folders for each set of exercises. It is intended for these folders to be named either just the Number (i.e. 1/ for the first group) or Z1 (Zettel 1), to make Tab Completion more comfortable.
Within each Folder, you can either have all your documents laid out, or have subfolders per exercise. These may be just the exercise number (1) or a decimal style numbering (1.1). These will all be flattened into the root of the archive. Any directories not matching this pattern (not beginning with a number), will not be flattened, in case an exercise requires a folder. Sub-Subfolders will also remain unchanged.
## Automatic Zipping
Of course, the script creates a .zip file for submission. It automatically populates it with the files (excluding any files matching the patterns in exclude.lst), the `mitglieder.txt`, and name the zip file as required using the names in mitglieder.txt.

# Dependencies
Needed packages: isutf8 from moreutils, autopep8, flake8, cbfmt, mdformat (myst flavour) (technically all of them may be removed but this script is most useful with all of them)
Install on debian based systems: 
sudo apt install -y moreutils python3-autopep8 flake8 pipx cargo; pipx install mdformat; pipx inject mdformat mdformat-myst; cargo install cbfmt

