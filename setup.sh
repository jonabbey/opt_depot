echo
echo "## opt_depot setup shell version 1.0 ##"
echo
echo "Searching for 'perl5'..."
echo

# The following sequence of ugly commands is necessary to parse the 
# output from the which command in case perl isn't found.

which perl5 > opt_temp1 
sed  's/^no perl5 \(.*\)/no/' opt_temp1 > opt_temp2
perl_loc=`cat opt_temp2`
rm opt_temp1; rm opt_temp2
perl_name="perl5"


if [ $perl_loc = "no" ]
  then 
   echo perl5 not found
   echo
   echo "Searching for 'perl'..."
   echo
   which perl > opt_temp1 
   sed  's/^no perl \(.*\)/no/' opt_temp1 > opt_temp2
   perl_loc=`cat opt_temp2`
   rm opt_temp1; rm opt_temp2
   perl_name="perl"
fi
  
if [ $perl_loc != "no" ]
  then 
   echo "Perl has been located in $perl_loc under the name: $perl_name"	
   echo "### The following is pertinent perl version information ###"
   $perl_loc -v   # this call to perl prints out the version info needed
   echo "###########################################################"
   echo
   echo "Note - The version of perl must be 5.000 or greater to use opt_depot" 
   echo
   echo "Do you wish to use this copy of Perl? [Y/N]"
   cat scripts/opt_prompt1
   read answer
   echo
  else
   echo perl not found
   echo
   answer=N
fi

if [ $answer = y ]
then 
  answer="Y"
fi

if [ $answer = Y ]
 then
found="true"
else
  echo Please enter the name of the Perl 5 version you are using
  echo "and its location (ie /v/site/packages/perl-5.003/bin/perl5)" 
  cat scripts/opt_prompt1
  read perl_loc
	
if [ -f "$perl_loc" ] 
  then 
    echo perl found
  else 
    echo The file $perl_loc was not located
    echo Please check the filname and location and try again
    exit	
fi
fi

 echo
 echo "The following line will be added to the opt_depot scripts:"
 echo "#!$perl_loc"	 
 $perl_loc scripts/install.pl  -IGetopt $perl_loc
 if [ -f "opt.config" ] 
  then  
 $perl_loc scripts/modify_archives 
  else
  exit
fi

   echo " "
   $perl_loc scripts/opt_copy $perl_loc
 

