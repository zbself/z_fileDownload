package com.zb.as3.zlib.filedownload.util
{
	/**
	 * 链接地址解密 <br>
	 * TYPES 链接密文头<br>
	 * DECODES 解密删除字符的正则
	 */	
	public class URLDecode
	{
		//可以再添加,
		private static const TYPES:Array = ["^thunder://","^flashget://","^qqdl://"]; ///thunder:\/\/[A-Za-z0-9\+\/=]*/
		private static const DECODES:Array = [["^AA","ZZ$"],["^\\[FLASHGET\\]","\\[FLASHGET\\]$"],[]];
		public function URLDecode()
		{
		}
		private static function searchTitle(url:String):int
		{
			for (var i:int = 0; i < TYPES.length; i++) 
			{
				var index:int = url.search(new RegExp(TYPES[i],"i"));
				if(index==0)
				{
					return i;
				}
			}
			return -1;
		}
		private static function regVerify(url:String,typeIndex:int):String
		{
			url = url.replace(new RegExp(TYPES[typeIndex],"i"),"");
			url = Base64.decode(url);
			var regs:Array = DECODES[typeIndex];
			if(regs.length)
			{
				for each (var regStr:String in regs) 
				{
					var reg:RegExp = new RegExp(regStr,"im");
					url = url.replace(reg,"");
				}
			}
			return url;
		}
		/**
		 * 暂时支持 迅雷/快车/旋风
		 * @param url 加密地址: thunder://  flashget:// qqdl://
		 * @return 解密地址
		 */		
		public static function decode(url:String):String
		{
			var index:int = searchTitle(url);
			if(index!=-1)
			{
				url = regVerify(url,index);
			}
			 return url;
		}
	}
}
import flash.utils.ByteArray;
class Base64 {
	private static const BASE64_CHARS:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
	public static const version:String = "1.0.0";
	public static function encode(data:String):String {
		// Convert string to ByteArray
		var bytes:ByteArray = new ByteArray();
		bytes.writeUTFBytes(data);
		// Return encoded ByteArray
		return encodeByteArray(bytes);
	}
	public static function encodeByteArray(data:ByteArray):String {
		// Initialise output
		var output:String = "";
		// Create data and output buffers
		var dataBuffer:Array;
		var outputBuffer:Array = new Array(4);
		// Rewind ByteArray
		data.position = 0;
		// while there are still bytes to be processed
		while (data.bytesAvailable > 0) {
			// Create new data buffer and populate next 3 bytes from data
			dataBuffer = new Array();
			for (var i:uint = 0; i < 3 && data.bytesAvailable > 0; i++) {
				dataBuffer[i] = data.readUnsignedByte();
			}
			// Convert to data buffer Base64 character positions and 
			// store in output buffer
			outputBuffer[0] = (dataBuffer[0] & 0xfc) >> 2;
			outputBuffer[1] = ((dataBuffer[0] & 0x03) << 4) | ((dataBuffer[1]) >> 4);
			outputBuffer[2] = ((dataBuffer[1] & 0x0f) << 2) | ((dataBuffer[2]) >> 6);
			outputBuffer[3] = dataBuffer[2] & 0x3f;
			// If data buffer was short (i.e not 3 characters) then set
			// end character indexes in data buffer to index of '=' symbol.
			// This is necessary because Base64 data is always a multiple of
			// 4 bytes and is basses with '=' symbols.
			for (var j:uint = dataBuffer.length; j < 3; j++) {
				outputBuffer[j + 1] = 64;
			}
			// Loop through output buffer and add Base64 characters to 
			// encoded data string for each character.
			for (var k:uint = 0; k < outputBuffer.length; k++) {
				output += BASE64_CHARS.charAt(outputBuffer[k]);
			}
		}
		// Return encoded data
		return output;
	}
	public static function decode(data:String):String {
		// Decode data to ByteArray
		var bytes:ByteArray = decodeToByteArrayB(data);
		// Convert to string and return
		return bytes.readUTFBytes(bytes.length);
	}
	public static function decodeToByteArray(data:String):ByteArray {
		// Initialise output ByteArray for decoded data
		var output:ByteArray = new ByteArray();
		// Create data and output buffers
		var dataBuffer:Array = new Array(4);
		var outputBuffer:Array = new Array(3);
		// While there are data bytes left to be processed
		for (var i:uint = 0; i < data.length; i += 4) {
			// Populate data buffer with position of Base64 characters for
			// next 4 bytes from encoded data
			for (var j:uint = 0; j < 4 && i + j < data.length; j++) {
				dataBuffer[j] = BASE64_CHARS.indexOf(data.charAt(i + j));
			}
			// Decode data buffer back into bytes
			outputBuffer[0] = (dataBuffer[0] << 2) + ((dataBuffer[1] & 0x30) >> 4);
			outputBuffer[1] = ((dataBuffer[1] & 0x0f) << 4) + ((dataBuffer[2] & 0x3c) >> 2);		
			outputBuffer[2] = ((dataBuffer[2] & 0x03) << 6) + dataBuffer[3];
			// Add all non-padded bytes in output buffer to decoded data
			for (var k:uint = 0; k < outputBuffer.length; k++) {
				if (dataBuffer[k+1] == 64) break;
				output.writeByte(outputBuffer[k]);
			}
		}
		// Rewind decoded data ByteArray
		output.position = 0;
		// Return decoded data
		return output;
	}
	public static function decodeToByteArrayB( data:String ) : ByteArray {
		// Initialise output ByteArray for decoded data
		var output:ByteArray = new ByteArray();
		
		// Create data and output buffers
		var dataBuffer:Array = new Array(4);
		var outputBuffer:Array = new Array(3);
		
		// While there are data bytes left to be processed 
		for (var i:uint = 0; i < data.length; i += 4) { 
			// Populate data buffer with position of Base64 characters for 
			// next 4 bytes from encoded data and throw away the non-encoded characters. 
			for (var j:uint = 0; j < 4 && i + j < data.length; j++) { 
				dataBuffer[j] = BASE64_CHARS.indexOf(data.charAt(i + j)); 
				while((dataBuffer[j] < 0) && (i < data.length)) { 
					i++; 
					dataBuffer[j] = BASE64_CHARS.indexOf(data.charAt(i + j)); 
				} 
			}
			// Decode data buffer back into bytes
			outputBuffer[0] = (dataBuffer[0] << 2) + ((dataBuffer[1] & 0x30) >> 4);
			outputBuffer[1] = ((dataBuffer[1] & 0x0f) << 4) + ((dataBuffer[2] & 0x3c) >> 2);		
			outputBuffer[2] = ((dataBuffer[2] & 0x03) << 6) + dataBuffer[3];
			// Add all non-padded bytes in output buffer to decoded data
			for (var k:uint = 0; k < outputBuffer.length; k++) {
				if (dataBuffer[k+1] == 64) break;
				output.writeByte(outputBuffer[k]);
			}				
		}
		// Rewind decoded data ByteArray
		output.position = 0;
		// Return decoded data
		return output;
	}
	public function Base64() {
		throw new Error("Base64 class is static container only");
	}
}