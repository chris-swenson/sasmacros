' CheckLog Launch for OpenWith Menu
' Requires the CheckLog macro
' Replace the CheckLog variable with the location of the file
' Script by Chris Swenson at www.cswenson.com
CheckLog = "P:\_Common_Variables_Code_Definitions_Documentation\_SAS_Common_Processes\shared\Macros\CheckLog.sas"
Set objArgs = WScript.Arguments
For I = 0 to objArgs.Count - 1
    UserResponse = MsgBox("Would you like to specify additional arguments?" & Chr(13) & "Hit Cancel to stop the check.", 259, "CheckLog Options")
    if UserResponse = vbYes then
        UserInput = InputBox("Enter additional CheckLog arguments. " & Chr(13) &_
            "Hit Cancel to accept defaults." & Chr(13) & Chr(13) &_
            "Common arguments:" & Chr(13) &_
            "ext = extension to search for (directories only)" & Chr(13) &_
            "keyword = additional keyword(s) to search for" & Chr(13) &_
            "relog = overwrite the current log (Y/N/E)" & Chr(13) & Chr(13) &_
            "Note: Do not use the SHADOW argument. It is defaulted to Yes to copy the file first." & Chr(13) _
            , "CheckLog Arguments")
        if UserInput <> "" then UserInput = ", " & UserInput end if
    elseif UserResponse = vbNo then UserInput = ""
    else exit for
    end if
    Dim objSAS
    Set objSAS=WScript.CreateObject("SAS.Application")
    objSAS.Visible=True
    objSAS.Submit("%inc '" & CheckLog & "';")
    objSAS.Submit("%checklog(" & objArgs(I) & UserInput & ", shadow=Y);")
Next
