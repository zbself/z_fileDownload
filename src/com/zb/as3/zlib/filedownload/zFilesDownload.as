package com.zb.as3.zlib.filedownload
{
	import com.zb.as3.zlib.filedownload.core.zFileDownloadItem;
	import com.zb.as3.zlib.filedownload.core.zFileDownloadMode;
	import com.zb.as3.zlib.filedownload.events.zFileDownloadErrorEvent;
	import com.zb.as3.zlib.filedownload.events.zFileDownloadEvent;
	import com.zb.as3.zlib.filedownload.events.zFileDownloadProgressEvent;
	import com.zb.as3.zlib.filedownload.util.HashMap;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.filesystem.File;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	
	/**
	 * 下载多个文件
	 * 下载器模式: 失败文件自动跳过,存在失败文件导致无法触发完成事件.
	 * 更新器魔兽: 失败问题暂停运行,
	 * 
	 * 
	 * 
	 * 
	 * 
	 * 
	 */	
	public class zFilesDownload extends EventDispatcher
	{
		private var _total:int = 0;
		private var _loaded:int = 0;
		private var downloadList:HashMap;
		private var lastParallelTaskNum:int = 0;//记录
		private var _maxParallelTaskNum:int = 0;//并行数
		private var items:Vector.<zFileDownloadItem>;
		private var _failedItems:HashMap;
		private var _mode:String = zFileDownloadMode.DOWNLOADER;//模式
		private var aaa:int;
		/**添加item 进行debug查看列表
		 */
		public var isDebugItems:Boolean = true;
		/**
		 * @param $mode 默认:"downloader"("downloader"下载器/"updater",版本更新器)<br>具体查看:zFileDownloadMode.DOWNLOADER/zFileDownloadMode.UPDATER<br>updater模式下,maxParallelTaskNum强制为1;
		 * @param $maxParallelTaskNum 默认:0 不限制
		 */
		public function zFilesDownload($mode:String="downloader", $maxParallelTaskNum:int = 0)
		{
			this.downloadList = new HashMap();
			this.items = new Vector.<zFileDownloadItem>();
			this._failedItems = new HashMap();
			this._maxParallelTaskNum = $maxParallelTaskNum;
			this.lastParallelTaskNum = $maxParallelTaskNum;//记录
			this.mode = $mode;
		}
		/**
		 * @param $item : zFileDownloadItem
		 */
		public function addItem($item:zFileDownloadItem):void
		{
			addItemFunc($item);
			_total = loaded+items.length;
			download();
		}
		/**
		 * @param $items 数组: zFileDownloadItem集合
		 */		
		public function addItems($items:Array):void
		{
			for each (var i:zFileDownloadItem in $items)
			{
				addItemFunc(i);
			}
			_total = loaded+items.length;
			download();
		}
		public function getDownloadFromURL($url:String):zFileDownload
		{
			return null;
		}
		public function getDownloadFromStamp($stamp:String):zFileDownload
		{
			return getDownload($stamp);
		}
		/**
		 * 下载
		 */		
		protected function download():void
		{
			var maxlTaskNum:int = maxParallelTaskNum==0 ? _total : maxParallelTaskNum;
			trace(" 数组length "+items.length)
			if(items.length)
			{
				for (var i:int = 1; i <= items.length; i++)
				{
					var crtItem:zFileDownloadItem =  items[i-1] as zFileDownloadItem;
					var crtDownload:zFileDownload = getDownload(crtItem.toFile.name);
					if(crtItem.error)
					{
						_failedItems.put(crtItem.stamp,crtItem);
						continue;
					}
					if(crtDownload)
					{
						(i-_failedItems.keys.length-1) < maxlTaskNum?crtDownload.goto() : crtDownload.pause();
					}
				}
			}
		}
		/** 快捷创建FileDownload */
		private function creatDownload(item:zFileDownloadItem):zFileDownload
		{
			var fileDownload:zFileDownload = new zFileDownload();
			fileDownload.addEventListener(zFileDownloadErrorEvent.SERVER_CLOSE,serverCloseHandler);
			fileDownload.addEventListener(zFileDownloadEvent.OPEN,openHandler);
			fileDownload.addEventListener(zFileDownloadEvent._404,download404Handler);
			fileDownload.addEventListener(zFileDownloadEvent.START,downloadStartHandler);
			fileDownload.addEventListener(zFileDownloadEvent.EXISTS,existsHandler);
			fileDownload.addEventListener(zFileDownloadEvent.VERIFY,verifyHandler);
			fileDownload.addEventListener(zFileDownloadEvent.VERIFY_FAILED,verifyHandler);
			fileDownload.addEventListener(zFileDownloadEvent.VERIFY_SUCCESS,verifyHandler);
			fileDownload.addEventListener(zFileDownloadProgressEvent.PROGRESS,downloadProgressHandler);
			fileDownload.addEventListener(zFileDownloadEvent.COMPLETE,downloadCompleteHandler);
			fileDownload.download(item.url, item.toFile, item.brokenPoint, item.auto, item.stamp,item.cover);
			downloadList.put(fileDownload.stamp,fileDownload);//直接视为完成,则不需要加入下载器列表中
			return fileDownload;
		}
		
		protected function serverCloseHandler(event:zFileDownloadErrorEvent):void
		{
			var $target:zFileDownload = zFileDownload(event.target);
			trace($target.stamp+"["+event.type+"]"+event.text);
			if(isDownloader)
			{
				getItem($target.stamp).error = true;
				lastItem($target.stamp);
				download();
			}
			this.dispatchEvent(new zFileDownloadErrorEvent(zFileDownloadErrorEvent.SERVER_CLOSE,"",$target));//
		}
		protected function openHandler(event:zFileDownloadEvent):void
		{
			var $target:zFileDownload = zFileDownload(event.target);
//			trace($target.stamp+"["+event.type+"]"+event.text);
		}
		protected function download404Handler(event:zFileDownloadEvent):void
		{
			var $target:zFileDownload = zFileDownload(event.target);
//			trace($target.stamp+"["+event.type+"]"+event.text);
			if(isDownloader)
			{//下载器:继续下载
				getItem($target.stamp).error = true;
				lastItem($target.stamp);
				download();
			}//更新器停止
			this.dispatchEvent(new zFileDownloadEvent(zFileDownloadEvent._404,"",$target));//
		}
		protected function downloadStartHandler(event:zFileDownloadEvent):void
		{
			var $target:zFileDownload = zFileDownload(event.target);
			trace($target.stamp+"["+event.type+"]"+event.text);
			getItem($target.stamp).error = false;
		}
		protected function verifyHandler(event:zFileDownloadEvent):void
		{
			var $target:zFileDownload = zFileDownload(event.target);
			trace($target.stamp+"["+event.type+"]"+event.text);
			switch(event.type)
			{
				case zFileDownloadEvent.VERIFY:
				{
					//开始验证
					break;
				}
				case zFileDownloadEvent.VERIFY_FAILED:
				{
					//验证失败
					break;
				}
				case zFileDownloadEvent.VERIFY_SUCCESS:
				{
					//验证成功
					break;
				}
				default:
					break;
			}
		}
		protected function downloadProgressHandler(event:zFileDownloadProgressEvent):void
		{
			this.dispatchEvent(new zFileDownloadProgressEvent(zFileDownloadProgressEvent.PROGRESS,event.bytesLoaded,event.bytesTotal,zFileDownload(event.target)));//----
		}
		protected function existsHandler(event:zFileDownloadEvent):void
		{
			var $target:zFileDownload = zFileDownload(event.target);
			trace($target.stamp+"["+event.type+"]"+event.text);
			delItem($target.stamp);//项目删除
			$target.close();
			_loaded++;//已下载数
			_total = _loaded + items.length;
			this.dispatchEvent(new zFileDownloadEvent(zFileDownloadEvent.EXISTS,"",$target));//下载完成
			checkComplete();
		}
		protected function downloadCompleteHandler(event:zFileDownloadEvent):void
		{
			var $target:zFileDownload = zFileDownload(event.target);
			trace($target.stamp+"["+event.type+"]"+event.text);
			$target.close();
			delItem($target.stamp);//项目删除
			delDownload($target.stamp);//工具删除
			_loaded++;//已下载数
			checkComplete();
			this.dispatchEvent(new zFileDownloadEvent(zFileDownloadEvent.DOWNLOAD_COMPLETE,"",$target));//下载完成
		}
		/** 检测完成度	 */
		protected function checkComplete():void
		{
			trace(_loaded +"/"+total)//文件数量进度
			if(_loaded==total)
			{//全部下载完毕
				trace("downloads complete");
				this.dispatchEvent(new zFileDownloadEvent(zFileDownloadEvent.DOWNLOADS_COMPLETE));
			}else{//继续下载
				download();
			}
		}
		/**
		 * 清除
		 */
		public function clear():void
		{
			for each (var i:String in downloadList.keys)
			{
				var tempDownloadItem:zFileDownload = getDownload(i);
				tempDownloadItem.removeEventListener(zFileDownloadErrorEvent.SERVER_CLOSE,serverCloseHandler);
				tempDownloadItem.removeEventListener(zFileDownloadEvent.OPEN,openHandler);
				tempDownloadItem.removeEventListener(zFileDownloadEvent._404,download404Handler);
				tempDownloadItem.removeEventListener(zFileDownloadEvent.START,downloadStartHandler);
				tempDownloadItem.removeEventListener(zFileDownloadEvent.VERIFY,verifyHandler);
				tempDownloadItem.removeEventListener(zFileDownloadEvent.VERIFY_FAILED,verifyHandler);
				tempDownloadItem.removeEventListener(zFileDownloadEvent.VERIFY_SUCCESS,verifyHandler);
				tempDownloadItem.removeEventListener(zFileDownloadProgressEvent.PROGRESS,downloadProgressHandler);
				tempDownloadItem.removeEventListener(zFileDownloadEvent.COMPLETE,downloadCompleteHandler);
				tempDownloadItem.dispose();
			}
			while(items.length)
			{
				items.pop();
			}
			_failedItems.clear()
			
			_loaded = 0;
			_total = 0;
			downloadList.clear();
		}
		/**
		 * 获取下载项目
		 * @param stamp
		 * @return 
		 */
		public function getItem(stamp:String):zFileDownloadItem
		{
			for each (var i:zFileDownloadItem in items) 
			{
				if(i.stamp == stamp)
				{
					return i;
				}
			}
			return null;
		}
		/**
		 * 获取下载器<br>
		 * 没有设置stamp,则默认下载文件的文件名. 例如:patch.zip
		 * @param stamp
		 */
		public function getDownload(stamp:String):zFileDownload
		{
			return downloadList.get(stamp);
		}
		public function get loaded():int
		{
			return _loaded;
		}
		public function get total():int
		{
			return _total;
		}
		public function get maxParallelTaskNum():int
		{
			return _maxParallelTaskNum;
		}
		/**最大并行任务数<br>
		 * 默认:0 不限制,并行全部下载
		 * @param value = 0
		 */
		public function set maxParallelTaskNum(value:int):void
		{
			_maxParallelTaskNum = value;
			if(isDownloader)
			{//记录下载器模式的最大并行下载数
				lastParallelTaskNum = value;
			}
			download();
		}
		public function get mode():String
		{
			return _mode;
		}
		public function set mode(value:String):void
		{
			_mode = value;
			maxParallelTaskNum = value==zFileDownloadMode.DOWNLOADER ? lastParallelTaskNum : 1;//版本更新器模式下,并行下载数1
		}
		//----内部方法----
		private function debugItems():void
		{
			var debugText:String = "";
			for (var i:int = 0; i < items.length; i++) 
			{
				var crtItem:zFileDownloadItem =  items[i] as zFileDownloadItem;
				debugText += "[ "+crtItem.stamp+(crtItem.error ? "-失链": crtItem.exists?"-存在":"-正常")+" ] ";
			}
			trace( debugText );
		}
		private function addItemFunc($item:zFileDownloadItem):void
		{
			var infex:int = 0;
			var lenIndex:int = items.length;
			var $_item:zFileDownloadItem;
			var temp:zFileDownload = creatDownload($item);
			if(temp==null) return;
			
			$item.stamp = temp.stamp;
			$item.exists = temp.exists;
			if(!lenIndex)//0:首次添加下载文件
			{
				items.unshift($item);//数组首 添加
			}else{
				do{//倒置添加下载项目
					if(!lenIndex)//若倒置到数组首,便直接添加
					{
						items.unshift($item);
					}else{
						$_item = items[lenIndex-1];
						if(!$_item.error||$_item.exists)//添加至已失链项目前
						{
							items.splice(lenIndex,0,$item);
							break;
						}
					}
				}while(lenIndex--)
			}
			if(isDebugItems) debugItems();
		}
		/**删除下载Item
		 * @param $stamp
		 */		
		private function delItem($stamp:String):void
		{
			for (var i:int = items.length-1; i >=0; i--)
			{
				var $item:zFileDownloadItem = items[i] as zFileDownloadItem;
				if($item.stamp == $stamp)
				{
					trace("删除"+$stamp);
					items.splice( i ,1 );
				}
			}
			if(isDebugItems) debugItems();
		}
		/** Item更新列表至尾(失链Item至尾)
		 * @param stamp
		 * @return 是否有stamp元素至尾
		 */
		private function lastItem(stamp:String):Boolean
		{
			var j:int = 0;
			for each (var i:zFileDownloadItem in items) 
			{
				if(i.stamp == stamp)
				{
					items.push(zFileDownloadItem(Vector.<zFileDownloadItem>(items.splice(j,1))[0]));
					return true;
				}
				j++;
			}
			return false;
		}
		/** 删除下载器
		 * @param stamp
		 * @return 
		 */
		private function delDownload(stamp:String):zFileDownload
		{
			return downloadList.remove(stamp);
		}
		/** 模式:是否下载器<br>
		 * true:下载器 / false:更新器
		 */		
		private function get isDownloader():Boolean
		{
			return mode == zFileDownloadMode.DOWNLOADER;
		}

		public function get failedItems():HashMap
		{
			return _failedItems;
		}
		
	}
}