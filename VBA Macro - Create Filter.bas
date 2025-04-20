Attribute VB_Name = "Module3"
Sub AbsenceFilter()

'Filter Absence
    
    Sheets("Intra-Day View").Select
    Range("Y19").Select
    Selection.AutoFilter Field:=23, Criteria1:=">0.01%"
'    Range("AC19").Select
'   Selection.AutoFilter Field:=27, Criteria1:="="
    

End Sub

Sub WEValidation()

'Filter Absence
    
    Sheets("Consolidated").Select
    Range("Z1").Select
    Selection.AutoFilter Field:=26, Criteria1:="Absent"
    Range("AA1").Select
    Selection.AutoFilter Field:=27, Criteria1:="="
    

End Sub
