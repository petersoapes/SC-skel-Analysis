//rewrite of current macro to print out SC data
//28dec16 most current macro
//TODO
//add another approval, category assignmented after blob2
//find a way to delete all SC's smaller than a certain threshold

run("Set Scale...", "distance=0 known=0 global");//remove previous scales
T = getTitle;
selectWindow(T);
run("Duplicate...", "title=duplicate duplicate");
selectWindow(T);
run("Stack to Images");

// cache image names
selectImage(2);
redImage = getTitle();
selectImage(3);
greenImage = getTitle();
selectImage(4);
blueImage = getTitle();

imageCalculator("and", greenImage, redImage);
setAutoThreshold("Shanbhag dark");
setOption("BlackBackground", true);
fociChannel = getTitle();
//remove more of the windows

//work on centromeres
selectWindow(blueImage);
run("Threshold...");
waitForUser("Step 1, Thresholding", "Adjust threshold for centromere signal then press OK" );
run("Convert to Mask");
run("Despeckle");
run("Dilate");
run("Analyze Particles...", "  show=Outlines display exclude summarize add");
IJ.redirectErrorMessages()
centromereX = newArray();
centromereY = newArray();
for(i=0;i<roiManager("count");i++){
	roiManager("select",i);
	x = getResult("X", i);//from result page
	centromereX = Array.concat(centromereX, x);
	y = getResult("Y", i);
	centromereY = Array.concat(centromereX, y);
	cIndex = i+1; //cIndex = i+1;
	roiManager("Rename", roiManager("index") + "_centromere "+ cIndex);//cIndex
	Roi.setProperty("obj_class", "centromere");
	Roi.setProperty("cent_indx", i);
	roiManager("update");//roi must be selected again
	roiManager("select",i);
}
//setBatchMode("hide");
centromereCount = roiManager("count");//centromere indices
print("end blue channel processing. centCount: "+centromereCount);
//end blue channel processing

//start green channel processing
print("processing green channel");
wait(500);
//selectImage(2);
selectWindow(greenImage);
run("Threshold...");
waitForUser("Step 1, Thresholding", "Adjust threshold for foci signal then press OK" );
//run("Convert to Mask");
run("Analyze Particles...", "size=4-Infinity display exclude summarize add");//size=6 also works well
//setBatchMode("hide");
//label foci
fociCount = 0;
allfociX = newArray();
allfociY = newArray();
for(f=centromereCount;f<roiManager("count");f++) {
	fociCount++;
	roiManager("select", f);
	Roi.setProperty("paired", false);//setting this property to for further blobject
	roiManager("Rename", roiManager("index")+ "foci "+ fociCount);//renaming to keep track of rois
	setResult("FociIndex",f, fociCount);
	//add to foci coordinates
	Roi.getCoordinates(fx, fy);
	Array.concat(allfociX, fx);
	Array.concat(allfociY, fy);
}//end green channel processing

//process red channel (SC)
selectWindow(redImage);
run("Threshold...");
waitForUser("Step 1, Thresholding", "Adjust threshold for foci signal then press OK" );

wait(500);
//results very full, and these measures aren't needed
//selectWindow('Results');////i don't think windows should be closed from within a function
//run("Close");//results must be  'R'
//this might not be working

run("Convert to Mask");
//run("Dilate");
run("Despeckle");
//run("Skeletonize"); // skeleton may not be best for the ridge detection 
run("Invert LUT");//activating the LUT allows ridge detection to be run
// Requires the Ridge Detection plugin from the Biomedgroup update site.
wait(500);
//run("Ridge Detection", "line_width=2 high_contrast=255 low_contrast=240 add_to_manager");
run("Ridge Detection", "line_width=2 high_contrast=255 low_contrast=240 extend_line show_junction_points show_ids displayresults add_to_manager method_for_overlap_resolution=SLOPE sigma=1.2 lower_threshold=16.83 upper_threshold=40");
//sigma 1.2, lower 16.83, upper 40
setBatchMode("hide"); // hide the UI for this computation to avoid unnecessary overhead


//error throwing here. 1 item not selected

