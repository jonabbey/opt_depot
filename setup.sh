#!/bin/sh
#
# This is the bootstrapping configuration script for opt_depot. The
# only thing we count on to run this script is that /bin/sh works.
#
# Get enough information from the user to be able to find Perl 5
#
# Release: $Name:  $
# Version: $Revision: 1.2 $
# Last Mod Date: $Date: 2003/07/07 21:22:26 $
#
###############################################################################

# 
# Figure out how to do an echo without trailing newline
#

case "`echo 'x\c'`" in
'x\c')  echo="echo -n"   nnl= ;;       # BSD 
x)      echo="echo"      nnl="\c" ;;   # Sys V
*)      echo "$0 quitting: Can't set up echo." 1>&2; exit 1 ;;
esac

#
# Let the games begin
#

echo
echo "## opt_depot setup shell version 1.0 ##"
echo
echo "Searching for 'perl'..."
echo

# Find perl (GPERL)

perl_loc=`which perl5`
perl_name="perl5"

if test ! -r "$perl_loc"; then
  perl_loc=`which perl`
  perl_name="perl"
fi

if test ! -r "$perl_loc"; then
  perl_loc = "no"
fi
  
if [ $perl_loc = "no" ]; then 
  echo "Perl has been located in $perl_loc under the name: $perl_name"	
  echo "### The following is pertinent perl version information ###"
  $perl_loc -v   # this call to perl prints out the version info needed
  echo "###########################################################"
  echo
  echo "Note - The version of perl must be 5.000 or greater to use opt_depot" 
  echo
  echo "Do you wish to use this copy of Perl? [Y/N]"
  $echo "----> {$nnl}"
  read answer
  echo
else
  echo "Perl not found"
  echo
  answer=N
fi

if [ $answer = y ]; then 
  answer="Y"
fi

if [ $answer != Y ]; then
  echo "Please enter the name of the Perl 5 version you are using"
  echo "and its location (ie /usr/local/bin/perl) " 
  $echo "----> {$nnl}"
  read perl_loc
	
  if [ -f "$perl_loc" ]; then 
    echo "perl found"
  else 
    echo "The file $perl_loc was not located"
    echo "Please check the filename and location and try again"
    exit	
  fi
fi

echo
echo "The following line will be added to the opt_depot scripts:"
echo "#!$perl_loc"

$perl_loc scripts/install.pl  -IGetopt $perl_loc
if [ -f "opt.config" ]; then  
  $perl_loc scripts/modify_archives 
else
  exit
fi

echo " "
$perl_loc scripts/opt_copy $perl_loc
 

