.TH OPT_LINK l "10 July 1997" "ARL:UT/CSD"
.SH NAME
opt_link 2.01 \- creates links from a single depot directory to packages located in one or more central package archive directories.
.SH SYNOPSIS
.B opt_link
[
.B -vqg
]
[
.BI -l directory
]
[
.BI -b directory
]
.RS
[
.BI -d directory
] 
.SH ARGUMENTS
.TP
.BI -l directory
sets the log file directory
.TP
.BI -b directory
sets the software base directory (i.e. /opt) - this is where opt_link will look for .exclude
.TP
.BI -d directory
sets the depot directory
.TP
.B -q
quiet mode.  Logging will be turned off.
.TP
.B -v
verbose mode
.TP
.B -g 
get_most_recent.  When this option is selected, opt_link will allow exclusions to occur regardless of the priority of the archive where a package is located. For example, a version of emacs-19.33 which excludes emacs-19.30 would be installed even if it resided on a lower priority site volume than emacs-19.30.
.TP
.BI -d directory
changes the destination directory (default is /opt/depot)
.SH DESCRIPTI0N
opt_link is a companion to the opt_depot script.  Given the location of a central package archive (where packages are physically stored), opt_link 
will construct links to all the directories in that site from a depot 
directory.  The directories should be packages containing one or more of a
list of subdirectories used by opt_depot (e.g. "bin", "lib", "man", etc.).
.sp
The idea behind opt_link is to allow programs to loaded anywhere, while being accessed through a known location. Programs can be compiled with this path hard coded. Opt_link makes a symlink from the hard coded location (i.e. /opt/depot/emacs-19.35) to wherever the package is physically installed (i.e. /v/site/packages/emacs-19.35). 
.sp
opt_link uses a file called 'sites' to determine the directories that will 
serve as the archive directories. The file is in a plain text format, with each line containing a central package archive listing, in the form of: <label> <directory>. The directory portion of the entry is the aboslute pathname of the archive (i.e. /v/site/packages) and the label portion is the name that will be associated with the archive (i.e. GLOBAL, Local_packs, fred, etc.). 
.sp
The order in which the package archives are listed in the sites file determines the priority of each package archive, with the archives listed first being given priority over the others. Normally, a package cannot exclude another package that is contained in a higher priority archive, although if the -g get_most_recent option is selected then any package can exclude any other package, regardless of the priority of the archive where it resides.
.sp
When specifying an exclusion in the .exclude file, a package specific to a particular package archive may be excluded by specifying the label of the archive along with the excluded package. The entry in the .exclude file for a labeled exclusion takes the form of <label>:<package>. An example of a site specific exclusion might be GLOBAL:netscape-1.0, which would exclude the netscape-1.0 which resides in the archive associated with the GLOBAL label only.
.sp
Unless the -q option is specified on the command line, opt_link will append
information to the standard log file detailing actions taken.  This log
file is named /logs/opt_depot/opt by default.  The directory may be changed
by using the -l option.  The name of the log file by default is the
path to the depot directory (/opt/depot by default), with the "/depot"
part removed.  Any remaining slashes will be replaced with colons.
.sp
For instance, if the depot directory were located in /usr/local/depot, the
default log file would become /logs/opt_depot/usr:local.  If the
-l option specified /usr/local/logs/opt_depot, the log file would then become
/usr/local/logs/opt_depot/usr:local.
.sp
opt_link reads the standard opt_depot .exclude file, as well as 
individual .exclude files present in the packages themselves.
.sp
.SH NOTE
All directory names should be absolute path names.
.SH SEE ALSO
opt_depot(l) opt_setup(l)