//rename all the SC
scCount = 0;
JPcount = 0;
for(o=centromereCount;o<roiManager("count");o++){ //roimanager error after RD, requires one item to be selected
	roiManager("select", o);
	if (startsWith(Roi.getName(), "C")) {
			roiManager("Rename", roiManager("index") + "SC ");
			scCount++;
			}
			//delete JPs, to clean up screen
		//print("start red channel. sc count: "+ scCount + ". blobcount: "+blobcount+". stuff in manager: "+roiManager("count"));
		//rename SC, delete JPs, set SC length property
		//for(i=centromereCount;i<roiManager("count");i++){
			
	if (startsWith(Roi.getName(), "JP-")) {
		roiManager("delete");
		//o--;
		roiManager("select",roiManager("count")-1); // JP items are not being deleted
		//select another item?
		//deleting without selecting the next thing causes an error
		}//when changed to count-1, the roi manager error 
}
//run("Tile");
selectWindow(redImage);
run("Close"); 
selectWindow(greenImage);
run("Close"); 
selectWindow(blueImage);
run("Close"); 
//delete all but dpulicate

selectWindow("duplicate");//not sure this is selecting correctly any more
setTool("zoom");
run("In [+]");
run("In [+]");
waitForUser("Paused to poke around");		

y=100;
while(y>1){	
//add another option to pause an poke around
	Dialog.create("Fix pieces from Ridge Dection");//need crete before options can be added
	Dialog.addChoice("Choose edit method", newArray("Cleave", "Stitch", "finish", "poke"));	
	Dialog.show();	
	status1 = Dialog.getChoice();
	if(status1=="Cleave"){
		waitForUser("click on point to cleave");
		Dialog.create("Cleave step. Choose line to cleave. Click on point to cleave.");
		Dialog.show();		
		setTool("point");		
		getSelectionCoordinates(cleave_pointx, cleave_pointy); // these cleavage points fill in correctly
		print("cleave point x "+ cleave_pointx[0]);
		print("cleave point y "+ cleave_pointy[0]);
		Dialog.create("enter roi index");
		Dialog.addNumber("roi index", 0);//parameter
		Dialog.show();
		roi = Dialog.getNumber();			
		print("cleaving");
		Cleave(roi, cleave_pointx[0], cleave_pointy[0]);
		//delete choosen roi here -- and run re-sorting and renaming outside of the functions
		roiManager("update"); //updateDisplay()?		
	}
	if(status1=="Stitch"){
//	enter numbers for SC1 SC2, wait for user cent x, cent y
//this doesn't seem to be working
		Dialog.create("starting the Stitching process. click on centromere"); // asses if centromere rois are in yet
		Dialog.show();
		waitForUser("choose SC pieces to join. Centromere SC first");
		Dialog.create("choose SC pieces to join. Centromere SC first");
		Dialog.addNumber("centromere", 0);
		Dialog.addNumber("first", 0);
		Dialog.addNumber("second", 0);
		Dialog.show();
		cent_indx = Dialog.getNumber();
		first = Dialog.getNumber();;
		sec = Dialog.getNumber();;;
		Stitch(first, sec, cent_indx);
		roiManager("update");
	} //go back to menu
	if (status1=="poke") {
		waitForUser("paused for poking around");
		
	}
	//function Stich(SC1, SC2, cent_x, cent_y){
	if(status1=="finish") {
					y=0;
			}		
}//while loop				
//end RidgeDetection clean up, start Blobject construction		
//

//SC rename  ridge detection items not being renamed
blobcount = 0;
JPcount = 0;
print("start red channel. sc count: "+ scCount + ". blobcount: "+blobcount+". stuff in manager: "+roiManager("count"));
//rename SC, delete JPs, set SC length property
for(i=centromereCount;i<roiManager("count");i++){
	roiManager("select",i);
	if (startsWith(Roi.getName(), "JP-")) {
		roiManager("delete");
		i--;
	}
	else {
		if (startsWith(Roi.getName(), "SC")) {
			scCount++;
			//roiManager("Rename", roiManager("index") + "SC "); // edit renamed above
			roiManager("measure");
			sclength = getResult("length",i);
			Roi.setProperty("SC Results length", sclength); // this is a property of the SC
			setResult("SC index", i, roiManager("index")); // link to SC roi index
			}//length measured here, this info might be lost in later lines
		}
	}
print("SC count: "+scCount);

//loop through centromeres, find overlapping SC, form blobjects
for(cen=0;cen < centromereCount;cen++){
	roiManager("Select",cen);
	if(matches(Roi.getName(), ".*centromere.*")) {
		makeBlob(cen);
	print("this is cen " + cen);
	//print("move through non cen loop");
	roiManager("update");
	blobcount++;
		}
}
print("finished centromere pairing. "+ blobcount+ "   is blobcount");	

