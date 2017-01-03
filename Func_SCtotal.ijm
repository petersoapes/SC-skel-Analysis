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
}	
//this still only adds blobject -- not suprising because this blobject assigns the blob classes

//for(a=0;a<roiManager("count");a++) {
	//roiManager("select", a);
	//print(Roi.getName());
	//Roi.getProperties();
//}
