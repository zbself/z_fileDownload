package com.zb.as3.zlib.filedownload.core
{
	import flash.filesystem.File;

	public class zFileDownloadItem
	{
		public var url:String = "";
		public var toFile:File;
		public var brokenPoint:Boolean = true;
		public var auto:Boolean = false;
		public var stamp:String = "";
		public var error:Boolean = false;
		public var exists:Boolean = false;
		public var cover:Boolean = false;//覆盖式下载
		/**
		 * 
		 * @param url 地址
		 * @param toFile 文件
		 * @param brokenPoint 断点续载
		 * @param auto download自动开始.设置为false,否则直接下载.
		 * @param stamp 标识
		 * @param cover 覆盖式下载
		 */		
		public function zFileDownloadItem(url:String,toFile:File,brokenPoint:Boolean=true,auto:Boolean=false,stamp:String="",cover:Boolean=false)
		{
			this.url = url;
			this.toFile = toFile;
			this.brokenPoint = brokenPoint;
			this.auto = auto;
			this.stamp = stamp;
			this.cover = cover;
		}
	}
}