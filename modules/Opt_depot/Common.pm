#
# Opt_depot::Common.pm
#
# Perl module to provide common functionality used by the various
# opt_depot scripts, including link handling logic, directory filename
# operations, and configuration file parsing.
#
#************************************************************************
#
# Copyright (C) 2003  The University of Texas at Austin.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
#    02111-1307, USA
#
#    Written by: Computer Science Division, Applied Research Laboratories,
#    University of Texas at Austin  opt-depot@arlut.utexas.edu
#
#***********************************************************************
# Written by Jonathan Abbey
# 23 July 2003
#
# Release: $Name:  $
# Version: $Revision: 1.1 $
# Last Mod Date: $Date: 2003/07/25 02:25:57 $
#
#####################################################################

package Opt_depot::Common;

use Text::ParseWords;

use vars qw($VERSION @ISA @EXPORT $PERL_SINGLE_QUOTE);
$VERSION="2.02";

require 5.000;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw($dest $depot $logdir %switches @subdirs @unify_list
	     LOG
	     logprint dircheck extractdir removelastslash resolve read_prefs
	    );
@EXPORT_OK = qw();

# declare our package globals that we're not exporting

our $usage_string;
our CONFIG;
our $log_init;
our LOG;

#########################################################################
#
#                                                                init_log
#
# input: $appname
#
# uses: $logdir $dest %switches package globals
#
# This function handles initialization of the log file if the %switches
# hash doesn't contain q.
#
# Note that because this function depends on a bunch of package globals,
# it needs to be called after read_prefs().
#
#########################################################################
sub handleinit {
  my ($appname) = @_;

  my ($buf, @dest, $log);

  # name log file, with colons separating the path of the log target

  @dest= split (/\//, $dest);
  shift(@dest);
  $log = "$logdir/" . join(':',@dest)

  # open log file and time stamp entry

  if (!($switches{'q'})) {
    open (LOG, ">> $log") || die "Could not open $log";
    print (LOG "\n\n**$appname**  ");
    ($sec, $min, $hour, $mday, $mon, $year)= localtime(time);
    $mon=$mon + 1;
    print (LOG "$hour:$min:$sec  $mon\/$mday\/$year\n");
  }
}


#########################################################################
#
#                                                               close_log
#
# input:
#
# uses:
#
# This function closes the log file if the %switches hash doesn't
# contain q.
#
#########################################################################
sub close_log {
  close (LOG) if (!($switches{'q'}));
}

##########################################################################
#
#                                                                 logprint
#
# input: $str - A string to print and/or log
#        $level - A numeric value.. if 0, print to stdout only on
#                 -v being set.  If not 0, print regardless of
#                 the presence or absence of -v
#
##########################################################################
sub logprint {
  my ($str,$level) = @_;

  if ($level || $switches{'v'}) {
    print $str;
  }

  if (!($switches{'q'})) {
    print LOG $str;
  }
}

#########################################################################
#
#                                                                dircheck
#
# input: a pathname to test
#
# this function will trigger an exit if the parameter is not
# a directory.
#
#########################################################################
sub dircheck {
  my($dir) = @_;

  if (!(-d $dir)){		
    logprint("$dir is not a directory", 1);
    exit(0);
  }
}

#########################################################################
#
#                                                              extractdir
#
# input: $filepath, a string containing a fully qualified path, terminating
#        in a filename
#
# output: a string containing just the directory from $filepath
#
#########################################################################
sub extractdir {
  my ($filepath) = @_;

  my (@comps);

  @comps =split(/\//, $filepath);
  pop @comps;

  return join('/', @comps);
}

#########################################################################
#
#                                                         removelastslash
#
# input: a pathname to test
#
# this function will remove a trailing slash from the directory name
# input
#
#########################################################################
sub removelastslash {
  if ($_[0] =~ /\/$/) {
    chop $_[0];
  }
}

#########################################################################
#
#                                                                 resolve
#
# input: $dir - absolute pathname of current directory
#        $link - string containing the readlink() results for a
#                symbolic link in $dir to be processed
#
# returns: absolute pathname of the target of the symbolic link
#
#########################################################################
sub resolve {
  my($dir, $link) = @_;

  my(@alinkp, $d, $alinkp);

  # make array representations of
  # the current directory and symbolic link

  # if we have a leading / in our $dir or $link,
  # we'll need to shift to get rid of the leading
  # empty array element

  @dirp=split(/\//, $dir);
  shift(@dirp) if (!($dirp[0]));

  @linkp=split(/\//, $link);
  shift(@linkp) if (!($linkp[0]));

  # @alinkp is an array that we will build to contain the absolute
  # link target pathname.  If the link does not begin with a /, it is
  # a relative link, and we need to place our current directory into
  # the @alinkp array.

  if ($link !~ /^\//) {
    @alinkp=@dirp;
  }

  # modify the @alinkp array according
  # to each path component of the @linkp array
  # (an array representation of the symbolic link
  # given to us), to arrive at the ultimate absolute
  # pathname of the symbolic link

  $d = shift(@linkp);

  while ($d) {
    if ($d eq "..") {
      pop(@alinkp);
    } elsif ($d ne ".") {
      push(@alinkp, $d);
    }

    $d=shift(@linkp);
  }

  $alinkp = "/".join('/',@alinkp);

  return $alinkp;
}

##########################################################################
#
#                                                               read_prefs
#
# The idea of read_prefs is to create a single function which can be called
# by the various opt scripts which would process command line arguments
# and the configure file.. ?
#
# input: $usage_str, $default_config_file, $switchlist, @ARGV
#
# $usage_str is a textual message describing the proper command line
# parameters we're expecting.  The $default_config_file should be the
# initial location to look in for the opt.config file.  The
# $switchlist string should be a concatenation of the permissible
# single-character command line flags.  %prefs should be a hash to
# load preference data into, and @ARGV should be the command line
# argument vector.
#
# output: the exported $dest, $depot, $logdir, %switches, @subdirs, and
# @unify_list variables are loaded from the given configuration file (or
# whatever configuration file is specified using the -f argument in @ARGV)
#
##########################################################################

sub read_prefs ($$$\@) {
  my ($usage_str, $default_config_file, $switchlist, $ARGV_ref) = @_;

  my ($cmd_config_file, $cmd_depot, $cmd_dest, $cmd_logdir);

  $usage_string = $usage_str;

  # first see if we have a config file override on the command line

  $cmd_config_file = find_arg('f', $$ARGV_ref);

  if ($cmd_config_file) {
    if (-r $cmd_config_file) {
      $config_file = $cmd_config_file;
    } else {
      die "Can't find/read $cmd_config_file";
    }
  } else {
    $config_file = $default_config_file;
  }

  # read the config file

  read_config($config_file);

  # if we didn't get an explicit -f config file specifier on the
  # command line, look to see if we have an auxiliary config file
  # located under $dest

  if (!$cmd_config_file && -e "$dest/opt.config") {
    read_config("$dest/opt.config");
  }

  # now for final after-the-fact command line overrides

  $cmd_depot = find_arg('d',$$ARGV_ref);

  if ($cmd_depot) {
    removelastslash($cmd_depot);
    dircheck($cmd_depot);
    $depot = $cmd_depot;
  }

  $cmd_dest = find_arg('b', $$ARGV_ref);

  if ($cmd_dest) {
    removelastslash($cmd_dest);
    dircheck($cmd_dest);
    $dest = $cmd_dest;
  }

  $cmd_logdir = find_arg('l', $$ARGV_ref);

  if ($cmd_logdir) {
    removelastslash($cmd_logdir);
    dircheck($cmd_logdir);
    $logdir = $cmd_logdir;
  }

  read_switches($switchlist, $$ARGV_ref);

  check_args($switchlist, $$ARGV_ref);
}

##########################################################################
#
#                                                              read_config
# input: $default_config_file, $switchlist
#
# output:
#
# This function reads the configuration file for the opt_depot scripts
# and sets global variables $dest, $depot, $logdir, @subdirs, @unify_list
# that are exported by this module.
#
##########################################################################
sub read_config {
  my ($file, $switchlist) = @_;

  open(CONFIG, "$config_file") || die "Could not open $config_file\n";

  while (<CONFIG>){
    if (/^Base:\s*(.*)/) {
      $dest = $1;

      if (($dest =~ /^\s*\"/) ||
	  ($dest =~ /^\s*\'/)) {
	$dest = parsequoted($dest);
      }
    }

    if (/^Depot:\s*(.*)/) {
      $depot = $1;

      if (($depot =~ /^\s*\"/) ||
	  ($depot =~ /^\s*\'/)) {
	$depot = parsequoted($depot);
      }
    }

    if (/^Log:\s*(.*)/) {
      $logdir = $1;

      if (($logdir =~ /^\s*\"/) ||
	  ($logdir =~ /^\s*\'/)) {
	$logdir = parsequoted($logdir);
      }
    }

    if (/^Subdirs:\s*(.*)/) {
      $dirs = $1;
      $dirs =~ s/^\s+//;
      $dirs =~ s/\s+$//;
      @subdirs = quoteword('\s+|,',0,$dirs); # from Text::ParseWords
    }

    if (/^Recurse:\s*(.*)/) {
      $rdirs = $1;
      $rdirs =~ s/^\s+//;
      $rdirs =~ s/\s+$//;
      @unify_list = quoteword('\s+|,',0,$rdirs); # from Text::ParseWords
    }
  }

  close(CONFIG);
}

##########################################################################
#
#                                                                 find_arg
# input: $token, @args
#
# output: the string argument following the single character
# $token.. for instance, if $token is 'f', find_arg will return the
# string following -f in the @args list, if it can be found.
#
# if the token can't be found following a dash character, an empty string
# will be returned.
#
#
##########################################################################

sub find_arg {
  my ($token, @args) = @_;

  my ($i, $word, $localword);

  $i = 0;
  $localword = "";

  while ($args[$i] =~ /^-(.*)$/) {
    $word=$1;
    $i = $i + 1;

    if ($word =~ /^$token/) {
      # redefine config file location

      if (length($word)==1) {
	$localword = $args[$i];
      } else {
	$word =~ /^$token(.*)$/;
	$localword = $1;
      }

      last;
    }
  }

  return $localword;
}

##########################################################################
#
#                                                            read_switches
# input: $switchlist, @args
#
# The $switchlist string should be a concatenation of the
# permissible single-character command line flags.
#
# output: sets flags in the global %switches hash
#
##########################################################################

sub read_switches {
  my ($switchlist, @args) = @_;

  my ($i, $word, @switches);

  $i = 0;
  $localword = "";

  while ($args[$i] =~ /^-(.*)$/) {
    $word=$1;
    $i = $i + 1;

    if ($word =~ /(^[$switchlist]+)$/) {
      @switches= split (//, $1);
      for $switch (@switches) {
	$switches{$switch}=1;
      }	
    } else {
      print "\"$word\" is an invalid command entry!\n";
      print $usage_string;
      exit 0;
    }
  }
}

##########################################################################
#
#                                                               check_args
# input: $switchlist, @args
#
# check_args runs through the argument array and makes sure that no
# parameters were given which shouldn't be there
#
##########################################################################

sub find_arg {
  my ($switchlist, @args) = @_;

  my ($i, $word);

  $i = 0;

  while ($i <= $#args) {
    if ($args[$i] =~ /^-(.*)$/) {
      $word=$1;
      $i++;

      if ($word =~ /^[fdbl]/) {
	# we've got one of the standard tokens which may permissibly
	# be followed by an argument string
	
	if (length($word)==1) {
	  # single char flag.. skip the next param, which is the
	  # argument for the flag
	  $i++;
	}
      } else if ($word !~ (^[$switchlist]+)$/) {
	# just a set of switch flags, no big deal either
      } else {
	print "\"$word\" is an unrecognized command line flag!\n";
	print $usage_string;
	exit 0;
      }
    } else {
      print "\"$word\" is an unrecognized command line flag!\n";
      print $usage_string;
      exit 0;
    }
  }
}

##########################################################################
#
#                                                              parsequoted
#
# input: $str
#
# This subroutine is designed to process a string that is surrounded by
# quotation marks, with proper escape handling
#
# output: the quoted string, minus the surrounding quotes
#
##########################################################################
sub parsequoted {
  my ($str) = @_;

  my $quoted = "";
  my $strcopy = $str;

  $strcopy =~ s/^\s+//;		# trim leading whitespace

  if ($strcopy =~ m/^(["'])((?:\\.|(?!\1)[^\\])*)\1/) {
    $quoted = $2;
    $quoted =~ s/\\(.)/$1/g;
  }

  return $quoted;
}