//move delete array step into the Purge function
delete_array = newArray('first', 0); // if delete_array is empty, all rois will be deleted
selectImage(1); //1 should be the duplicate
//selectWindow(duplicate);//select window throws error
for(approv1=roiManager("count")-1; approv1 > centromereCount+fociCount+scCount-1; approv1--){
		roiManager("Select", approv1);
		print("Confirm blobs. Checking blobs " + approv1 +"  "+Roi.getName());
		waitForUser("Step 2: Blob Approval. Paused for adjustment."+ "\n"+
		""+"\n"+"");		
		
		if(matches(Roi.getName(), ".*blob.*")) {  //might be throwing error	
			selectWindow("duplicate");//
			roiManager("Select", approv1);//this should higlight roi on activated window
			Dialog.create("Blobject Manager");
			Dialog.addChoice(Roi.getName()+": ", newArray("Accept blob", "delete", "XY", "poke"));
			Dialog.show();		
			status = Dialog.getChoice();
			if(status=="Accept blob") {
	//soo.. nothing happens yet when blobs are approved
				roiManager("Select", approv1);
				Roi.setProperty("blob_class", "blob");
			} if(status=="XY") {
				roiManager("Select", approv1);
				Roi.setProperty("blob_class", "XY");//this label is not translating into the 2CO...
				print('setting property to XY: '+ Roi.getProperty("blob_class") );
			
			}if(status=="poke"){
				waitForUser("paused for poking around");
			}
			if(status=="delete") {
				roiManager("Select", approv1);
				delete_array = Array.concat(approv1);
				Roi.setProperty("blob_class", "delete");
			}//error might be generated here, because a single thing isn't selected
		}								
    }
//2nd automation step --- added foci, 
//1st approval step, approve complete blobjects
//2nd arroval step, make new blobjects

//make new blobjects
setTool('wand');
waitForUser("Step 3: Make new blobs"); //for createing blobs that the computer doesn't recognize and 
count_before = roiManager("count")-1;

y=100;
while(y>1){
	Dialog.create("Step 3: Blob Creation");
	Dialog.addChoice("Create more blobjects?", newArray("new blob", "stitch", "finish", "poke")); 
// add edit for stitching SC to make more blobjects
	Dialog.show();
	more_blobs = Dialog.getChoice();
	if(more_blobs=="new blob") {
		waitForUser("Step 3: Check elements to create new blob");
		Dialog.create("Assign Blob indeces");
		Dialog.addNumber("centromere index", 0);
		Dialog.addNumber("SC index", 0);//TODO, add more than 1 SC piece
		Dialog.show();
		cent = Dialog.getNumber();
		sc = Dialog.getNumber();;	
		makeBlob2(cent, sc);//might be throwing an error
		roiManager("update");
		} 
//stitch should be applied to SC's not blobject
	if(more_blobs == "stitch"){	
		//create windows to get required input.		
		///run stich function,   SC1, SC2		
		//Stich(
	}
	if(more_blobs == "poke"){
//pause window to poke arround
		waitForUser("paused for poking around");
	}
	else if(more_blobs=="finish"){
  			y=0;
      }
}
print("finished making new blobs");

wait(50);
//
//this second approval step doesn't seem to be activating
//add at last approval step before final printing. mostly 
//first step, approve, delete or reafirm XY
//this should go through all blobjects
//aprv2 = 0;

aprov2_indx = (roiManager("count")-1) - count_before; 
q=100;
print("start second approval match");//this prints, 
//aproval skipped
//while(q>1){	//this causes the menu to stall on a single biv
Dialog.create("Approve 2 menu");
for(aprv2= 0; aprv2 > roiManager("count")-1; aprv2++){
	roiManager("Select", aprv2);
	if(matches(Roi.getName(), ".*blob.*")) {
		Dialog.create("Approve 2 menu");
		Dialog.addChoice("Final approval step", newArray("Approve", "XY", "Delete", "finish"));	
		Dialog.show();
		status2 = Dialog.getChoice();			
//only select rois for <non deleted> rois
		print("Confirm blobs. Checking blobs " + aprv2 +"  "+Roi.getName());
		waitForUser("Step 2: Blob Approval. Paused for adjustment."+ "\n"+""+"\n"+"");
		if(status2 =="Approve"){
		//don't do anything	
			}
		if(status2 =="XY"){
			roiManager("Select", aprv2);
			Roi.setProperty("blob_class", "XY");//this label is not translating into the 2CO...
			print('setting property to XY: '+ Roi.getProperty("blob_class") );
			}
		if(status2 =="Delete"){
			delete_array = Array.concat(aprv2);
			Roi.setProperty("blob_class", "delete");
			}
		if(status2 =="finish"){
				//q=0;
				}
			}
		}
