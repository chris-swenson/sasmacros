' CheckLog Launch
CheckLog = \\tsclient\P\_Common_Variables_Code_Definitions_Documentation\_SAS_Common_Processes\shared\macros\checklog.sas 
Dim objSAS
UserInput = InputBox("Enter the log to check:", "CheckLog")
Set objSAS=CreateObject("SAS.Application")
objSAS.Visible=True
objSAS.Submit("%inc '" & CheckLog & "';")
objSAS.Submit("%checklog(" & UserInput & ");")