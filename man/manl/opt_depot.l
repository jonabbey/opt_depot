.TH OPT_DEPOT l "10 July 1997" "ARL:UT/CSD"
.SH NAME
opt_depot 2.01 \- creates a directory structure with links to packages under a "depot" directory
.SH SYNOPSIS
.B opt_depot
[
.B -vnqmr
] [
.BI -d directory
] [
.BI -l directory
]
.RS
[
.BI -b directory
]
.SH ARGUMENTS
.TP
.B -v
verbose mode.
.TP
.B -n
test mode.  No action will actually occur while run information is
output to the screen.
.TP
.B -m
rebuild manpage index after making any changes to the man subdirectory,
using the catman program.  The command to run catman is defined inside
the opt_depot script and may be changed there.
.TP
.B -q
quiet mode.  Logging will be turned off.
.TP
.B -r
enable recursion. opt_depot will be able to solve package conflicts by merging
directories recursivly.
.TP
.BI -d directory
sets the "depot" directory (i.e. the directory to be searched)
.TP
.BI -l directory
set the location of the log directory
.TP
.BI -b directory
sets the software base directory
.RE
.SH DESCRIPTION
opt_depot is a script that creates a directory structure that contains 
links to packages under a "depot" directory (default is /opt/depot).  
It will create  the directories "bin", "lib", "man", etc. in a designated directory 
(default is /opt) and create links from these directories to the files under each 
package's "bin", "lib", "man", etc. directories.  This will allow the user to access the 
files for many different packages in one place and still keep the packages physically 
separate from each other.
.sp
opt_depot employs a lock file
.I (lock.opt_depot)
to prevent multiple runs on the same 
destination directory.  When a user runs 
opt_depot to link /opt to /opt/depot (i.e., /opt is the sofdtware base directory and 
/opt/depot is the depot directory) a lock file is created in /opt and is removed when 
the run is completed.  If the user cancels (hits control C) in the middle of the run or
an error occurs during the run then the user
should remember to remove the lock file from the software base directory.  
.sp
The software base directory is the last argument in the command line without 
any switches directly preceding it.  The default software base directory is 
/opt.  The directory must already exist; however, any required sub directories 
(i.e., "bin", "lib", "man", etc.) will be created if they do not exist.
.sp
Usually the user should not have to do much more than simply type "opt_depot" 
when updating /opt; however, there may be situations where one wants to change the software base directory, add
a couple of subdirectories to search, or link a different depot directory than /opt/depot. 
.sp
For example:
.RS
opt_depot -vq -d/opt/depot -shelp,etc /tmp/opt
.RE
will first make sure that the subdirectories of /tmp/opt exist (i.e. /tmp/opt/lib, /tmp/opt/man, 
/tmp/opt/bin, etc.), creating them if they don't, and then take the packages in /opt/depot (note that
the "-d/opt/depot" option is not necessary since /opt/depot is already the default directory and is 
included only for illustrative purposes), 
search the "lib", "man", "bin", and "include" directories in each package for files, and create links from /tmp/opt/lib, /tmp/opt/man, 
/tmp/opt/bin, etc. to the files found in the packages. 
.sp
opt_depot also uses two configuration files called .priority and .exclude, which should be placed in the 
software base directory. 
.sp 
.I .priority 
is a list of packages and package files in order of decreasing
priority.  This is to allow the user to specify which packages or
files are more important when name conflicts arise.  If two files
conflict then the priority list is searched. If either of the files or
directories containing them are found then a comparison is made to
determine which is of higher priority.  If a file or its package is
not contained in the priority list then it has the lowest priority.
If two files conflict and neither are found in the list then the first
one linked remains.  Files included in the list can either start with
the package name (e.g. opt_depot/bin/opt_clean) or be absolute
pathnames (e.g. /opt/depot/opt_depot/bin/opt_clean), or be the the
names of the packages themselves, if you want to assign relative
priority of all files in a pair of packages. Package names should be
the name of the package as listed under the "depot" directory and
should contain no slashes.  Comments may follow a pound sign placed at
the beginning of a line.
.sp
When opt_depot tries to resolve a conflict through the use of the .priority
file, it first checks to see if the files involved in the conflict are listed in
the .priority file.  If so, the priority of the file or files in the .priority
file are used to determine which individual file should be linked.  If neither
of the files at issue are listed in the .priority file, opt_depot will give
preference to whichever file is listed in a package or subdirectory of the
highest priority.  That is, if the file in question is /opt/depot/test/bin/file,
and a link to /opt/depot/old/bin/file is already in place in /opt/bin/file,
the old link will be removed if:
.sp
.br
.RS
1) test/bin/file or /opt/depot/test/bin/file is in the .priority file ahead of an entry for old/bin/file or /opt/depot/old/bin/file, if such exists
.RE
.sp
or
.sp
.RS
2) any directory in the tree containing /opt/depot/test/bin/file has a higher priority in the .priority file than all directories which contain /opt/depot/old/bin/file
.RE
.sp
The individual files' relative priorities, if listed, are considered before the priority of any containing directory or package.  
.sp
For example:
.RS
#this is a priority list
.br
/opt/depot/opt_depot/bin/opt_depot
.br
idl/bin/lmstat
.br
X11R6/man
.br
X11R5/man
.br
X11R5/man/manl/xterm.l
.br
gnuemacs-19.23
.br
gnuemacs-18.57
.RE
.sp
In the above example, X11R5/man/manl/xterm.l
.I
would
be given preference in linking, because it is a specific file.  In all other cases, the X11R6 man pages
would be given preference, because they are not specifically enumerated, and X11R6/man, which contains
the man pages, has a higher preference than X11R5/man.
.sp
If X11R5 had been listed above X11R6/man in the .priority file, then
X11R5's man pages would be linked.  opt_depot only looks at the
containing directory with the highest priority when deciding linkage
based on containing directories.
.sp
.I .exclude
is a list of packages and package files that should not be linked to the software base directory 
structure.  The format is the same as that for .priority.
.sp
In the case of package conflicts, opt_depot will recursively search the package's sub-directories for files that should be linked into the software base. If
two or more files are found that do not exclude one another, then physical su-directories are created under the software base and links to the files are placed in these directories. By doing so, opt_depot allows two or more packages to use files located in the same directory.
This feature may be diabled using the -r option.
.sp
By default, opt_depot will log the run in a file located in /logs/opt_depot, and, since the default
destination is /opt, a file there called "opt" will contain most of the logs; however, for destination directories
which have paths more than one level deep the corresponding log file name is derived from the absolute path name by 
replacing all but the first slash with a colon (e.g., /tmp/test/opt would be tmp:test:opt).  Logging can be turned 
off using the q (for quiet) switch.  The log directory can be changed using the -l"directory name" option.
.SH NOTE
All directory names should be absolute path names
.SH SEE ALSO
opt_clean(l), opt_nuke(l), opt_setup(l), opt_link(l)


