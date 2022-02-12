#!/bin/bash
echo #######################
if ! [ -d DBMS ] 
then
	mkdir DBMS
fi

clear
echo "Welcome To DBMS"

function mainMenu {
  echo "======================================"
  echo "1. Create DataBase"
  echo "2. List DataBases "
  echo "3. Connect to DataBase"
  echo "4. Drop DataBase"
  echo "5. Exit"
  echo "======================================"
  
  echo -e "Enter Choice: \c"
  read ch
  case $ch in
    1)  createDB ;;
    2)  listDBs;;
    3)  connectDB ;;
    4)  dropDB ;;
    5)  ;;
    *) echo " Wrong Choice " ; mainMenu;
  esac
}
function createDB {
  echo -e "Enter Database Name: \c"
  read dbName

  if ! [[ $dbName =~ ^[a-zA-Z]*$ ]]; then
        echo -e "Invalid Database Name !!"
        mainMenu
	return;
  fi


  if ! [ -d ./DBMS/$dbName ]
  then
  	mkdir ./DBMS/$dbName
    echo "Database Created Successfully"
  else
    echo "Database $dbName already exists"
  fi
  mainMenu
}
function connectDB {
  echo -e "Enter Database Name: \c"
  read dbName
  if [ -d ./DBMS/$dbName ]
  then
    cd ./DBMS/$dbName 
    echo "Database $dbName was Successfully Connected"
    tablesMenu
  else
    echo "Database $dbName wasn't found"
    mainMenu
  fi
}
function listDBs {
	ls ./DBMS ;
	mainMenu
} 

function dropDB {
  echo -e "Enter Database Name: \c"
  read dbName
   
  if [ -d ./DBMS/$dbName ]
  then
    rm -r -i ./DBMS/$dbName
    echo "Database Dropped Successfully"
  else
    echo "Database Not found"
  fi
  mainMenu
}

function tablesMenu {
  echo "======================================"
  echo "1. Create New Table"
  echo "2. List all Tables"
  echo "3. Drop Table"
  echo "4. Insert Into Table"
  echo "5. Select From Table"
  echo "6. Delete From Table"
  echo "7. Update Table"
  echo "8. Exit "
  echo "======================================"
  echo -e "Enter Choice: \c"
  read ch
  case $ch in
    1)  createTable ;;
    2)  ls .; tablesMenu ;;
    3)  dropTable;;
    4)  insert;;
    5)  clear; selectMenu ;;
    6)  deleteFromTable;;
    7)  updateTable;;
    8) clear; cd ../.. 2>>./.error.log; mainMenu ;;
    *) echo " Wrong Choice " ; tablesMenu;
  esac

}

function createTable {
  echo -e "Table Name: \c"
  read tableName
  if ! [[ $tableName =~ ^[a-zA-Z]*$ ]]; then
        echo -e "Invalid Table name !!"
	tablesMenu
	return
  fi
    
  
  if [[ -f $tableName ]]; then
    echo "Table already existed ,choose another name"
    tablesMenu
  fi
  echo -e "Number of Columns: \c"
  read colsNum
  counter=1
  sep="|"
  rSep="\n"
  pKey=""
  metaData="Field"$sep"Type"$sep"key"
  while [ $counter -le $colsNum ]
  do
    echo -e "Name of Column No.$counter: \c"
    read colName

    echo -e "Type of Column $colName: "
    select var in "int" "str"
    do
      case $var in
        int ) colType="int";break;;
        str ) colType="str";break;;
        * ) echo "Wrong Choice" ;;
      esac
    done
    if [[ $pKey == "" ]]; then
      echo -e "Make PrimaryKey ? "
      select var in "yes" "no"
      do
        case $var in
          yes ) pKey="PK";
          metaData+=$rSep$colName$sep$colType$sep$pKey;
          break;;
          no )
          metaData+=$rSep$colName$sep$colType$sep""
          break;;
          * ) echo "Wrong Choice" ;;
        esac
      done
    else
      metaData+=$rSep$colName$sep$colType$sep""
    fi
    if [[ $counter == $colsNum ]]; then
      temp=$temp$colName
    else
      temp=$temp$colName$sep
    fi
    ((counter++))
  done
  touch .$tableName
  echo -e $metaData  >> .$tableName
  touch $tableName
  echo -e $temp >> $tableName
  if [[ $? == 0 ]]
  then
    echo "Table Created Successfully"
    tablesMenu
  else
    echo "Error Creating Table $tableName"
    tablesMenu
  fi
}

function dropTable {
  echo -e "Enter Table Name: \c"
  read tName
  if [[ -f $tName ]]
  then
    rm -i $tName .$tName 
    echo "Table Dropped Successfully"
  else
    echo "Table $tName doesn't exists"
  fi
  tablesMenu
}

