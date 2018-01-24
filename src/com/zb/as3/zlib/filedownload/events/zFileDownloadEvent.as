package com.zb.as3.zlib.filedownload.events
{
	import flash.events.Event;
	
	public class zFileDownloadEvent extends Event
	{
		//--------------------------------------------------
		/** 打开
		 */		
		public static const OPEN:String = "open";
		
		/** 下载文件已存在<br>
		 * 下载时 cover=false(非覆盖式下载 才会派发)
		 */
		public static const EXISTS:String = "exists";
		/** 文件存在历史记录(断点下载)
		 */
		public static const TEMP_EXISTS:String = "temp_exists";
		/** 开始
		 */		
		public static const START:String = "start";
		/**下载中
		 */		
		public static const DOWNLOADING:String = "downloading";
		/**下载完毕
		 */
		public static const COMPLETE:String = "complete";
		//--------------------------------------------------
		/**需要验证
		 */
		public static const VERIFY:String = "verify";
		/** 验证失败,是否重新下载 .goto();
		 */		
		public static const VERIFY_FAILED:String = "verify_failed";
		/**验证通过,自动重新下载
		 */
		public static const VERIFY_SUCCESS:String = "verify_success";
		
		//--------------------------------------------------
		/**下载文件失效
		 */		
		public static const _404:String = "404";
		/**请求超时
		 */
		public static const REQUEST_TIMEOUT:String = "request_timeout";
		
		/**全部下载完毕
		 */
		public static const DOWNLOADS_COMPLETE:String = "downloads_complete";
		/**下载完毕
		 */
		public static const DOWNLOAD_COMPLETE:String = "download_complete";
		
		public var text:String = "";
		public var data:*;
		public var fileURL:String;
		public function zFileDownloadEvent(type:String, text:String="", data:* = null, fileURL:String="", bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.data = data;
			this.fileURL = fileURL;
			if(text=="")
			{
				switch(type)
				{
					case OPEN:
						text = "网络正常,启动下载";
						break;
					case START:
						text = "开始下载";
						break;
					case EXISTS:
						text = "下载文件已存在";
						break;
					case TEMP_EXISTS:
						text = "下载文件已有历史缓存";
						break;
					case VERIFY:
						text = "等待验证";
						break;
					case VERIFY_FAILED:
						text = "验证失败";
						break;
					case VERIFY_SUCCESS:
						text = "验证成功";
						break;
					case DOWNLOADING:
						text = "下载中";
						break;
					case COMPLETE:
						text = "下载完毕";
						break;
					case _404:
						text = "下载文件失效"
						break;
					case REQUEST_TIMEOUT:
						text = "请求超时,检测网络或服务器关闭";
						break;
					default:
						break;
				}
			}
			this.text = text;
			super(type, bubbles, cancelable);
		}
	}
}