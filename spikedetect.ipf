#Pragma rtGlobals=1     // Use modern global access method. rtGlobals=1     // Use modern global access method.

Function spontspikeAnalysis(w, ampThresh)
        
        Wave w
        Variable ampThresh
        findRMV(w)
        threshdetect(w) 
        peakdetect(w, AmpThresh)
        ISI(w)
        graphWave(w)
        stats(w)
        
        //to do:
        //ISI or spike rate
        // "stats" function, that calculates the mean and standard deviation of all the calculated values and then outputs them into the final results wave 
       // threshold voltage
       // spike amplitude
       // spike half width
       // AHP amplitude
       // AHP duration
       // spike rate
       // ISI
       // ISI standard deviation
       // RMP
       
        
End

//************************************************


Function threshdetect(w) //wave "times" and wave "values" contain the timing and voltage values of the detected AP thresholds

        Wave w
        Differentiate w/D=diffWave
        
    Smooth 10, diffWave

        
        Wave diffWave
        FindLevels/EDGE=1/M=.05/Q/DEST=threshTimes diffWave 5
            
        
        Make /O/D/N=(numpnts(threshTimes)) threshValues
        variable pos
        variable threshpoint
        
        for(pos=0;pos<=(numpnts(threshValues));pos+=1)
            threshpoint= x2pnt(w,threshTimes[pos])
            threshValues[pos]=w[threshpoint]
        endfor
        
        variable i
       
       //get rid of detections resulting from noise
        variable diff1point
        variable diff2point
        
        Make/O/D/N=0 times
        Make/O/D/N=0 values
        
        for (i=0;i<=(numpnts(threshTimes));i+=1)
            
            diff1point = x2pnt(diffWave, threshTimes[i])
            diff2point = diff1point + 30
            
            if(diffWave[diff2point]>20)
                Insertpoints numpnts(times),1,times
                times[numpnts(times)]=threshTimes[i]
                Insertpoints numpnts(values),1,values
                variable valuefinder = x2pnt(w,times[numpnts(times)])
                values[numpnts(values)]=w[valuefinder]
                
            endif
        endfor
                
end

//*************************************************

Function findRMV(w) 
        wave w 
 
        Variable minVoltage = -.090 //lower limit for RMP 
        Variable maxVoltage = -.040 // upper limit for RMP 
        Duplicate/O w $"restVals" 
        Wave restVals 
        variable ic 
 
        for(ic = 0; ic < numpnts(w); ic+=1) // can set to 3 to 3.5 s (in points) for current step protocol 
                if(w[ic]<maxVoltage && w[ic] > minVoltage) 
                restVals[ic]=w[ic] 
                else 
                restVals[ic]=NaN 
                endif 
        endfor 
         
        Duplicate/O restVals $"RMPWave" 
        Wave RMPWave 
         
        Curvefit /Q/N/NTHR=0 line restVals /D=RMPWave  
         
        if (abs(((RMPWave[numpnts(RMPWave)])-(RMPWave[0]))>.010))  
                print "Error: Significant change in RMP in Wave: "+ NameofWave(w) // detects if the starting and ending RMP are significantly different 
                endif 
 
      end
      
//****************************************************
      