function insert {
  echo -e "Table Name: \c"
  read tableName
  if ! [[ -f $tableName ]]; then
    echo "Table $tableName doesn't exist "
    tablesMenu
  fi
  rowsNum=`awk 'END{print NR}' .$tableName`
  sep="|"
  rSep="\n"
  for (( i = 2; i <= $rowsNum; i++ )); do
    colName=$(awk 'BEGIN{FS="|"}{ if(NR=='$i') print $1}' .$tableName)
    colType=$( awk 'BEGIN{FS="|"}{if(NR=='$i') print $2}' .$tableName)
    colKey=$( awk 'BEGIN{FS="|"}{if(NR=='$i') print $3}' .$tableName)
    echo -e "$colName ($colType) = \c"
    read data

    # Validate Input
    if [[ $colType == "int" ]]; then
      while ! [[ $data =~ ^[0-9]*$ ]]; do
        echo -e "invalid DataType !!"
        echo -e "$colName ($colType) = \c"
        read data
      done
    fi
    if [[ $colType == "str" ]]; then
      while ! [[ $data =~ ^[a-zA-Z]*$ ]]; do
        echo -e "invalid DataType !!"
        echo -e "$colName ($colType) = \c"
        read data
      done
    fi

    if [[ $colKey == "PK" ]]; then
      while [[ true ]]; do
        if [[ $data =~ ^[`awk 'BEGIN{FS="|" ; ORS=" "}{if(NR != 1)print $(('$i'-1))}' $tableName`]$ ]]; then
          echo -e "invalid input for Primary Key !!"
        else
          break;
        fi
        echo -e "$colName ($colType) = \c"
        read data
      done
    fi

    #Set row
    if [[ $i == $rowsNum ]]; then
      row=$row$data$rSep
    else
      row=$row$data$sep
    fi
  done
  echo -e $row"\c" >> $tableName
  if [[ $? == 0 ]]
  then
    echo "Data Inserted Successfully"
  else
    echo "Error Inserting Data into Table $tableName"
  fi
  row=""
  tablesMenu
}

function updateTable {
  echo -e "Enter Table Name: \c"
  read tName
  if ! [ -f $tName ]
  then
    echo "Table $tName doesn't exist "
  else
	  echo -e "Enter Condition Column name: \c"
	  read field
	  fid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$field'") print i}}}' $tName)
	  if [[ $fid == "" ]]
	  then
	    echo "Not Found"
	    tablesMenu
	  else
	    echo -e "Enter Condition Value: \c"
	    read val
	    res=$(awk 'BEGIN{FS="|"}{if ($'$fid'=="'$val'") print $'$fid'}' $tName 2>>./.error.log)
	    if [[ $res == "" ]]
	    then
	      echo "Value Not Found"
	      tablesMenu
	    else
	      echo -e "Enter FIELD name to set: \c"
	      read setField
	      setFid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$setField'") print i}}}' $tName)
	      if [[ $setFid == "" ]]
	      then
		echo "Not Found"
		tablesMenu
	      else
		echo -e "Enter new Value to set: \c"
		read newValue
		NR=$(awk 'BEGIN{FS="|"}{if ($'$fid' == "'$val'") print NR}' $tName 2>>./.error.log)
		oldValue=$(awk 'BEGIN{FS="|"}{if(NR=='$NR'){for(i=1;i<=NF;i++){if(i=='$setFid') print $i}}}' $tName 2>>./.error.log)
		echo $oldValue
		sed -i ''$NR's/'$oldValue'/'$newValue'/g' $tName 2>>./.error.log
		echo "Row Updated Successfully"
		tablesMenu
	      fi
	    fi
	  fi
fi
}

function deleteFromTable {
  echo -e "Enter Table Name: \c"
  read tName
  echo -e "Enter Condition Column name: \c"
  read field
  fid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$field'") print i}}}' $tName)
  if [[ $fid == "" ]]
  then
    echo "Not Found"
    tablesMenu
  else
    echo -e "Enter Condition Value: \c"
    read val
    res=$(awk 'BEGIN{FS="|"}{if ($'$fid'=="'$val'") print $'$fid'}' $tName 2>>./.error.log)
    if [[ $res == "" ]]
    then
      echo "Value Not Found"
      tablesMenu
    else
      NR=$(awk 'BEGIN{FS="|"}{if ($'$fid'=="'$val'") print NR}' $tName 2>>./.error.log)
      sed -i ''$NR'd' $tName 2>>./.error.log
      echo "Row Deleted Successfully"
      
      tablesMenu
    fi
  fi
}

