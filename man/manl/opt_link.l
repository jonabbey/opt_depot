.\" -*- nroff -*-
.\"
.\" opt_link
.\"
.\" Copyright (C) 1993-2003 The University of Texas at Austin.
.\"
.\" Contact information
.\"
.\" Author Email: opt-depot@arlut.utexas.edu
.\" Email mailing list: opt-depot-users@arlut.utexas.edu
.\"
.\" US Mail:
.\"
.\" Computer Science Division
.\" Applied Research Laboratories
.\" The University of Texas at Austin
.\" PO Box 8029, Austin TX 78713-8029
.\"
.\" This program is free software; you can redistribute it and/or modify
.\" it under the terms of the GNU General Public License as published by
.\" the Free Software Foundation; either version 2 of the License, or
.\" (at your option) any later version.
.\"
.\" This program is distributed in the hope that it will be useful,
.\" but WITHOUT ANY WARRANTY; without even the implied warranty of
.\" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
.\" GNU General Public License for more details.
.\"
.\" You should have received a copy of the GNU General Public License
.\" along with this program; if not, write to the Free Software
.\" Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
.\" 02111-1307, USA
.\"
.\" Written by: Computer Science Division, Applied Research Laboratories,
.\" University of Texas at Austin  opt-depot@arlut.utexas.edu
.\"
.\" Release: $Name:  $
.\" Version: $Revision: 1.5 $
.\" Last Mod Date: $Date: 2003/10/21 00:25:16 $
.TH OPT_LINK l "15 October 2003" "ARL:UT/CSD"
.SH NAME
opt_link 3.0 \- creates and manages links from a system depot directory to packages located in one or more central package archive directories.
.SH SYNOPSIS
\fBopt_link\fR [\fB-asqvng\fR] [\fB-f\f(BI config file\fR] [\fB-d\f(BI directory\fR] [\fB-l\f(BI path\fR] [\fB-b\f(BI directory\fR]
.SH ARGUMENTS
.TP
\fB-a\fR add only
If set, \fBopt_link\fR will only add, not remove, links from the depot directory to site volume packages.
.TP
\fB-s\fR inhibits lock creation.
Used to allow \fBopt_setup\fR to handle locking when running several scripts in sequence.
.TP
\fB-v\fR verbose mode.
.TP
\fB-n\fR test mode.
When \fB-n\fR is set, \fBopt_link\fR will print out a list of actions that it would take if \fB-n\fR had not been set, without actually performing them.
.TP
\fB-q\fR quiet mode.
Disables logging to disk.  Only necessary if a log file/directory is specified in the configuration file.
.TP
\fB-g\fR get_most_recent
When this option is selected, \fBopt_link\fR will allow exclusions to occur
regardless of the priority of the archive where a package is
located. For example, a version of emacs-19.33 which excludes
emacs-19.30 would be installed even if it resided on a lower priority
site volume than emacs-19.30.
.TP
\fB-f\f(BI config file\fR sets the location of the "\fIopt.config\fR" configuration file
.TP
\fB-d\f(BI directory\fR sets the "depot" directory (i.e. the directory to be searched for packages)
.TP
\fB-l\f(BI directory\fR set the location of the log directory/file
.TP
\fB-b\f(BI directory\fR sets the Base directory for \fBopt_link\fR
.SH DESCRIPTION
\fBopt_link\fR is a companion to the \fBopt_depot\fR script.  While
the \fBopt_depot\fR and \fBopt_clean\fR scripts are concerned with the
creation and deletion of symbolic links under a set of deployment
directories (\fI__BASEDIR__/bin\fR, \fI__BASEDIR__/lib\fR, and etc.),
\fBopt_link\fR is responsible for linking packages into the system
depot directory (\fI__DEPOTDIR__\fR) from one or more potentially
remote package archives.
.sp
\fBopt_link\fR makes it possible for a set of client systems to
automatically update themselves with new packages published on one or
more centralized NFS file servers.  When \fBopt_link\fR runs, it
consults a \fBsites\fR file which provides an ordered list of package
archives and the filesystem path where each is located.
\fBopt_link\fR then scans the package archives and links them into the
system depot directory, making the contents of the packages
available for the \fBopt_depot\fR script to link.
.sp
The key to this process is that all packages compiled for use with the
\fBopt_depot\fR suite are configured to be installed under the system
depot directory.  If a package in a package archive directory is named
\fIemacs-19.35\fR, for instance, it should have been configured to run
under the standard depot directory (\fI__DEPOTDIR__/emacs-19.35\fR).  This
property of the package makes it position indepdent, so long as a symlink
exists from the canonical location to the physical location of the package.
This is what \fBopt_link\fR does.
.sp
\fBopt_link\fR uses a file called 'sites' (as specified in the \fIopt.config\fR file)
to determine the directories that will serve as the archive directories.
The file is in a plain text format, with each line containing a
central package archive listing, in the form of: <label> <directory>.
The directory portion of the entry is the absolute pathname of the
archive (i.e. \fI/v/site/packages\fR) and the label portion is the
name that will be associated with the archive (i.e. \fIGLOBAL\fR,
\fILocal_packs\fR, \fIfred\fR, etc.).
.sp
The order in which the package archives are listed in the sites file
determines the priority of each package archive, with the archives
listed first being given priority over the others. Normally, a package
cannot exclude another package that is contained in a higher priority
archive, although if the -g get_most_recent option is selected then
any package can exclude any other package, regardless of the priority
of the archive where it resides.
.SH MANUAL EXCLUSIONS
\fBopt_link\fR contains a lot of logic to help control what packages
are linked into the depot directory.
Users on individual workstations can specify packages to be excluded
using the same \fI.exclude\fR file (by default
\fI__BASEDIR__/.exclude\fR) that the \fBopt_depot\fR and
\fBopt_clean\fR scripts use.
The \fI__BASEDIR/.exclude\fR file simply consists of a set of file
or package names to be excluded, one per line, with empty lines and
pound comments ignored.
Any line that does not contain embedded slashes is taken to be a package
name, and all packages of that name will be excluded from being linked
into the depot directory.
In addition, the \fI__BASEDIR__/.exclude\fR file may be used to
exclude packages from a particular site volume, by prepending the
package name with the site volume label (as specified in the
\fIsites\fR file) followed by a colon.



\fBopt_link\fR can also handle the removal of old and outdated symbolic links
from the depot directory.
In this way, \fBopt_link\fR is capable of working with the maintainer of a
centralized package archive to keep distributed workstations up-to-date with
centrally installed software.
.sp
There are two places that \fBopt_link\fR
Creating symbolic links from the system depot directory to 
Like \fBopt_depot\fR and \fBopt_clean\fR, \fBopt_link\fR supports the use
of certain text files
.sp
When specifying an exclusion in the \fI__BASEDIR__/.exclude\fR file, a
package specific to a particular package archive may be excluded by
specifying the label of the archive along with the excluded
package. The entry in the \fI__BASEDIR__/.exclude\fR file for a
labeled exclusion takes the form of <label>:<package>. An example of a
site specific exclusion might be GLOBAL:netscape-1.0, which would
exclude the netscape-1.0 which resides in the archive associated with
the GLOBAL label only.
.sp
\fBopt_link\fR reads the standard \fBopt_depot\fR .exclude file, as well as 
individual .exclude files present in the packages themselves.
.sp
.SH NOTE
All directory names should be absolute path names.
.SH SEE ALSO
opt_depot(l) opt_setup(l)
