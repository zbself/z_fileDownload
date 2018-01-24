package com.zb.as3.zlib.filedownload.events
{
	import flash.events.ErrorEvent;
	
	public class zFileDownloadErrorEvent extends ErrorEvent
	{
		public static const REQUEST_ERROR:String = "request_error";
		public static const SERVER_CLOSE:String = "server_close";
		public var data:*;
		public function zFileDownloadErrorEvent(type:String, $text:String="", data:* = null, id:int=0, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			text = $text;
			this.data = data;
			if(text == "")
			{
				switch(type)
				{
					case SERVER_CLOSE:
						text = "服务已暂停";
						break;
					case REQUEST_ERROR:
						text = "请求失败";
						break;
					
					default:
						break;
				}
			}
			super(type, bubbles, cancelable, text, id);
		}
	}
}