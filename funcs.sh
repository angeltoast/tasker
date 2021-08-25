#!/bin/bash

# Tasker - an appointments management program written in Bash
# This module contains all the functions called by the main Tasker module
# ----------------------------------------------------------------------
# Line   Function       Purpose           Line   Function       Purpose
# ----------------------------------------------------------------------
# 20  SortFile         Update data file | 230 Showfields
# 47  PrepareDisplay   Load reminders   | 243 DateEntry
# 72  DisplayDueTasks  Display tasks    | 324 TextEntry
# 129 EditItem         IN PROGRESS      | 361 SetRepeats  # TODO
# 161 DeleteItem       DONE             | 392 RunRepeats  # TODO
# 184 AddItem          IN PROGRESS      | 408 Tidy        # Delete temp file
# 197 EnterTaskDescription  Description | 413 debug
# 213 OptionsMenu      Backout menu     |
# ----------------------------------------------------------------------
function SortFile        # Updates year in data file
{
   readarray -t tasks < tasks.list                 # Copy file into array
   items=${#tasks[@]}
   thisYear=$(date '+%Y')                          # Get current year
   for (( i=0; i <= $items; ++i ))                 # Set all annual items
   do                                              # to current year
      if [ "${tasks[i]}" == "" ]; then continue; fi
      if grep -q "<-ry" <<< "${tasks[i]}"; then    # If an annual item
         item="${tasks[i]}"                        # Save the current state
         dayMonth=$(echo $item | cut -d'/' -f1,2)  # Separate date & month
                                                   # Includes leading <
         fullDate="$dayMonth/$thisYear"            # Create a new full date
                                                   # Includes leading
         itemText=$(echo $item | cut -d'<' -f3)    # Copy reminder text
                                                   # Includes trailing >
         repeatText=$(echo $item | cut -d'<' -f4)  # Copy repeat text
                                                   # Includes trailing >
         newItem="$fullDate><$itemText<$repeatText"  # Add the new date
         echo $newItem >> temp.tasks.list          # Save new record to temp file
      else                                         # Not an annual item
         echo "${tasks[i]}" >> temp.tasks.list     # Save original record to temp file
      fi
   done
   # Sort updated temp file to tasks.list (overwites original)
   sort -n -k 1.4 -k 1.1 temp.tasks.list > tasks.list
   Tidy                                            # Delete temp file
   return 0
} # End SortFile

function PrepareDisplay
{
   DoHeading
   Grow=2                               # Set cursor position
   currentMonth=$(date '+%m')           # Get current month
   case $currentMonth in
    '01') nextMonth='02' ;;
    '02') nextMonth='03' ;;
    '03') nextMonth='04' ;;
    '04') nextMonth='05' ;;
    '05') nextMonth='06' ;;
    '06') nextMonth='07' ;;
    '07') nextMonth='08' ;;
    '08') nextMonth='09' ;;
    '09') nextMonth='10' ;;
    '10') nextMonth='11' ;;
    '11') nextMonth='12' ;;
    '12') nextMonth='01' ;;
    *) DoMessage "Date error"
   esac
   return 0
} # End PrepareDisplay

function DisplayDueTasks
{
   # Add all due items for this month to temp file
   readarray -t tasks < tasks.list
   items=${#tasks[@]}
   for (( i=0; i <= $items; ++i ))
   do
      local recordNumber=$((i+1))
      if grep -q "<../$currentMonth" <<< "${tasks[i]}"; then
         item=$(echo ${tasks[i]} | cut -d'<' -f2,3 | sed 's/</ /g' | sed 's/>//g' )
        # echo "[$recordNumber] $item" >> temp.tasks.list
         printf "[%03d] %s\n" $recordNumber "$item" >> temp.tasks.list
      fi
   done
   # Add all due items for next month to temp file
   for (( i=0; i <= $items; ++i ))
   do
      recordNumber=$((i+1))
      if grep -q "<../$nextMonth" <<< "${tasks[i]}"; then
         item=$(echo ${tasks[i]} | cut -d'<' -f2,3 | sed 's/</ /g' | sed 's/>//g' )
        # echo "[$recordNumber] $item" >> temp.tasks.list
         printf "[%03d] %s\n" $recordNumber "$item" >> temp.tasks.list
      fi
   done
   # Display tasks in a menu
   local winHeight=$(tput lines)    # Get window height and calculate
   winHeight=$((winHeight-6))       # maximum lines printable
   local fileLines=$(wc -l temp.tasks.list | cut -d' ' -f1)
   # If the file exceeds limits, use DoMega instead
   if [ $fileLines -lt $winHeight ]; then
      DoLongMenu  "temp.tasks.list" "Select Done" "~ Tasks for $(date +%B) and $(date +%B -d "+ 1 month") ~"
   else
      DoMega  "temp.tasks.list" "~ Tasks for $(date +%B) and $(date +%B -d "+ 1 month") ~"
   fi
   Tidy                          # Delete temp file (use Gstring from here)
   if [ ! $Gstring ]; then       # No item was selected
      OptionsMenu                # Backing out
   else
      selectedItem="$Gstring"    # Copy Gstring before DoMenu overwrites it
      BackTitle="$selectedItem"  # Display selected record as heading
      DoMenu  "Edit Delete" "Select Cancel" "Please choose an action"
      Gstring="$selectedItem"    # Restore Gstring
      case $Gnumber in
      1) EditItem ;;
      2) DeleteItem ;;
      *) OptionsMenu
         Gstring='n'
      esac
   fi
   return 0
} # End DisplayDueTasks

