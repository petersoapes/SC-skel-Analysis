//jan17 AP.
//function for calculating SC totals, A and XY
//added the return value which is a array of autosomal [0] and XY SC skel values.

//TODO update this to print the length totals as well as array length
//


//these totals are for the whole image, -- no parameters
c = SC_totals(); //c is the 2 item array of autosome and xy skeleton values
print("pulled from function autosomal SC calq: "+ c[0]);
print("XY SC total calq "+ c[1]);
Array.print(c);

function SC_totals(){
SC_XY_total = 0;
SC_A_total = 0;
for(c=0;c<roiManager("count");c++) {
	roiManager("select", c);
	if(matches(Roi.getName(), ".*blobject.*")){
		obj_class = Roi.getProperty("blob_class");
		if(obj_class == "XY"){
			//sc length results aren'y set yet
			XY_rlength = Roi.getProperty("SC Results length");
			XY_length = Roi.getProperty("SC array length");
			SC_XY_total = XY_length + SC_XY_total;
		} 
		if(obj_class == "1CO"){
			//a_length = Roi.getProperty("SC Results length");
			a_length = Roi.getProperty("SC array length");
			//print(" 1CO math: " + a_length +" + " + SC_A_total);
			SC_A_total = abs(parseFloat(a_length) + parseFloat(SC_A_total));	
	}
		if(obj_class == "2CO"){
			//aResult_length = Roi.getProperty("SC Results length");
			a_length = Roi.getProperty("SC array length");
			//print(" 2CO math: " + a_length + " + " + SC_A_total);
			SC_A_total = abs(parseFloat(a_length) + parseFloat(SC_A_total));
		}
		if(obj_class == "3CO"){
			//a_rlength = Roi.getProperty("SC Results length");
			a_length = Roi.getProperty("SC array length");
			SC_A_total = a_length + SC_A_total;
		}		
	   }
	   	
	}
     	print("autosomal SC calq: "+ SC_A_total);
	    print("XY SC total calq "+ SC_XY_total);
		sc_skel_array = newArray(SC_A_total, SC_XY_total);
		return sc_skel_array;
}	

//for(a=0;a<roiManager("count");a++) {
	//roiManager("select", a);
	//print(Roi.getName());
	//Roi.getProperties();
//}
