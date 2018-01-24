package com.zb.as3.zlib.filedownload.core
{
	public class zFileDownloadMode
	{
		/**
		 * 下载器模式<br>
		 * 下载文件,意味着:可任意下载,文件之间互相无关联
		 */
		public static const DOWNLOADER:String = "downloader";
		/**
		 * 更新器模式<br>
		 * 版本更新包顺序下载,意味着中途不可中断,必须依次下载更新
		 */
		public static const UPDATER :String = "updater";
		
		public function zFileDownloadMode()
		{
		}
	}
}