function EditItem
{                       # options to edit a) Date, b) Details, c) Repeat
   # Item is in Gstring - separate record number & remove square brackets
   local record=$(echo $Gstring | cut -d']' -f1 | sed 's/\[//' )
   # Read the record back from file (with all brackets)
   Gstring="$(head -n ${record} tasks.list | tail -n 1)"
   # Prepare to display the record as a heading
   local field1=$(echo $Gstring | cut -d'<' -f2 | sed 's/>//' )
   local field2=$(echo $Gstring | cut -d'<' -f3 | sed 's/>//' )
   local field3=$(echo $Gstring | cut -d'<' -f4 | sed 's/>//' )
   BackTitle=$(echo $field1 : $field2 : $field3)
   # Offer a simple menu (salad, no fries)
   selectedItem="$Gstring"    # Copy Gstring before DoMenu overwrites it
   DoMenu "Date Message Repeat" "Select Cancel" "Which part do you wish to change?"
   Gstring="$selectedItem"    # Restore Gstring
   case $Gnumber in
   1) DateEntry ;;
   2) TextEntry ;;
   3) SetRepeats ;;
   *) OptionsMenu
      Gstring='n'
      return 0
   esac
   Gstring="y"
   return 0
} # End EditItem

function DeleteItem
{  # Item is in Gstring without repeat data
   # Get the record number from Gstring (to match from file)
   local record="$(echo $Gstring | cut -d'[' -f2)"
   Tidy                                   # Make sure the temp file gone
   local items=$(cat tasks.list | wc -l)  # Check size of tasks.list
   for (( i=1; i <= items; ++i ))         # Then run through it
   do                                     # Loading each line
      Gstring="$(head -n ${i} tasks.list | tail -n 1)"
      if [ $i -eq $record ]; then         # Record to be deleted, so skip
         continue
      else
         echo "$Gstring" >> temp.tasks.list # Add to the temp file
      fi
   done
   # Write the temp file to main file
   sort -n -k 1.4 -k 1.1 temp.tasks.list > tasks.list
   Tidy                                    # Delete temp file
   return 0
} # End DeleteItem

function AddItem
{
   # Enter details through a form to Gstring
   DateEntry
   TextEntry
   SetRepeats
   # Write the array to a new copy of the temp file
   # Write the temp file to main file using ...
   #     sort -n -k 1.4 -k 1.1 temp.tasks.list > tasks.list
   # ... then delete temp file
   return 0
} # End AddItem

function EnterTaskDescription    # Returns user entry through $Gstring
{                 # $1 is Text for prompt
   local winwidth length empty
   winwidth=$(tput cols); length=${#1}
   if [ ${length} -le ${winwidth} ]; then
      Gcol=$(( (winwidth - length) / 2 ))
   else
      Gcol=1
   fi
    tput cup $Grow $Gcol                     # Move cursor to start
    read -p "$1" Gstring                     # User enters description
} # End EnterTaskDescription

function OptionsMenu
{
   DoMenu "Add_a_Reminder Display_Tasks Change_Editor" "Select Quit" "Choose an action, or Quit"

   case $Gnumber in                          # Returned by DoMenu
   1) AddItem
      Gstring="y" ;;
   2) Gstring="y" ;;
   3) $editor tasker.settings                # Open the settings file in editor
      # After editor is closed, reload the new settings in current session ...
      editor="$(head -n 1 tasker.settings | tail -n 1 | cut -d':' -f2)"
      Gstring="y" ;;
   *) Gstring="n"
   esac
   return 0
} # End OptionsMenu

function ShowFields
{
   tput cup $Grow $Gcol                # Move cursor to prompt position
   printf '%s' "Date: [dd/mm/yyyy]"    # Date Prompts and boxes
   tput cup $((Grow+2)) $1             # Position for text prompt
   printf '%s%*s%s' "Text: [" 30 "]"   # Reminder prompt plus box
   tput cup $((Grow+4)) $1             # Position for repeats prompt
   printf '%s' "Will this entry repeat? (y/n) :"
}