//}		
//create Blobjects, blobs + foci
print("starting to add foci to blobs to make blobjects");
for(ber=roiManager("count")-1; ber > centromereCount+fociCount+scCount-1; ber--){
	blob_foci_array = newArray();//this is counter for multiple foci on the same blobject
	blob_foci_pos_array = newArray(); // this is supposed to hold positions/indeces for multiple foci
	roiManager("Select", ber);	
	print("start foci adding, on blob "+ber);
	if(matches(Roi.getName(), ".*_blo.*")){
//stop the makeBlobject for the SC skel. 
	//	makeBlobject(ber);//first time function called
	}else{
		continue;
	}
}

//remove IFD from this macro
wait(500);
//IFD calculation
//cycle through blobjects, if class 2CO or 3CO start IFD measures
for(ifd=blobcount; ifd < roiManager("count"); ifd++){ //blobcount might be 2x times as much
	roiManager("Select", ifd);
	//print("calculating IFD of " + Roi.getName());
	OB = Roi.getProperty("blob_class");
	if(OB == "2CO"){
		pos1 = Roi.getProperty("prox foci position");
		pos2 = Roi.getProperty("distal foci position");
		print(pos2 + " minus "+pos1);
		IFD = abs(parseFloat(pos2) - parseFloat(pos1));
		print(IFD);
		Roi.setProperty("IFD", IFD);
	}
}
wait(500);
selectWindow("Junctions"); 
run("Close"); 
selectWindow("Results"); 
run("Close"); 
selectWindow("Summary"); 
run("Close"); 
//main file
//print SC totals to the biv length file
print("running SC total function");
c = SC_totals();

//f = File.open("");
f = File.open("/Users/alpeterson7/Documents/imageAnalysis/hand measures/G male/"+T+".txt");//title
//f = File.open("/Users/April/Desktop/"+T+".txt"); // create unique file for each image -- with title of image.
print(f,"image title"+"\t"+"blobject name"+"\t"+"SClength results"+"\t"+"SC length array"+"\t"+"correct"+"\t" +"blobjectClass"+"\t"+"reverse"+
"\t"+"IFD"+"\t"+"prox foci position"+"\t"+"distal foci position"+"\t"+"notes");
//
print("about to delete delete_array ");
printArray(delete_array);
//roiManager("select", delete_array); //if delete array is empty, everything deleted
//roiManager("delete");

//prevent delete_array blobjects from being printed
for(bb =roiManager("count")-blobcount-1; bb < roiManager("count"); bb++){
	roiManager("select", bb);
	if(matches(Roi.getName(), ".*blo.*") && !delete_array) { //the anti delete array isn't workign
	print("properties test: "+Roi.getName()+"  :"+Roi.getProperties());//position of foci not as 
//correct the reverse values
	//Array.reverse() // is a ready made function
	rev_val = Roi.getProperty("reverse");
	print("rev value is "+rev_val);
	prox_foci = Roi.getProperty("prox foci position");
	distal_foci = Roi.getProperty("distal foci position");
		
	print(f, T+"\t" + Roi.getName() + "\t" 
	 + Roi.getProperty("SC Results length") + "\t"
	 + Roi.getProperty("SC array length")+"\t"
	 + "\t"
	 + Roi.getProperty("blob_class") + "\t" 
	 + Roi.getProperty("reverse") + "\t"
	 + Roi.getProperty("IFD") + "\t"
	 + prox_foci + "\t"
	 + distal_foci);
	
	}
	//do not print in this loop, it will repeat for each line	

}
print(f, "\n" +T + "\t" + "Autosome SC skel total" + "\t" +"XY SC skel total");
print(f, T + "\t" + c[0] +"\t"  + c[1]);
print(f,  T+"\t"+c[2]+"\t"+c[3]);
//close f file
File.close(f);


//check all roi properties
wait(500);
for(bbb = 0; bbb < roiManager("count"); bbb++){
	roiManager("select", bbb);
	if(matches(Roi.getName(), ".*blobject.*")) {
		print("properties test: "+Roi.getName()+"  :"+Roi.getProperties());
	}
}

///functions
function printArray(a) {
      print("");
      for (i=0; i<a.length; i++)
          print(i+": "+a[i]);
  }