function selectMenu {
  echo "====================================================="
  echo "1. Select All Columns of a Table"
  echo "2. Select Specific Column from a Table"
  echo "3. Select From Table under condition"
  echo "4. Exit"
  echo "====================================================="
  echo -e "Enter Choice: \c"
  read ch
  case $ch in
    1) selectAll ;;
    2) selectCol ;;
    3) clear; selectCon ;;
    4) clear; tablesMenu ;;
    
    *) echo " Wrong Choice " ; selectMenu;
  esac
}

function selectAll {
  echo -e "Enter Table Name: \c"
  read tName
   
  if [[ -f $tName ]]
  then
    column -t -s '|' $tName
    
  else 
    echo "Table $tName doesn't exist"
  fi
  selectMenu
}

function selectCol {
  echo -e "Enter Table Name: \c"
  read tName
  if [[ -f $tName ]]
  then
	  echo -e "Enter Column Number: \c"
	  read colNum
	  awk 'BEGIN{FS="|"} {if (NF >= '$colNum' && '$colNum' >0 ) print $'$colNum'; }END { if(NF < '$colNum' || '$colNum' <= 0 ) print "wrong column number " }' $tName
  else 
    echo "Table $tName doesn't exist"
  fi
  selectMenu
}

function selectCon {
  echo -e "\n\n+--------Select Under Condition Menu-----------+"
  echo "| 1. Select All Columns Matching Condition    |"
  echo "| 2. Select Specific Column Matching Condition|"
  echo "| 3. Back To Selection Menu                   |"
  echo "| 4. Back To Main Menu                        |"
  echo "| 5. Exit                                     |"
  echo "+---------------------------------------------+"
  echo -e "Enter Choice: \c"
  read ch
  case $ch in
    1) clear; allCond ;;
    2) clear; specCond ;;
    3) clear; selectCon ;;
    4) clear; cd ../.. 2>>./.error.log; mainMenu ;;
    5) exit ;;
    *) echo " Wrong Choice " ; selectCon;
  esac
}

function allCond {
  echo -e "Select all columns from TABLE Where FIELD(OPERATOR) = VALUE \n"
  echo -e "Enter Table Name: \c"
  read tName
  echo -e "Enter required FIELD name: \c"
  read field
  fid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$field'") print i}}}' $tName)
  if [[ $fid == "" ]]
  then
    echo "Not Found"
    selectCon
  else
    echo -e "\nSupported Operators: [==, !=, >, <, >=, <=] \nSelect OPERATOR: \c"
    read op
    if [[ $op == "==" ]] || [[ $op == "!=" ]] || [[ $op == ">" ]] || [[ $op == "<" ]] || [[ $op == ">=" ]] || [[ $op == "<=" ]]
    then
      echo -e "\nEnter required VALUE: \c"
      read val
      res=$(awk 'BEGIN{FS="|"}{if ($'$fid$op$val') print $0}' $tName 2>>./.error.log |  column -t -s '|')
      if [[ $res == "" ]]
      then
        echo "Value Not Found"
        selectCon
      else
        awk 'BEGIN{FS="|"}{if ($'$fid$op$val') print $0}' $tName 2>>./.error.log |  column -t -s '|'
        selectCon
      fi
    else
      echo "Unsupported Operator\n"
      selectCon
    fi
  fi
}

function specCond {
  echo -e "Select specific column from TABLE Where FIELD(OPERATOR)VALUE \n"
  echo -e "Enter Table Name: \c"
  read tName
  echo -e "Enter required FIELD name: \c"
  read field
  fid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$field'") print i}}}' $tName)
  if [[ $fid == "" ]]
  then
    echo "Not Found"
    selectCon
  else
    echo -e "\nSupported Operators: [==, !=, >, <, >=, <=] \nSelect OPERATOR: \c"
    read op
    if [[ $op == "==" ]] || [[ $op == "!=" ]] || [[ $op == ">" ]] || [[ $op == "<" ]] || [[ $op == ">=" ]] || [[ $op == "<=" ]]
    then
      echo -e "\nEnter required VALUE: \c"
      read val
      res=$(awk 'BEGIN{FS="|"; ORS="\n"}{if ($'$fid$op$val') print $'$fid'}' $tName 2>>./.error.log |  column -t -s '|')
      if [[ $res == "" ]]
      then
        echo "Value Not Found"
        selectCon
      else
        awk 'BEGIN{FS="|"; ORS="\n"}{if ($'$fid$op$val') print $'$fid'}' $tName 2>>./.error.log |  column -t -s '|'
        selectCon
      fi
    else
      echo "Unsupported Operator\n"
      selectCon
    fi
  fi
}

mainMenu
