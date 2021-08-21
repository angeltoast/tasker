#!/bin/bash

# Tasker - a simple reminder list of upcoming tasks
# 1) Tasks are held in a text file in random order;
# 2) When called, Tasker displays any items within a specified date range;
# 3) User can add/delete tasks and specify date range.

# Started 20210814
# Elizabeth Mills
#
# This program is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# A copy of the GNU General Public License is available from:
# the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
# ----------------------------------------------------------------------------------------
# NOTES                                                                                   :
# Depends: cal (ncal in Debian)                                                           :
# ----------------------------                                                            :
# The file format of the tasks.list file is:                                              :
#  Action Date (dd/mm/yyyy) -space- Descriptive Text -space- Repeat Criteria              :
#     Repeat criteria consist of ':' followed by an optional '-r' (for repeat)            :
#     then 'y' (years), 'm' (months), 'w' (weeks), or 'd' (days) ! without spaces !       :
#     and a number by which to repeat next time, a '.' and an optional number of repeats  :
#     These numbers are to be reduced each time they are cycled.                          :
#     If either number is omitted, repeats will occur every time forever:                 :
#        eg:   ':-rd10' to repeat every 10 days forever                                   :
#              ':-rw2.4' will repeat alternate weeks for 4 recurrences                    :
#              ':-ry1' will repeat every year                                             :
#     Annual repeats will be cycled at the start of each new year.                        :
#     Daily, weekly and monthly repeats will be entered for the number of cycles in the   :
#     current year. These may have to be recalculated at the start of the next year.      :
#     A plain ':' without any additional text means that no recurrances are required.     :
#                                                                                         :
#        An 'end of year' function is needed to prepare any daily/weekly/monthly          :
#        items for the next year.                                                         :
# ----------------------------------------------------------------------------------------

source lister.sh      # The Lister library of user interface functions

GlobalInt=0           # For returning integers from functions
GlobalChar="y"        # For returning strings from functions
GlobalCursorRow=0     # Manages the cursor position between functions

declare -a tasks      # Will hold a copy of the data file

function Main
{
   Tidy
   while [ $GlobalChar == "y" ]
   do
      local editor="$(head -n 1 tasker.settings | tail -n 1 | cut -d':' -f2)"
      SortFile                         # Prepare data file
      DoHeading
      ncal                             # Display system calendar
      DoForm "[Enter] to quit, or 'm' [Enter] for a menu: "
      if [ $GlobalChar ] && ([ $GlobalChar == "m" ] || [ $GlobalChar == "M" ]); then
         Menu
      else
         break
      fi
      Tidy
   done
}

function SortFile                      # Updates year in data file
{
   readarray -t tasks < tasks.list     # Copy file into array
   items=${#tasks[@]}

   Tidy                                # Prepare working file

   thisYear=$(date '+%Y')              # Get current year

   for (( i=0; i <= $items; ++i ))     # Set all annual items to current year
   do
      if [ "${tasks[i]}" == "" ]; then continue; fi
      if grep -q ":-ry" <<< "${tasks[i]}"; then    # If an annual item
         item="${tasks[i]}"                        # Save the current state
         dayMonth=$(echo $item | cut -d'/' -f1,2)  # Separate date & month
         fullDate="$dayMonth/$thisYear"            # Create a new full date
         itemText=${item:11}                       # Save non-date text from item
         newItem="$fullDate $itemText"             # Add the new date
         echo $newItem >> temp.tasks.list          # Save new record to temp file
      else                                         # Not an annual item
         echo "${tasks[i]}" >> temp.tasks.list     # Save original record to temp file
      fi
   done

   # Sort updated temp file to tasks.list (overwites original)
   sort -n -k 1.4 -k 1.1 temp.tasks.list > tasks.list

   prepareDisplay                                  # Prepare to display tasks

   return 0
}

function prepareDisplay
{
   Tidy
   BackTitle="$(date '+%A %d %B %Y')"              # Display date
   DoHeading                                       # as a heading

   GlobalCursorRow=2                               # Set cursor position
   currentMonth=$(date '+%m')                      # Get current month

   case $currentMonth in
    '01')   nextMonth='02' ;;
    '02')   nextMonth='03' ;;
    '03')   nextMonth='04' ;;
    '04')   nextMonth='05' ;;
    '05')   nextMonth='06' ;;
    '06')   nextMonth='07' ;;
    '07')   nextMonth='08' ;;
    '08')   nextMonth='09' ;;
    '09')   nextMonth='10' ;;
    '10')   nextMonth='11' ;;
    '11')   nextMonth='12' ;;
    '12')   nextMonth='01' ;;
    *)    echo "Date error"
   esac

   displayDueTasks                                 # Now we can display tasks
   Tidy
   return 0
}

function displayDueTasks
{
   # Display all due items in task.list for this month

   Tidy                                   # Clear temp file

   readarray -t tasks < tasks.list
   items=${#tasks[@]}
   for (( i=0; i <= $items; ++i ))
   do
      if grep -q "../$currentMonth" <<< "${tasks[i]}"; then
         item=$(echo ${tasks[i]} | cut -d':' -f1)
         echo "$i: $item" >> temp.tasks.list
      fi
   done

   # Display all items in task.list that match next month

   for (( i=0; i <= $items; ++i ))
   do
      if grep -q "../$nextMonth" <<< "${tasks[i]}"; then
         item=$(echo ${tasks[i]} | cut -d':' -f1)
         echo "$i: $item" >> temp.tasks.list
      fi
   done

   DoLongMenu  "temp.tasks.list" "Select Exit" "~ Tasks This Month ~"

   if [ $? -eq 1 ]; then   # An item was selected
      DoMenu  "Edit Delete Add" "Select Quit" "Selected item $GlobalChar" # Simple menu
      case $GlobalInt in
      1)   EditItem ;;
      2)   DeleteItem ;;
      3)   AddItem ;;
      esac
   fi
   Tidy
   return 0
}

function EditItem
{
   # Select the full item from the array by its number
   # Edit it and save back to the array
   # Write the array back to the data file
   return 0
}

function DeleteItem
{
   # Run through data file, adding each item to a new copy of the array
   # When the matching item is reached, skip it, then add the rest
   # Write the array back to the data file
   return 0
}

function AddItem
{
   # Enter details to a variable
   # Append it to the array
   # If repeat is set for days/weeks/months, add as required until the end of current year
   # Write the array back to the data file
   # Run SortFile
   return 0
}

function Menu
{
    DoMenu "Tasks Settings" "" "Show Due Tasks, Change Editor, or Quit"
    case $GlobalInt in              # Returned by DoMenu
    1)  GlobalChar="y"
    ;;
    2)  $editor tasker.settings     # Open the settings file in editor
        # After editor is closed, reload the new settings in current session ...
      editor="$(head -n 1 tasker.settings | tail -n 1 | cut -d':' -f2)"
      GlobalChar="y"
    ;;
    *)  GlobalChar="n"
    esac

    return 0
}

function Tidy
{
   rm temp.tasks.list 2>/dev/null       # Clear temporary files
}

Main