function reverseArray(a) {
      size = a.length;
      for (i=0; i<size/2; i++) {
          tmp = a[i];
          a[i] = a[size-i-1];
          a[size-i-1] = tmp;
       }
  }//end function  


//function below seems to be working!! //function (cen,[SC]) optional -- if variable for SC is enter -- skip to join
function makeBlob(cen){
	roiManager("Select", cen); 
	Roi.getCoordinates(centx, centy);
	roiManager("deselect");
//function for cycling through rois with certain name cycle(regex)? 
	for(noncen=centromereCount+fociCount; noncen < roiManager("count"); noncen++) { // make sure these counters will work in function format
//all x and y coordinates
	//deselect cent
		roiManager("Select", noncen); //select roi to test if SC
		if(matches(Roi.getName(), ".*SC.*")) { //test if this is selecting splines from Cleave
			//measure and extract length information
			//delete result window..?
			run("Measure");
			//selectWindow('Results');////i don't think windows should be closed from within a function
			//run("Close"); //closing this window is throwing a non-selection error
			print("the number of results before error: " + nResults);
  			SClength = getResult('Length', nResults-1);//throwing error			
			Roi.getCoordinates(SCx, SCy);
				paired=false;
				//rev=false; // not sure if this should be rev
				for(k=0; k < centx.length && !paired; k++){  //k pixels in centromere
						if(Roi.contains(centx[k], centy[k])) {
		 						roiManager("Select", cen);
								if(Roi.contains(SCx[0], SCy[0])) {  //if cent contains begining of SC
									//SC and cent are properly alligned
									print(cen + " " + noncen + "SC array starts at centromere");
										}
								if(Roi.contains(SCx[SCx.length-1], SCy[SCy.length-1])) { //if cent contains end of SC
									print(cen + " " + noncen + "centromere is at end of array. array reversed");
									SCx = Array.reverse(SCx);
									SCy = Array.reverse(SCy);
									//rev=true;
									}
		 						roiManager("select", noncen); //selecting the current sc
		 						run("Measure");
								length1 = getResult('Length', nResults-1);	//don't know why there are two property assignments of Length from Results...						
								Roi.setProperty("SC Results length", length1);//SC Results Length
		 						
		 						print("the SC length from the SC is "+SClength);
		 						blob_parts = Array.concat(cen, noncen);//noncen = SC
		 						
		 						roiManager("Select", blob_parts);//roiManager("Select", newArray(cen, noncen)) doesn't work
		   						roiManager("Combine");
								roiManager("Add");
								roiManager("deselect");
								roiManager("Select", roiManager("count")-1); //select the new roi
								roiManager("Rename", roiManager("index")+"_blob");
								//if(rev == true){
									//Roi.setProperty("reverse", '1');//this should be blobject property
								//}
								Roi.setProperty("SC Results length", length1);//this is zero
								Roi.setProperty("SC length", SClength);
								Roi.setProperty("SC index", noncen);				
								roiManager("update");
								noncen=1000; //break out of loop by overcounting 
								blobcount++;
								paired=true;
					        	}
			            }   	
		       }
			} 
}//end function

//function for making blobject when centromere and SC indeces are provided by user
function makeBlob2(cen, sc){
//this might not be recognizing stiched SC as sc
		roiManager("Select", newArray(cen, sc));// make sure if this is blank it still works
		roiManager("Combine");
		roiManager("Add");
		roiManager("Select", roiManager("count")-1);
		roiManager("Rename", roiManager("index")+"_blob"); 		
  		blobcount++;
  		roiManager("Select", sc);
  		run("Measure");
  		SClength = getResult('Length', nResults-1);//nResults was throwing everything off by 1?
  		Roi.getCoordinates(nSCx, nSCy);
//add code to test if SC array coordinates start in centromere		
		roiManager("Select", cent);
		if(Roi.contains(nSCx[0], nSCy[0])) { //ask if first coordinate is in centromere
			print(cen + " " + sc + "SC array starts at centromere");//no reverse needed
			//Roi.setProperty("reverse", 2);//reverse set to 0 is messing up manual blobjects 
//why should this still be reversed		
		} if(Roi.contains(nSCx[nSCx.length-1], nSCy[nSCy.length-1])) { //ask if last coordinate is in centromere
			nSCx = Array.reverse(nSCx);
			nSCy = Array.reverse(nSCy);
			print(cen + " " + sc + "centromere is at end of array. Array reversed with function");
		}
//why are these called in makeBlob? asking it these are set to centromere
		bc = Roi.getProperty("blob_class");
		ifd = Roi.getProperty("IFD");
		pfp = Roi.getProperty("prox foci position");
		dfp = Roi.getProperty("distal foci position");
  		roiManager("deselect");
  		roiManager("Select", roiManager("count")-1);//assign properties
		print("setting properties of new  blobject "+Roi.getName()); 
//set the same property for macro generated blobjects	
		Roi.setProperty("SC array length", nSCx.length);//this length value might be less accurate than the legnth from results
		Roi.setProperty("SC Results length", SClength);//SC length from results page
		Roi.setProperty("SC index", sc);//maybe doing measure then assign	
  		Roi.setProperty("IFD", ifd);
  		Roi.setProperty("prox foci position", pfp);
  		Roi.setProperty("distal foci position", dfp);
  		roiManager("update");
    }	//end function


