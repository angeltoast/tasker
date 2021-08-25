#!/bin/bash

# Tasker - a simple reminder list of upcoming tasks
# 1) Tasks are held in a text file in date order;
# 2) Tasker displays any items due within the current and next month;
# 3) User can add/delete/edit tasks.

# Updated 2021/08/25
# Elizabeth Mills

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# A copy of the GNU General Public License is available from:
# the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
# ----------------------------------------------------------------------------------------
# NOTES                                                                                   :
#  The file format of the tasks.list file is:                                             :
#  Action Date <dd/mm/yyyy><Descriptive Text><Repeat Criteria>                            :
#     Repeat criteria consist of '<' followed by an optional '-r' (for repeat)            :
#     then 'y' (years), 'm' (months), 'w' (weeks), or 'd' (days) ! without spaces !       :
#     and a number by which to repeat next time, a '+' and an optional number of repeats  :
#     These repetition numbers are to be reduced each time they are cycled.               :
#     If either number is omitted, repeats will occur every time forever:                 :
#        eg:   '<-rd10>' to repeat every 10 days forever                                  :
#              '<-rw2+4>' will repeat alternate weeks for 4 recurrences                   :
#              '<-ry1>' will repeat every year                                            :
#     Annual repeats will be cycled at the start of each new year.                        :
#     Daily, weekly and monthly repeats will be entered for the number of cycles in the   :
#     current year. These may have to be recalculated at the start of the next year.      :
#     A plain '<>' without any additional text means that no recurrances are required.    :
#                                                                                         :
#        An 'end of year' function is needed to prepare any daily/weekly/monthly          :
#        items for the next year.                                                         :
# ----------------------------------------------------------------------------------------

source lister.sh     # The Lister library of user interface functions
source funcs.sh      # Functions called by this module

# Global variables
Gnumber=0            # For returning integers from functions
Gstring="y"          # For returning strings from functions
Grow=0               # These two variables coordinate the
Gcol=0               #  cursor position between functions

declare -a tasks     # Will hold a copy of the data file

function Main
{
   Tidy              # Ensure that the temporary work file is not present

   while [ $Gstring == "y" ]
   do
      BackTitle="$(date '+%A %d %B %Y')"              # Display today's date
      editor="$(head -n 1 tasker.settings | tail -n 1 | cut -d':' -f2)"
      SortFile                                        # Prepare data file
      DoHeading
      Grow=2
      PrepareDisplay                                  # Load tasks
      DisplayDueTasks                                 # Now we can display tasks
   done
   clear
} # End Main

Main
