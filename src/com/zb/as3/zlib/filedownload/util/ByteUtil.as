package com.zb.as3.zlib.filedownload.util
{
	import mx.core.IFactory;

	public class ByteUtil
	{
		
		public function ByteUtil()
		{
		}
		
		public static function convert(bytes:Number):String
		{
			var reChar:String;
			var ratio:Number = 1/1024;
			var b:Number	=	bytes;
			var kb:Number	=	bytes*Math.pow(ratio,1);
			var mb:Number	=	bytes*Math.pow(ratio,2);
			var gb:Number	=	bytes*Math.pow(ratio,3);
			var tb:Number	=	bytes*Math.pow(ratio,4);
			var pb:Number	=	bytes*Math.pow(ratio,5);
			var eb:Number	=	bytes*Math.pow(ratio,6);
			var suffixs:Array	=	["EB","PB","TB","GB","MB","KB","B"];
			var arrs:Array	=	[eb,pb,tb,gb,mb,kb,b];
			for(var i:int=0;i<arrs.length;i++)
			{
				var temp:Number = arrs[i];
				if(temp>1)
				{
					reChar = temp.toFixed(2) + suffixs[i];
					break;
				}
			}
			return reChar;
		}
	}
}