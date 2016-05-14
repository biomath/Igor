#pragma rtGlobals=1		// Use modern global access method.

Menu "GL"
	"Do It All Waves_MML", DoItAllWaves_MML()
End

Function DoItAllWaves_MML()
	
	String WaveNameFormat=StrVarOrDefault("root:GL_Globals:DoItAll:GWaveNameFormat", "PMP*")
	String FunctionNameString=StrVarOrDefault("root:GL_Globals:DoItAll:GFunctionNameString", "")
	// String EDate=""//StrVarOrDefault("ExpDate", "")
	variable Outputs_num = 1
	Prompt WaveNameFormat, "Please specify the wave name format:"
	// Prompt EDate, "Please specify the date on which this experiment was performed (format: 9.03.15)"
	Prompt Outputs_num, "How many outputs should be expected from the batch function?"
	Prompt FunctionNameString, "Please specify the function name:", popup, FunctionList("*_batch",";","")
	// DoPrompt "Do It All Waves", WaveNameFormat, EDate, FunctionNameString
	DoPrompt "Do It All Waves", WaveNameFormat, Outputs_num, FunctionNameString
	// String/G ExpDate = EDate
	// variable/G Outputs_num = Outputs_num
	if (V_flag==1)
		Abort
	endif
	NewDataFolder/O root:GL_Globals
	NewDataFolder/O root:GL_Globals:DoItAll
	String/G root:GL_Globals:DoItAll:GWaveNameFormat=WaveNameFormat
	String/G root:GL_Globals:DoItAll:GFunctionNameString=FunctionNameString
	
	
	String AllWaveNameList=WaveList(WaveNameFormat,";","")
	
	if (strlen(AllWaveNameList)==0)
		Print "No specified waves are found in current folder!"
		Abort
	endif
	
	String WaveNameString=""

	Make/D/O/N=0 Results
	//Make/D/O/N=(0,2) Results  // MML: create a bidimensional list to store wavename and result
	Make/T/O/N=0 WaveNamesAll  // MML edit: WaveNames will be added to a single list
	Variable i=0
	FUNCREF myprotofunc f=$FunctionNameString
	Do 
		WaveNameString=StringFromList(i, AllWaveNameList)
		InsertPoints numpnts(Results), 1, Results  // Insert 1 row before the last (numpnts) element of Results
		
		Make/D/O/N=(1, Outputs_num) curr_result
		curr_result = f($WaveNameString)

		if (i == 0)
			InsertPoints/M=1 numpnts(Results), DimSize(curr_result, 1)-1, Results  // Create the necessary amount of columns
		endif
		
		variable j
		for(j = 0; j < DimSize(curr_result, 1)+1; j +=1)
			Results[numpnts(Results)-1][j]=curr_result[0][j]
		endfor
		// Results[numpnts(Results)-1, 1]=f($WaveNameString)  // MML: Add calculation to last position in the list and to the second column
		InsertPoints numpnts(WaveNamesAll), 1, WaveNamesAll
		WaveNamesAll[numpnts(WaveNamesAll)-1]=WaveNameString		
		i=i+1
	While (strlen(StringFromList(i, AllWaveNameList))!=0)
	String ResultsWaveString="r_"+FunctionNameString
	WaveStats/Q/Z Results
	//Print V_avg, V_sdev
	Duplicate/O Results, $ResultsWaveString
	ResultsWaveString="WaveName_"+FunctionNameString
	Duplicate/O WaveNamesAll, $ResultsWaveString
	KillWaves/Z Results, WaveNamesAll, curr_result
End

Function myprotofunc(w)
	Wave w
	Print "No function found."
End
