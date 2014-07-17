package weave.utils;

import org.apache.commons.io.FilenameUtils;

public class AWSUtils {

	public enum SCRIPT_TYPE
	{
		STATA, R, UNKNOWN, PYTHON
	}

	public enum OS_TYPE 
	{
		LINUX, OSX, WINDOWS, UNKNOWN
	}
	public static Object transpose(Object array) {

		  if (array instanceof Object[][])
		  {
			  Object[][] array2 = (Object[][]) array;
			  array = null;
			  if (array2 == null || array2.length == 0)//empty or unset array, nothing do to here
				  return array2;
			 
			  int width = array2.length;
			  
			  int height = array2[0].length;
			  
			  Object[][] array_new = new Object[height][width];
			  
			  for (int x = 0; x < width; x++) {
				  for (int y = 0; y < height; y++) {
					  array_new[y][x] = array2[x][y];
				  }
			  }
			  return (Object) array_new;
		  } else
		  {
			return (Object) new Object[0][0];
		  }
	  } 

	public static OS_TYPE getOSType()
	{
		String os = System.getProperty("os.name");

		if(os.toLowerCase().contains("windows"))
		{
			return OS_TYPE.WINDOWS;
		}
		else if (os.toLowerCase().contains("nix") || os.toLowerCase().contains("nux"))
		{
			return OS_TYPE.LINUX;
		}
		else if(os.toLowerCase().contains("mac"))
		{
			return OS_TYPE.OSX;
		}
		else
		{
			return OS_TYPE.UNKNOWN;
		}
	}

	public static SCRIPT_TYPE getScriptType(String scriptName)
	{
		String extension = FilenameUtils.getExtension(scriptName);

		//Use R as the computation engine
		if(extension.equalsIgnoreCase("R"))
		{
			return SCRIPT_TYPE.R;
		}

		//Use STATA as the computation engine
		if(extension.equalsIgnoreCase("do"))
		{
			return SCRIPT_TYPE.STATA;
		}
		
		if(extension.equalsIgnoreCase("PYTHON")){
			return SCRIPT_TYPE.PYTHON;
		}
		else
		{
			return SCRIPT_TYPE.UNKNOWN;
		}
	}

}