package com.zb.as3.zlib.filedownload
{
	import com.zb.as3.zlib.filedownload.events.zFileDownloadErrorEvent;
	import com.zb.as3.zlib.filedownload.events.zFileDownloadEvent;
	import com.zb.as3.zlib.filedownload.events.zFileDownloadProgressEvent;
	import com.zb.as3.zlib.filedownload.util.URLDecode;
	
	import flash.display.Bitmap;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.OutputProgressEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	import mx.controls.Alert;
	
	/** 网络正常 成功启动下载器
	 */
	[Event(name = "open",type = "download.zFileDownloadEvent")]
	/** 开始下载
	 */
	[Event(name = "start",type = "download.zFileDownloadEvent")]
	/** 文件存在<br>
	 * 下载时 cover=false(非覆盖式下载 才会派发)
	 */
	[Event(name = "exists",type = "download.zFileDownloadEvent")]
	/** 存在历史缓存
	 */
	[Event(name = "temp_exists",type = "download.zFileDownloadEvent")]
	/** 需要验证
	 */
	[Event(name = "verify",type = "download.zFileDownloadEvent")]
	/** 验证失败,已自动重新下载
	 */
	[Event(name = "verify_failed_and_start",type = "download.zFileDownloadEvent")]
	/**验证失败,是否重新下载 .goto();
	 */
	[Event(name = "verify_failed_to_start",type = "download.zFileDownloadEvent")]
	/** 验证通过,已自动重新下载
	 */
	[Event(name = "verify_complete_and_start",type = "download.zFileDownloadEvent")]
	/** *验证通过,是否继续下载 .goto();
	 */
	[Event(name = "verify_complete_to_start",type = "download.zFileDownloadEvent")]
	/** 下载成功
	 */
	[Event(name = "complete",type = "download.zFileDownloadEvent")]
	
	/** 下载文件失效
	 */
	[Event(name = "404",type = "download.zFileDownloadEvent")]
	/** 请求超时,检测网络或服务器关闭
	 */
	[Event(name = "request_timeout",type = "download.zFileDownloadEvent")]
	/** 检测网络或服务器关闭
	 */
	[Event(name = "server_close",type = "download.zFileDownloadErrorEvent")]
	/** 请求失败
	 */
	[Event(name = "request_error",type = "download.zFileDownloadErrorEvent")]
	/**
	 * 下载文件
	 */	
	public class zFileDownload extends EventDispatcher
	{
		/**标记
		 */		
		public var stamp:String = "";
		//--基本配置
		private var urlRequest:URLRequest;
		private var file:File;
		private var saveFile:File;
		private var fileStream:FileStream;
		private var fileLength:int = 0;
		private var brokenPoint:Boolean = true;
		private var tempExisted:Boolean = false;
		public var exists:Boolean = false;//文件已存在
		private var cover:Boolean = false;
		
		/**
		 *	断点下载&文件存在记录,此值发生变化
		 */
		private var hasPosition:int = 0;
		private var infoLoader:URLStream;//流式下载文件信息
		
		//--为了验证的变量
		private var checkLength:int = 10000;//检测重复文件 默认字节长度
		private var newBytes:ByteArray;//下载文件的检测样本
		private var newBase64:String = "";//下载文件的检测码
		private var checkBytes:ByteArray;//本地文件的检测样本
		private var checkBase64:String = "";//本地文件的检测码
		private var auto:Boolean = true//默认:智能验证
		private var verifyed:Boolean = false;//是否验证完毕 (非断点下载,不需要验证)
		private var verifySuccess:Boolean = false;
		private var readyVerify:Boolean = false;
		
		private var complete:Boolean = false;
		private var total:Number = 0;
		//监控
		private var loaded:Number = 0;
		private var monitorLoaded:Number = 0;
		private var _monitorSpeed:Number = 0;
		private var _monitoring:Boolean = false;
		private var monitorTimer:Timer;
		
		/**
		 * @param verify 验证方式( VerifyMode 常量)
		 */
		public function zFileDownload()
		{
			super();
			init();
		}
		/**初始化 **/
		public function init():void
		{
			this.file = new File();
			this.saveFile = new File();
			this.urlRequest = new URLRequest();
			
			this.infoLoader = new URLStream();
			this.infoLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,securityErrorHandler);
			this.infoLoader.addEventListener(IOErrorEvent.IO_ERROR,IOErrorHandler);
			this.infoLoader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS,httpResponseStatusHandler);
			this.infoLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS,httpStatusHandler);
			this.infoLoader.addEventListener(Event.OPEN,onOpenHandler);
			this.infoLoader.addEventListener(ProgressEvent.PROGRESS,infoProgressHandler);
			this.infoLoader.addEventListener(Event.COMPLETE,onLoadCompleteHandler);
			
			this.fileStream = new FileStream();
			this.fileStream.addEventListener(OutputProgressEvent.OUTPUT_PROGRESS, writeProgressHandler);
			this.fileStream.addEventListener(Event.COMPLETE,fileStreamComplete);
			
			this.monitorTimer = new Timer(1000);
			this.monitorTimer.addEventListener(TimerEvent.TIMER,onTimerHandler);
		}
		
		protected function onTimerHandler(event:TimerEvent):void
		{
			if(verifyed)//验证完毕,正式下载
			{
				_monitorSpeed =  loaded - monitorLoaded;
				trace("当前下载速率:"+_monitorSpeed);
				monitorLoaded = loaded;
			}
		}
		/**关闭 释放**/
		public function close():void
		{
			this.complete = false;
			this.readyVerify = false;
			this.verifySuccess = false;
			this.verifyed = false;
			this.checkBytes = null;
			this.checkBytes = null;
			this.newBytes = null;
			this.newBase64 = null;
			
			this.file = null;
			this.urlRequest = null;
			if(fileStream)
			{
				try{ fileStream.close(); }catch (err:Error){};
				this.fileStream.removeEventListener(OutputProgressEvent.OUTPUT_PROGRESS, writeProgressHandler);
				this.fileStream.removeEventListener(Event.COMPLETE,fileStreamComplete);
				this.fileStream = null;
			}
			if(infoLoader)
			{
				if(this.infoLoader.connected)
				{
					try{ infoLoader.close(); }catch (err:Error){};
				}
				this.infoLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,securityErrorHandler);
				this.infoLoader.removeEventListener(IOErrorEvent.IO_ERROR,IOErrorHandler);
				this.infoLoader.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS,httpResponseStatusHandler);
				this.infoLoader.removeEventListener(HTTPStatusEvent.HTTP_STATUS,httpStatusHandler);
				this.infoLoader.removeEventListener(Event.OPEN,onOpenHandler);
				this.infoLoader.removeEventListener(ProgressEvent.PROGRESS,infoProgressHandler);
				this.infoLoader.removeEventListener(Event.COMPLETE,onLoadCompleteHandler);
				this.infoLoader = null;
			}
			if(this.monitorTimer)
			{
				this.monitorTimer.stop();
				this.monitorTimer.removeEventListener(TimerEvent.TIMER,onTimerHandler);
				this.monitorTimer = null;
			}
		}
		public function dispose():void
		{
			close();
			this.saveFile = null;
		}
		protected function writeProgressHandler(event:OutputProgressEvent):void
		{
			trace("异步写入文件: "+event.toString());
		}
		protected function fileStreamComplete(event:Event):void
		{
			trace("fileStreamComplete");
		}
		protected function securityErrorHandler(event:SecurityErrorEvent):void
		{
//			trace(event.toString());
			monitoring = false;
			this.dispatchEvent(new zFileDownloadErrorEvent(  zFileDownloadErrorEvent.SERVER_CLOSE ));
		}
		protected function onErrorHandler(event:Event):void
		{
//			trace(event.toString());
			monitoring = false;
			this.dispatchEvent(new zFileDownloadErrorEvent(  zFileDownloadErrorEvent.SERVER_CLOSE ));
		}
		protected function IOErrorHandler(event:IOErrorEvent):void
		{
//			trace(event.toString());
			var $event:zFileDownloadErrorEvent;
			switch(event.errorID)
			{
				case 2032:
				{
					$event = new zFileDownloadErrorEvent(  zFileDownloadErrorEvent.SERVER_CLOSE );
					break;
				}
				default:
				{
					$event = new zFileDownloadErrorEvent(  zFileDownloadErrorEvent.REQUEST_ERROR );
					break;
				}
			}
			monitoring = false;
			this.dispatchEvent($event);
		}
		
		protected function httpStatusHandler(event:HTTPStatusEvent):void
		{
//			trace(event.toString());
			var $event:zFileDownloadEvent;
			switch(event.status)
			{
				case 0:
				{
					$event = new zFileDownloadEvent(  zFileDownloadEvent.REQUEST_TIMEOUT);
					break;
				}
				default:
				{
					break;
				}
			}
			if($event)	this.dispatchEvent($event);
		}
		
		protected function httpResponseStatusHandler(event:HTTPStatusEvent):void
		{
//			trace(event.toString());
			var $event:zFileDownloadEvent;
			switch(event.status)
			{
				case 404:
					infoLoader.close();
					$event = new zFileDownloadEvent(zFileDownloadEvent._404);
					break;
				case 206://因为添加了[Range=],所以只有206才是真正成功获得下载数据
					$event = new zFileDownloadEvent(verifyed?zFileDownloadEvent.START:"");
					break;
				default:
				{
					infoLoader.close();
					$event = new zFileDownloadEvent(zFileDownloadEvent._404);
					break;
				}
			}
			if($event)	this.dispatchEvent($event);
		}
		protected function onLoadCompleteHandler(event:Event):void
		{
//			trace(event.toString());
			if(tempExisted && !verifyed){//下载验证数据
//				trace("验证数据下载完毕");
				newBytes = new ByteArray();
				newBytes.position = 0;
				infoLoader.readBytes(newBytes,0, checkLength);
				newBase64 = Base64.encodeByteArray(newBytes);
				infoLoader.close();
				verifySuccess = verifyBase64();
				this.dispatchEvent(new zFileDownloadEvent( verifySuccess ? zFileDownloadEvent.VERIFY_SUCCESS : zFileDownloadEvent.VERIFY_FAILED));//验证不影响进程(匹配成功继续下载/匹配失败重新下载)
				verify2Download();
			}else{
				if(infoLoader.bytesAvailable>0)
				{
					write2Disk();
				}
				if(loaded==total)//下载正式数据
				{
					verifySuccess = false;
					complete = true;
					infoLoader.close();
					fileStream.close();
					file.moveTo(saveFile, true);//临时文件 打包成压缩文件
					this.dispatchEvent(new zFileDownloadEvent(zFileDownloadEvent.COMPLETE));//下载完毕
				}else{
					monitoring = false;
					this.dispatchEvent(new zFileDownloadErrorEvent(zFileDownloadErrorEvent.SERVER_CLOSE));
				}
			}
		}
		protected function infoProgressHandler(event:ProgressEvent):void
		{
			if(verifyed)//验证完毕.开始下载
			{
				loaded = hasPosition+event.bytesLoaded;
				total = hasPosition+event.bytesTotal;
				dispatchEvent(new zFileDownloadProgressEvent(zFileDownloadProgressEvent.PROGRESS,loaded,total));
				write2Disk();
			}else{//等待验证
				checkLength = event.bytesTotal<checkLength ? event.bytesTotal : checkLength;//若总文件过小,则验证检测长度为文件总字节数
				if(readyVerify){
					readyVerify = false;
					this.dispatchEvent(new zFileDownloadEvent(zFileDownloadEvent.VERIFY));
				}
			}
		}
		/**
		 * 验证 开始下载
		 */
		private function verify2Download():void
		{
			if(!verifySuccess)//验证失败,需要删除记录重新下载
			{
				delFile();
				openFile();
				hasPosition = 0;
				fileStream.position = 0;
			}
			downloadFileInfo();
		}
		/**
		 *  下载
		 * @param url 文件地址
		 * @param toFile 存储为File
		 * @param brokenPoint 是否断点方式继续下载 默认:false 不开启
		 * @param auto 是否自动开始下载(否则需 .goto() 开始下载)
		 * @param stamp 标记(默认:toFile文件名)
		 * @param cover 覆盖式下载(文件已存在,则直接删除,开始下载) / 发送[文件存在]事件(zFileDownloadEvent.EXISTS)
		 */
		public function download(url:String, toFile:File, brokenPoint:Boolean = false, auto:Boolean = true, stamp:String="", cover:Boolean=false):void
		{
			if(infoLoader.connected) infoLoader.close();//停止当前下载
			this.urlRequest.url = URLDecode.decode(url);//链接解密 迅雷/快车/旋风
			this.saveFile.url = toFile.url;
			this.exists = this.saveFile.exists;
			this.file.url = toFile.url +"_stemp";
			this.brokenPoint = brokenPoint;
			this.auto = auto;
			this.stamp = stamp ?  stamp : toFile.name;
			this.cover = cover;
			this.complete = false;
			//测速相关
			monitorLoaded = 0;
			_monitorSpeed = 0;
			if(auto)	goto();
		}
		/**
		 * 打开文件流,并设置当前写入位置
		 */
		private function openFileStream(tempExists:Boolean=true):void
		{
			if(!tempExists) delFile();//不存在/不断点 删除临时文件
			openFile();
			this.tempExisted = tempExists = tempExists?fileStream.bytesAvailable>0?true:false:false;//0字节视为:无临时文件
			if(tempExists) dispatchEvent(new zFileDownloadEvent(zFileDownloadEvent.TEMP_EXISTS));
			verifyed = !(brokenPoint && tempExists);//还未验证
			readyVerify = !verifyed;//准备验证
			trace(tempExists?"存在记录":"无记录",readyVerify?" > 准备验证":" > 准备下载");
			hasPosition = tempExists ? fileStream.bytesAvailable : 0;//记录本地临时文件的字节末端
			if(!verifyed)
			{
				checkBytes = new ByteArray();
				checkBytes.position = 0;
				fileStream.position = 0;
				if(fileStream.bytesAvailable>0)
				{
					checkLength = fileStream.bytesAvailable<checkLength ? fileStream.bytesAvailable : checkLength;//精确验证数据的长度
					var positionEnd:int = fileStream.bytesAvailable;
					var positionStart:int = calculateVerifyPositionStart(positionEnd);
					fileStream.position = positionStart;
					fileStream.readBytes(checkBytes, 0, checkLength);
					checkBase64 = Base64.encodeByteArray(checkBytes);
				}
				//获取本地文件的检测码
			}
			fileStream.position = hasPosition;
			//---获取记录文件字节段的验证码,并重置文件位置于末端
		}
		private function calculateVerifyPositionStart(positionEnd:int):int
		{
			return positionEnd-checkLength < 0 ? 0 : positionEnd-checkLength;
		}
		private function openFile():void
		{
			fileStream.open( file ,FileMode.UPDATE );
		}
		private function delFile():void
		{
			fileStream.close();
			if(file.exists) file.deleteFile();
		}
		/** 验证是否相同(是否可以断点继续下载)
		 * @return 
		 */
		private function verifyBase64():Boolean
		{
			verifyed = true;//验证完毕
			trace( checkBase64==newBase64 ?"验证匹配一致":"验证不匹配");
			return checkBase64.length==newBase64.length ? checkBase64 == newBase64 : false;
		}
		/**
		 * 启动下载文件
		 * 
		 * 断点下载&文件存在记录,此值发生变化
		 */		
		private function downloadFileInfo():void
		{
			setRangeURLRequestHeaders();
			infoLoader.load( urlRequest );
		}
		/**
		 * 自动设置下载请求参数Range的起始点
		 * @return 
		 */
		private function setRangeURLRequestHeaders():void
		{
			var header:URLRequestHeader = new URLRequestHeader();
			header.name = "Range";
			if(tempExisted && !verifyed)
			{
				var positionStart:int = calculateVerifyPositionStart(hasPosition);
				header.value = "bytes="+positionStart+"-"+(hasPosition>0?hasPosition:"");
				trace("准备下载验证数据");
			}else{
				header.value = "bytes="+hasPosition+"-";
				trace("准备下载文件数据");
			}
			urlRequest.requestHeaders = [header];
//			trace(header.name+" -> "+header.value);
		}
		protected function onOpenHandler(event:Event):void
		{
			if(verifyed) this.dispatchEvent(new zFileDownloadEvent(zFileDownloadEvent.OPEN));
		}
		private function write2Disk():void
		{
			var $fileData:ByteArray = new ByteArray();
			infoLoader.readBytes($fileData,0,infoLoader.bytesAvailable);
			fileStream.writeBytes($fileData,0,$fileData.length);//下载文件信息 写入 磁盘文件
		}
		public function get bytesLoaded():Number
		{
			return loaded;
		}
		public function get bytesTotal():Number
		{
			return total;
		}
		/**下载的压缩文件
		 * @return File
		 */
		public function get endFile():File
		{
			return saveFile;
		}
		/**
		 *	暂停下载 
		 */		
		public function pause():void
		{
			if(infoLoader.connected)	 infoLoader.close();
			if(monitorTimer.running)	 monitorTimer.stop();//效率:暂停不监控网速
		}
		/**
		 * 继续下载
		 * @return Boolean true:继续下载 / false:文件存在/完成/不需下载
		 */
		public function goto():Boolean
		{
			if( !infoLoader || infoLoader.connected || complete) return false;
			if(exists)
			{//下载文件已存在
				if(cover)
				{//覆盖式下载 直接删除旧文件
					this.saveFile.deleteFile();
				}else{//非覆盖式下载.发送文件存在事件
						dispatchEvent(new zFileDownloadEvent(zFileDownloadEvent.EXISTS));
					return false;
				}
			}
			monitoring ? monitorTimer.start() : monitorTimer.stop();//测速
			openFileStream(brokenPoint&&file.exists);//关于本地临时文件
			downloadFileInfo();//下载环节
			return true;
		}
		/**
		 * 重新下载
		 * @return Boolean 重新下载成功
		 */
		public function reDownload():Boolean
		{
			if(urlRequest.url)
			{
				download(urlRequest.url,saveFile,false,auto,"",true);
				return true;
			}
			return false;
		}
		
		public function get monitoring():Boolean
		{
			return _monitoring;
		}
		/**
		 * 启动测速
		 */
		public function set monitoring(value:Boolean):void
		{
			_monitoring = value;
			value && !monitorTimer.running && infoLoader.connected ? monitorTimer.start() : monitorTimer.stop(); 
		}
		/**当前下载速率  b/s
		 */		
		public function get monitorSpeed():Number
		{
			return _monitorSpeed;
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