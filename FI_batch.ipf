#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// FI function from Dan Pollak and Joseph Starrett's work
// Adapted by Matheus Macedo-Lima

Function/D FI_batch(w)
	wave w
	
	variable spikes, current_step, FI
	
	variable level = -.010 // threshold for spike detection in V
	
	variable pulse_start = 3  // Change this accordingly to match the start of the current pulse in seconds
	variable pulse_end = 3.5  // Change this accordingly to match the end of the current pulse in seconds
      	// Edit these according to protocol used
      	variable first_pulse = -50  
       	variable number_of_pulses = 15
       	variable pulse_increments = 10
       	// Grab current pulse from raw wave name
       	variable current_step_FI = (str2num(StringFromList(3, NameOfWave(w)	, "_"))-1)*pulse_increments+first_pulse  
	
	//evoked peak detection
	findLevels/R=(pulse_start,pulse_end)/DEST=levels/Q/M=.001 w, level
	
	variable numEvoked= numpnts(levels)/2
	//print "NUMEVOKED" + num2str(numEvoked)
	Make /O/D/N=(numEvoked) evokedPeaks
	Make /O/D/N=(numEvoked) evokedPeakTimes
	
	variable evokedPeak
	variable evokedPeakTime
	
	variable i
	variable pos=0
	
	for (i=0;i<numpnts(levels) - 1;i+=2)
		Variable xUp=levels[i]
		Variable xDown=levels[i+1]
		Wavestats/Q/R=(xUp,xDown) w
		evokedPeak = V_max
		evokedPeakTime= V_maxloc
		evokedPeaks[pos]=evokedpeak
		evokedPeakTimes[pos]=evokedPeakTime
		pos+=1
	endfor
	

	spikes = numpnts(evokedPeaks)
	//currentInjected = str2num(label)
	//FI = spikes / currentInjected


	//interspike intervals
	
	Make /O/D/N=(numpnts(evokedPeakTimes)-1) evokedISI
	variable k
	variable n=0
	
	for (k=0;k<numpnts(evokedPeakTimes)-1;k+=1)
		variable interval
		interval= evokedPeakTimes[k+1]-evokedPeakTimes[k]
		//print interval
		endfor	
	
	
	//print ("*********************\r" + nameofwave(current) + "- " + "\rFI: " + num2str(FI) + "\rspikes: " + num2str(spikes) )
	//print ("current injected: " + num2str(currentInjected))
	
	//Add to wave
	Make/D/O/N=(1,2) retVal
       	retVal[0][0] = current_step_FI
       	retVal[0][1] = spikes
	return retVal //CHANGED FI FUNCTION TO RETURN SPIKES NOT FI**
end