function makeBlobject(blob){
	roiManager("Select", blob);
	SCindx = Roi.getProperty("SC index");
	roiManager("Select", SCindx);
	Roi.getCoordinates(SCx, SCy);
//get SC index
	roiManager("deselect");
	print("entered foci function");
	blob_foci_count=0;
	for(nonblobs=centromereCount; nonblobs <roiManager("count")-blobcount;nonblobs++){ // starts at foci
		roiManager("Select",nonblobs);//foci			
		if(matches(Roi.getName(), ".*foci.*")) {
			print("on nonblob "+Roi.getName());
			Roi.getCoordinates(focix, fociy);
			roiManager("deselect");
			roiManager("Select", blob); //select current blob
			fpaired=false;//foci paired status   
			for(h=0; h < focix.length; h++){ //&& !fpaired  allfociX.length//for all foci pixels, check it they are contained in selected blobject
				if(Roi.contains(focix[h], fociy[h])) { //or select current blobject, current centromere and roiManager("and"); //if blobject contains, current foci's current pixel allfociX[h], allfociy[h]		
		 				skel_indx = Roi.getProperty("SC index"); // select the SC skel SC index, of current blob
		 				roiManager("deselect");
		 				roiManager("Select", skel_indx);//select SC
						rev_skel = Roi.getProperty("reverse");
						Roi.getCoordinates(skelx, skely);//blob is selected currently
						print("check if array should be reversed: "+ rev_skel);
						if(rev_skel == '1'){ //rev_skel isn't initialized so this test isn't being performed
							print("blob should be reversed. positions should be reversed");
							reverseArray(skelx);
							reverseArray(skely);
						}
						blob_foci_count++;//this will count all pixels?
		 				print("foci SC match at "+focix[h]+", "+fociy[h]);
						
						blob_foci_pos_array = Array.concat(focix[h],fociy[h]); // this makes position into tiny array
						blob_foci_array = Array.concat(blob_foci_array, nonblobs);//
                        roiManager("Select", blob);
                        bc = Roi.getProperty("blob_class");
						print("checking blob_class: "+ bc);
//new SC length based on array, 						
                        Roi.setProperty("SC array length", skelx.length);
                        Roi.setProperty("foci coodrin x", focix[h]);//these should be blobject properties
                        Roi.setProperty("foci coodrin y", fociy[h]);
						Roi.setProperty("foci positions", blob_foci_pos_array[0]); //don't think I can add array as property
		 				Roi.setProperty("foci indeces", blob_foci_array[0]);//indeces of the foci being added //dont think property can be array					
						roiManager("deselect");
						roiManager("Select", nonblobs);//select current foci
						print("checking  positions");
						print("current blob_foci_count "+ blob_foci_count);
						COcount = 0;
						for(k=0; k < skelx.length; k++){ //alternatively (k = skelx.length; k> 0; k--)
							if(Roi.contains(skelx[k] ,skely[k])){
								print("blobfoci count " + blob_foci_count);
								COcount++;
								blob_foci = Array.concat(blob_foci, nonblobs);//make array of foci for combining into new blobject
								fpaired=true;
								Roi.setProperty("foci index in skel 1", k);
								Roi.setProperty("foci index in skel 2", skelx.length-k);
								print("foci index is "+k + " or " + skelx.length-k+" in SC skel");	
									
									if(blob_foci_count == 1 && bc != "XY"){ 
//move these foci assignment to when blobjects are updated
										roiManager("Select", blob);
										print("blob count of " + blob +" "+ blob_foci_count);
										print("assigning blobject_class to " + blob);
										Roi.setProperty("blob_class", "1CO");
										Roi.setProperty("prox foci position", k);
										roiManager("deselect");
										roiManager("Select", nonblobs);//select foci and cycle through skeleton
										for(u=0; u< skelx.length; u++){ 
											if(Roi.contains(skelx[u] ,skely[u])){//test that foci exsists in skeleton index 
											co1p_pos = skelx[u];
							  				Roi.setProperty("prox foci pos", co1p_pos);
							    				}
											}
										}
										if(blob_foci_count == 2 && bc != "XY"){ //only SC items use this
									roiManager("Select", blob);
									Roi.setProperty("blob_class", "2CO");//not sure why this is not setting
									Roi.setProperty("distal foci position", k); // this might not be right
									roiManager("deselect");
									roiManager("Select", nonblobs);//select foci and cycle through skeleton

									//check for reverse data --- name foci positions differently if this reverser =1
									for(u=0; u< skelx.length; u++){ 
										if(Roi.contains(skelx[u] ,skely[u])){  //test that foci exsists in skeleton index 
										co2p_pos = skelx[u];
							  			Roi.setProperty("distal foci pos", co2p_pos);
							 		   }
									}
								}
								fpos = k;
								k=1000; //skip through other pixels		
								} else {
									//print("foci roi did not contain skel pixels");
								}
							}//for all the skeletons
		 				//try inserting updateBlobject here
		 				blob_foci = Array.concat(blob, nonblobs);
		 				roiManager("Select", blob_foci);
	   					roiManager("Combine"); // this function is merging foci into the blobject
						//printArray(blob_foci);
						print(Roi.getName()+"_blobject updpdated!");
						roiManager("deselect");
						roiManager("Select", blob);
						roiManager("Rename", roiManager("index")+"blobject");
//enter SC length here?						
						
						//fpaired=true;
						h = 5000; //break out of loop
						roiManager("update");
		  			 } 	else {
							continue;
						}
						roiManager("update");			
		 			 }//cycle through foci						   
				} else{  //foci test
		continue;
	}
		}//nonblob loop
	print("progress through nonblob loop");
	roiManager("update");
	print("end blob loop");		
		}//blob loop		
