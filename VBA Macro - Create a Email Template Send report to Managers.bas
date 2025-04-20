Attribute VB_Name = "Module1"
Sub SendEmail()

' Don't forget to copy the function GetBoiler in the module.
' Working in Office 2000-2010
    Dim OutApp As Object
    Dim OutMail As Object
    Dim strbody As String
    Dim SigString As String
    Dim Signature As String
    Dim rng As Range
    

'VARIABLES
AAA = Sheets("Intra-Day View").Range("Bj6").Value 'TO
BBB = Sheets("Intra-Day View").Range("Bj7").Value 'CC
CCC = Sheets("Intra-Day View").Range("Bj8").Value 'SUBJECT
DDD = Sheets("Intra-Day View").Range("Bj9").Value 'BODY
EEE = Sheets("Intra-Day View").Range("Bj10").Value 'RANGE
FFF = Sheets("Intra-Day View").Range("Bj11").Value 'SIGNATURES


    Set rng = Nothing
    On Error Resume Next
    'Only the visible cells in the selection
    Set rng = Sheets("Intra-Day View").Range(EEE).SpecialCells(xlCellTypeVisible)
    'You can also use a range if you want
    'Set rng = Selection.SpecialCells(xlCellTypeVisible)
    On Error GoTo 0

    If rng Is Nothing Then
        MsgBox "The selection is not a range or the sheet is protected" & _
               vbNewLine & "please correct and try again.", vbOKOnly
        Exit Sub
    End If

    With Application
        .EnableEvents = False
        .ScreenUpdating = False
    End With
    

        
    Set OutApp = CreateObject("Outlook.Application")
    Set OutMail = OutApp.CreateItem(0)

    strbody = "Hi Team," & _
              "<br>" & _
              "<br>" & _
              DDD
            
    'Use the second SigString if you use Vista as operating system

    SigString = "C:\Documents and Settings\" & Environ("username") & _
                FFF

    'SigString = "C:\Users\" & Environ("username") & _
     "\AppData\Roaming\Microsoft\Signatures\Mysig.htm"

    'If Dir(SigString) <> "" Then
        'Signature = GetBoiler(SigString)
    'Else
        'Signature = ""
    'End If

    On Error Resume Next
    With OutMail
        .To = AAA
        .CC = BBB
        .BCC = ""
        .Subject = CCC
        .HTMLBody = strbody & "<br>" & RangetoHTML(rng) & "<br><br>" & Signature
        .Display   'or use .Send
    End With

    On Error GoTo 0
    Set OutMail = Nothing
    Set OutApp = Nothing
End Sub

'CONSTANT IN INSERTING SIGNATURE

Function GetBoiler(ByVal sFile As String) As String

    Dim fso As Object
    Dim ts As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set ts = fso.GetFile(sFile).OpenAsTextStream(1, -2)
    GetBoiler = ts.ReadAll
    ts.Close
End Function

'CONSTANT IN COPYING CELLS

Function RangetoHTML(rng As Range)

' Working in Office 2000-2010
    Dim fso As Object
    Dim ts As Object
    Dim TempFile As String
    Dim TempWB As Workbook
 
    TempFile = Environ$("temp") & "/" & Format(Now, "dd-mm-yy h-mm-ss") & ".htm"
 
    'Copy the range and create a new workbook to past the data in
    rng.Copy
    Set TempWB = Workbooks.Add(1)
    With TempWB.Sheets(1)
        .Cells(1).PasteSpecial Paste:=8
        .Cells(1).PasteSpecial xlPasteValues, , False, False
        .Cells(1).PasteSpecial xlPasteFormats, , False, False
        .Cells(1).Select
        Application.CutCopyMode = False
        On Error Resume Next
        .DrawingObjects.Visible = True
        .DrawingObjects.Delete
        On Error GoTo 0
    End With
 
    'Publish the sheet to a htm file
    With TempWB.PublishObjects.Add( _
         SourceType:=xlSourceRange, _
         Filename:=TempFile, _
         Sheet:=TempWB.Sheets(1).Name, _
         Source:=TempWB.Sheets(1).UsedRange.Address, _
         HtmlType:=xlHtmlStatic)
        .Publish (True)
    End With
 
    'Read all data from the htm file into RangetoHTML
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set ts = fso.GetFile(TempFile).OpenAsTextStream(1, -2)
    RangetoHTML = ts.ReadAll
    ts.Close
    RangetoHTML = Replace(RangetoHTML, "align=center x:publishsource=", _
                          "align=left x:publishsource=")
    'Close TempWB
    TempWB.Close savechanges:=False
 
    'Delete the htm file we used in this function
    Kill TempFile
 
    Set ts = Nothing
    Set fso = Nothing
    Set TempWB = Nothing
End Function




Sub sSleep(seconds)
        Set oWSShell = CreateObject("Wscript.Shell")
        cmd = "%COMSPEC% /c ping -n " & 1 + seconds & " 127.0.0.1>nul"
        oWSShell.Run cmd, 0, 1


End Sub