function DateEntry
{                 # $1 may be existing text string
   if [ ! $1 ]; then
      BackTitle="Adding new reminder"
   else
      BackTitle="Editing existing reminder: $1"
   fi
   DoHeading
   local date1 date2 date3 reminder
   Grow=2
   DoFirstItem "Please enter details (leave empty to abort)"
   winwidth=$(tput cols)
   Gcol=$(( (winwidth - 36) / 2 ))
   # Enter day part of date
   while true
   do
      ShowFields
      Gcol=$((Gcol+7))
      tput cup $Grow $Gcol                   # Move cursor to entry position
      read -n2 date1                         # User enters 2 characters
      if [ ! $date1 ]; then return 0; fi
      local checklen=${#date1}
      if [ $checklen -lt 2 ]; then
         DoMessage "If less than 10, please use leading zero (eg: 08)"
         continue
      fi
      if [ $date1 -gt 31 ] || [ $date1 -lt 1 ]; then
         DoMessage "$date1 days? Do be sensible!"
         continue
      fi
      if [[ $date1 =~ [0-9] ]]; then
         break
      else
         DoMessage "Date fields must be numeric"
      fi
   done
   # Enter month part of date
   while true
   do
      Gcol=$((Gcol+3))
      tput cup $Grow $Gcol                # Move cursor to entry position
      read -n2 date2                      # User enters 2 characters
      if [ ! $date2 ]; then return 0; fi
      checklen=${#date2}
      if [ $checklen -lt 2 ]; then
         DoMessage "If less than 10, please use leading zero (eg: 08)"
         continue
      fi
      if [ $date2 -gt 12 ] || [ $date2 -lt 1 ]; then
         DoMessage "Month $date2? Do be sensible!"
         continue
      fi
      if [[ $date2 =~ [0-9] ]]; then
         break
      else
         DoMessage "Date fields must be numeric"
      fi
   done
   # Enter year part of date
   while true
   do
      Gcol=$((Gcol+3))
      tput cup $Grow $Gcol                   # Move cursor to entry position
      read -n4 date3                         # User enters 4 characters
      # Validate
      if [ ! $date3 ]; then return 0; fi
      checklen=${#date3}
      if [ $checklen -lt 4 ]; then
         DoMessage "Year field must be 4 digits"
         continue
      fi
      if [[ $date3 =~ [0-9] ]]; then
         break
      else
         DoMessage "Date fields must be numeric"
      fi
   done
   return 0
} # End DateEntry

function TextEntry
{                    # $1 may be existing text string
   if [ ! $1 ]; then
      BackTitle="Adding new reminder"
   else
      BackTitle="Editing existing reminder: $1"
   fi
   Grow=$((Grow+2))
   while true                                   # Enter text of reminder
   do
      Gcol=$((Gcol+7))
      tput cup $Grow $Gcol                      # Move cursor to entry position
      read -n30 reminder                        # User enters 30 characters
      if [ ! $reminder ]; then return 0; fi
      if [[ $reminder =~ [0-9a-zA-Z] ]]; then
         break
      fi
   done
   Grow=$((Grow+2))
   tput cup $Grow $Gcol                         # Move cursor to entry position
   read -p "Will this entry repeat? (y/n) : " repeats
   if [ $repeats == "y" ] || [ $repeats == "Y" ]; then
      SetRepeats
   else
      Gstring="<>"
   fi
   Gstring="<$date1/$date2/$date3><$reminder>$Gstring"
   return 0
} # End TextEntry

function SetRepeats  # IN PROGRESS   # A menu to pick daily, weekly, monthly or yearly
{                    # $1 may be existing repeat string
   local repeatString="-r"
   if [ ! $1 ]; then
      BackTitle="Adding repeat data"
   else
      BackTitle="Editing repeat data: $1"
   fi
   local Item="$Gstring"  # Save item before DoMenu overwrites Gstring
   DoMenu  "Days Weeks Months Years" "Select Done" "Choose the repetition units for $Gstring"
   case $Gnumber in
   1) repeatString="-rd" ;;
   2) repeatString="-rw" ;;
   3) repeatString="-rm" ;;
   4) repeatString="-ry" ;;
   *) OptionsMenu
      Gstring='n'
   esac
   Gstring="$Item"  # Restore item
   # Add numeric entry fields for frequency and 'limit to x times'
   # Check that all fields have correct values, add to record
   # Then write the record to the main file

   # If repeat is set for days/weeks/months, add as required until the end of current year
 #  RunRepeats
   return 0

} # End SetRepeats

function RunRepeats  # TODO
{                    # Gstring must be set to full record to be run
   # Separate repeat citeria
   # Repeat daily, weekly or monthly reminders to year end
   # Using fields added by SetRepeats

   # Date Formatting
   # Today: date +"%d/%m/%Y"                             (23/08/2021)
   # Format month: date +"%d %b %Y"                      (23 Aug 2021)
   # Specified date: date +"%d/%m/%Y" -d "06 Sep 2021"   (06/09/2021)
   # Date Arithmetic
   # From today: newdate=$(date +"%d/%m/%Y" -d "+ 14 days")
   # From specified date: newdate=$(date +"%d/%m/%Y" -d "06 Sep 2021 +10 days")
   return 0
} # End RunRepeats

function Tidy
{
   rm temp.tasks.list 2>/dev/null    # Clear temporary file
} # End Tidy

function debug
{
   read -p "In file: $1 At line: $2"
}