Function peakdetect(w,threshold)

        Wave w
        Variable threshold
        Wave values = root:values

        FindLevels/Q/DEST=crosswave w threshold //finds x coordinate for where wave crosses threshold (up and down i.e. 2 spikes = 4 crossings)

        variable numspikes = numpnts(crosswave)/2

        Make /O/D/N=(numspikes) spikepeaks
        Make /O/D/N=(numspikes) spiketimes
        Make /O/D/N=(numspikes) spikeamps
        Make /O/D/N=(numspikes) AHPtimes
        Make /O/D/N=(numspikes) AHPpeaks
        Make /O/D/N=(numspikes) AHPamplitudes
        Make /O/D/N=(numspikes) AHPendtimes
        Make /O/D/N=(numspikes) AHPendvalues
        Make /O/D/N=(numspikes) AHPdurations
        Make /O/D/N=(numspikes) halfwidths
        Wave times = root:times
        Make /O/D/N= (numspikes*2) halfwidthpointsAll
        Make /O/D/N= (numspikes*2) halfwidthpointsAllvalues

        Variable peak
        Variable peaktime
        Variable peaktimepoint
        variable i
        variable pos=0 //effectively spike #, ie first spike pos = 0
        wave RMPWave = root:RMPWave
        variable amplitude
        variable halfamp
        variable halfampvoltage
        variable halfwidthleftpos= 0 
       
        Wave diffWaveCrossWave //from threshdetect()

        for (i=0;i<numpnts(crosswave);i+=2)
                Variable xUp = crosswave[i]
                Variable xDown=crosswave[i+1]
                WaveStats/Q/R=(xUp,xDown) w
                peak = V_max
                peaktime = V_maxloc
                peaktimepoint= x2pnt(V_maxloc,w)
                Spikepeaks[pos]=peak
                spiketimes[pos]=peaktime
                
                amplitude = peak - values[pos]
                halfamp = amplitude/2
                spikeamps[pos]= amplitude
                halfampvoltage = values[pos] + halfamp
                
                AHP(pos,0.030,spiketimes[pos],w)
                AHPcurvefit(w,AHPtimes[pos],pos)
                Findlevels/Q/R=(times[pos],AHPtimes[pos])/DEST=halfwidthpoints w halfampvoltage // halfwidth finder
                
               
             	  halfwidths[pos] = halfwidthpoints[1]-halfwidthpoints[0]
                halfwidthpointsAll[halfwidthleftpos] = halfwidthpoints[0]
                halfwidthpointsAll[halfwidthleftpos+1]= halfwidthpoints[1]
                halfwidthpointsAllvalues[halfwidthleftpos] = halfampvoltage
                halfwidthpointsAllvalues[halfwidthleftpos+1] = halfampvoltage
                halfwidthleftpos +=2
                
                
                pos+=1
                

        endfor
End

//**********************************************************

Function AHP(p,searchRight,peaktime,w)

        //parameters
        Variable p //position holder, see peakdetect
        Wave w
        Variable searchright //defines right limit of window to search for AHPpeak. May not work optimally.
        Variable peaktime //contained in wave made by spikepeak()
        
        Wave AHPtimes = root:AHPTimes
        Wave AHPpeaks = root:AHPpeaks
     Wave AHPamplitudes=root:AHPamplitudes
     Wave values=root:values
     
        //Internal variables
        Variable AHPpeakvalue
        Variable AHPpeaktime
        Variable AHPamplitude


        WaveStats/Q/Z/R=(peaktime,peaktime+searchright) w

                AHPpeakvalue = V_min
                AHPpeaktime = V_minloc
                
                AHPtimes[p]=AHPpeaktime
                AHPpeaks[p]=AHPpeakvalue
                AHPamplitudes[p]= AHPpeaks[p]-values[p]
                
              
End

//*********************************

Function compareValues(w1,w2,x)  ///

    Wave w1 //wave1
    Wave w2 //wave2
    Variable x
    
    if (w1[x]>=w2[x])
        return 0
    else
        return 1
    endif
        
end

Function AHPCurvefit(w,peaktime, p)

    Variable p //position holder, see peakdetect
    Wave w
    Variable peaktime
    Wave AHPtimes = root:AHPtimes
    Wave AHPendtimes=root:AHPendtimes
    Wave AHPendvalues=root:AHPendvalues
    Wave AHPdurations = root:AHPdurations
    
    Variable peakpoint= x2pnt(w, peaktime)
    
    variable i
    
    
    for (i=peakpoint;i<=numpnts(w);i+=1)
        variable pastRMV = compareValues(RMPwave, w, i)
        if (pastRMV>0)
            AHPendtimes[p]=pnt2x(w,i)
            AHPdurations[p]=AHPendtimes[p] - peaktime
            AHPendvalues[p]=w[i]
            break
        Endif
    Endfor
    
End

Function ISI(w)
	Wave w
	Wave spiketimes=root:spiketimes
	Make/O/D/N=(numpnts(spiketimes)-1) spikeintervals
	
	variable i
	variable n=0
	
	for (i=0;i<numpnts(spiketimes);i+=1)
		variable interval
		interval = spiketimes[i+1]-spiketimes[i]
		if (interval>0)
			spikeintervals[n]=interval
			n+=1
			endif
		endfor
	
End
		
		


Function graphWave(w)

wave w

//Display all calculations on top of source wave
Display w; AppendToGraph spikepeaks vs spiketimes; AppendToGraph values vs times; AppendToGraph AHPpeaks vs AHPtimes; AppendToGraph AHPendvalues vs AHPendtimes; AppendToGraph halfwidthpointsAllvalues vs halfwidthpointsAll

// Use markers instead of lines