//end function

function Cleave(choosen_roi, CleavePointx, CleavePointy) { 
//after JPs are delted using another cleave, renders thing out of range
roiManager("Select",choosen_roi);//this get out of range
Roi.getSplineAnchors(Sx, Sy);
print("spline anchor length "+Sx.length);
roiManager("Select",choosen_roi);

NwAx = newArray(Sx.length);
NwAy = newArray(Sx.length);

counter = 0;
for (g=0; g < Sx.length; g++){ //g counter should start as 0
	counter++;
	found = isNear(cleave_pointx[0], cleave_pointy[0], Sx[g], Sy[g], 1); 
	if(found == false){
		NwAx[g] = Sx[g];
		NwAy[g] = Sy[g];
	}
	if(found== true){
		//stop the array buillding, exit the 
		print(NwAx[g]);
		print("stop array");
		g=Sx.length; // this breaks out of the loop! but if 
	}      	
}
NwAx -1;//NwA arrays are no longer nessecary -- just the cleave point in array
NwAy -1;

piece1_NwAx = Array.trim(Sx, counter-1);
piece1_NwAy = Array.trim(Sy, counter-1);//old method NwAy
Roi.setPolylineSplineAnchors(piece1_NwAx, piece1_NwAy);
roiManager("add & draw");// this draws splines
roiManager("Select",roiManager("count")-1);
roiManager("Rename", roiManager("index")+"SC_cleave piece");//makeBlob tests name for .*SC*.
roiManager("deselect");

piece2_NwAx = Array.trim(Array.reverse(Sx), Sx.length-counter-1);//this creates the two pieces!!
piece2_NwAy = Array.trim(Array.reverse(Sy), Sx.length-counter-1);
//find a way to delete the old SC piece and sort object back to the top

Roi.setPolylineSplineAnchors(piece2_NwAx, piece2_NwAy); // this is doing something, don't think it is creating a new ROI
roiManager("add & draw");// this draws splines
roiManager("Select",roiManager("count")-1);
roiManager("Rename", roiManager("index")+"cleave_piece");
//roiManager("Select",choosen_roi);
//roiManager("delete");//can't delete here. this messes up naming. choosen roi should be deleted outside of function
roiManager("Select",0); // see if this fixes the no actiev selection issue
}//end cleave function

