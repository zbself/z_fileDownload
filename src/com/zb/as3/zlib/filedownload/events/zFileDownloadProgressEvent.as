package com.zb.as3.zlib.filedownload.events
{
	import flash.events.Event;
	import flash.events.ProgressEvent;
	
	public class zFileDownloadProgressEvent extends ProgressEvent
	{
		public static const PROGRESS:String = "progress";
		public var data:*;
		public var progress:Number = 0;
		public function zFileDownloadProgressEvent(type:String, bytesLoaded:Number=0, bytesTotal:Number=0, data:*=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.data = data;
			this.progress = bytesLoaded/bytesTotal;
			super(type, bubbles, cancelable,bytesLoaded,bytesTotal);
		}
	}
}