ModifyGraph mode(spikepeaks)=3,marker(spikepeaks)=17;
ModifyGraph rgb(spikepeaks)=(4369,4369,4369),mode(values)=3,marker(values)=32;
ModifyGraph rgb(values)=(0,0,0),mode(AHPpeaks)=3,marker(AHPpeaks)=23;
ModifyGraph rgb(AHPpeaks)=(4369,4369,4369),mode(AHPendvalues)=3;
ModifyGraph marker(AHPendvalues)=46,rgb(AHPendvalues)=(0,0,0);
ModifyGraph mode(halfwidthpointsAllvalues)=3,marker(halfwidthpointsAllvalues)=4;
ModifyGraph rgb(halfwidthpointsAllvalues)=(0,0,0)

TextBox/C/N=text0/F=0 nameofwave(w)

End

Function Stats(w)

	Wave w
	
	Wave spikepeaks= root:spikepeaks
	Wave spimetimes= root:spiketimes
	Wave spikeamps =root:spikeamps
       Wave AHPtimes=root:AHPtimes
       Wave AHPpeaks= root:AHPpeaks
       Wave AHPamplitudes=root:AHPamplitudes
       Wave AHPendtimes=root:AHPendtimes
       Wave AHPdurations = root:AHPdurations
       Wave values = root:values
     
     	
	variable column =1
	variable labels=1
	variable row = 1 // will go in driver, advance row for new wave 

	Make/O/N=(1,16) statsWave //goes in driver
	Make/O/T/N=(1,16) indexWave //goes in driver, will hold names of each wave and title of each column
	
	indexWave[row][0]=nameofwave(w)
	statswave[0][]=0
	statswave[][0]=0
	InsertPoints 0,1, statsWave
	InsertPoints 0,1, indexWave
	


	//spike amplitude
	indexWave[0][labels]= "Spike Amplitude(mean)"
	labels+=1
	
	Wavestats/Q spikeamps
	statsWave[row][column]=V_avg
	column+=1
	
	indexWave[0][labels]= "Spike Amplitude(stdev)"
	labels+=1
	statsWave[row][column]=V_sdev
	column+=1
	
	//spike threshold
	indexWave[0][labels]= "Threshold"
	labels+=1
	
	Wavestats/Q  values
	statsWave[row][column]=V_avg
	column+=1
	
	indexWave[0][labels]= "Threshold(sdev)"
	labels+=1
	statsWave[row][column]=V_sdev
	column+=1
	
	//half widths
	indexWave[0][labels]= "Spike Half-Width"
	labels+=1
	
	Wavestats/Q  halfwidthpointsAllvalues
	statsWave[row][column]=V_avg
	
	column+=1
	indexWave[0][labels]= "Spike Half-Width(sdev)"
	labels+=1
	statsWave[row][column]=V_sdev
	column+=1
	
	//AHP amplitude
	indexWave[0][labels]= "AHP Amplitude"
	labels+=1
	
	Wavestats/Q AHPamplitudes
	statsWave[row][column]=V_avg 
	column+=1
	indexWave[0][labels]= "AHP Amplitude(sdev)"
	labels+=1
	statsWave[row][column]=V_sdev 
	column+=1
	
	
	// AHP duration
	indexWave[0][labels]= "AHP duration"
	labels+=1

	Wavestats/Q AHPdurations
	statsWave[row][column]=V_avg
	column+=1
	indexWave[0][labels]= "AHP duration(sdev)"
	labels+=1
	statsWave[row][column]=V_sdev
	column+=1
	
	//RMP
	Wavestats/Q RMPwave
	indexWave[0][labels]= "RMP"
	labels+=1
		
	statsWave[row][column]=V_avg
	column+=1
	
	
	// # spikes
	indexWave[0][labels]= "# spikes"
	labels+=1

	statsWave[row][column]=numpnts(spikepeaks)
	column+=1
	
	// spike rate
	indexWave[0][labels]= "Spike rate (hz)"
	labels+=1

	variable waveduration
	variable lastpoint = numpnts(w)
	waveduration = pnt2x(w,lastpoint)
	statsWave[row][column]=(numpnts(spikepeaks))/waveduration
	column+=1
	
	//spike interval
	// AHP duration
	indexWave[0][labels]= "Interspike Interval (avg)"
	labels+=1

	Wavestats/Q spikeintervals
	statsWave[row][column]=V_avg
	column+=1
	
	indexWave[0][labels]= "Interspike Interval(sdev)"
	labels+=1
	statsWave[row][column]=V_sdev
	column+=1
	
	
	

End