function Stitch(SC1, SC2, cent){
roiManager("Select", SC1);
Roi.getSplineAnchors(Rspx, Rspy);
//based on centromere location, find order of spline array
roiManager("Select", cent);
cent_test = Roi.contains(Rspx[0], Rspy[0]); //cent_near_0 = isNear(Rspx[0], Rspy[0], cent_x[0], cent_y[0], 5); old method
if(cent_test == 1){
	print("array order matches centromere location");
} if(cent_test == 0){
	print("reversing SC array order");
	Rspx = Array.reverse(Rspx);
	Rspy = Array.reverse(Rspy);
}
roiManager("Select", SC2);
Roi.getSplineAnchors(Sspx, Sspy);//spline coordinates of second
// test which sec SC end is near the fist SC
second_end = isNear(Rspx[Rspx.length-1], Rspy[Rspy.length-1], Sspx[0], Sspy[0], 6);
if(second_end == true){
	print("first end near sec begining"); // this is the correct ordering I want
	Cat_array_x = Array.concat(Rspx,Sspx); //first correct order, second correct order
	Cat_array_y = Array.concat(Rspy,Sspy);
} if(second_end == false){
	print("first end near sec end");
	//reverse sec array
	Sspx = Array.reverse(Sspx);
	Sspy = Array.reverse(Sspy);

	Cat_array_x = Array.concat(Rspx,Sspx);
	Cat_array_y = Array.concat(Rspy,Sspy); //
}
//use the above information to infor the concat ordering!!

Roi.setPolylineSplineAnchors(Cat_array_x, Cat_array_y);
roiManager("add & draw");
roiManager("Select", roiManager("Count")-1);
roiManager("rename", roiManager("index")-1 + "SC stitchtd");//the stitchd were being named incorrectly
roiManager("measure");
length_shape1 = getResult('Length', nResults-1);
}//end Stich function

function isNear(x1,y1,x2,y2, min_distance) {
    if( sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2)) < min_distance) {
        return true;
    } 
return false;
}//end isNear funciton

//added the number of values used for calq the sums
function SC_totals(){
SC_XY_total = 0;
SC_A_total = 0;
SC_A_num =0;
SC_XY_num =0;
for(c=0;c<roiManager("count");c++) {
	roiManager("select", c);
	if(matches(Roi.getName(), ".*blob.*")){
		obj_class = Roi.getProperty("blob_class");
		if(obj_class == "XY"){
			//sc length results aren'y set yet
			XY_rlength = Roi.getProperty("SC Results length");
			XY_length = Roi.getProperty("SC array length");
			SC_XY_total = abs(parseFloat(XY_length) + parseFloat(SC_XY_total));
			SC_XY_num = abs(parseFloat(SC_XY_num)+1);
		} 
//adding the || blob, will allow for calculation of blobs which didn't go through makeblobject		
		if(obj_class == "1CO" || obj_class == "blob"){
			a_rlength = Roi.getProperty("SC Results length");
			a_length = Roi.getProperty("SC array length");
			//print(" 1CO math: " + a_length +" + " + SC_A_total);
			SC_A_total = abs(parseFloat(a_length) + parseFloat(SC_A_total));
			SC_A_num = abs(parseFloat(SC_A_num)+1);	
	}
		if(obj_class == "2CO"|| obj_class == "blob"){
			a_rlength = Roi.getProperty("SC Results length");
			a_length = Roi.getProperty("SC array length");
			//print(" 2CO math: " + a_length + " + " + SC_A_total);
			SC_A_total = abs(parseFloat(a_length) + parseFloat(SC_A_total));
			SC_A_num = abs(parseFloat(SC_A_num)+1);	
		}
		if(obj_class == "3CO"|| obj_class == "blob"){
			a_rlength = Roi.getProperty("SC Results length");
			a_length = Roi.getProperty("SC array length");
			SC_A_total =  abs(parseFloat(a_length) + parseFloat(SC_A_total));
			SC_A_num = abs(parseFloat(SC_A_num)+1);	
		}		
	   }	
	}
     	print("autosomal SC calq: "+ SC_A_total);
	    print("XY SC total calq "+ SC_XY_total);
		print(" A and XY nums are: "+ SC_A_num + " and "+ SC_XY_num);
		sc_skel_array = newArray(SC_A_total, SC_XY_total, SC_A_num, SC_XY_num);
		return sc_skel_array;
}	//end SC total function
