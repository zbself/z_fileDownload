package com.zb.as3.zlib.filedownload.util
{
	import flash.utils.Dictionary;
	
	/**
	 *	哈希链表：键值 >> 对象 的结构 
	 **/
	public class HashMap
	{

		public function HashMap()
		{
			length=0;
			content=new Dictionary();
		}
		/**
		 * To successfully store and retrieve (key->value) mapping from a HashMap.
		 * HashMap accept any type of object to be the key: number, string, Object etc...
		 * But it is only get fast accessing with string type keys. Others are slow.
		 * <p>
		 * ----------------------------------------------------------
		 * This example creates a HashMap of friends. It uses the number of the friends as keys:
		 * <listing>
		 *     function person(name,age,sex){
		 *         this.name=name;
		 *         this.age=age;
		 *         this.sex=sex;
		 *     }
		 *     var friends = new HashMap();
		 *     friends.put("one", new person("iiley",21,"M"));
		 *     friends.put("two", new person("gothic man",22,"M"));
		 *     friends.put("three", new person("rock girl",19,"F"));
		 * </listing>
		 * </p>
		 * <p>To retrieve a friends, use the following code:
		 *
		 * <listing>
		 *     var thisperson = friends.get("two");
		 *     if (thisperson != null) {
		 *         trace("two name is "+thisperson.name);
		 *         trace("two age is "+thisperson.age);
		 *         trace("two sex is "+thisperson.sex);
		 *     }else{
		 *         trace("two is not in friends!");
		 *     }
		 * </listing>
		 *</p>
		 * @author iiley
		 * 	@langversion ActionScript 3.0
		 *	@playerversion Flash 9.0+
		 */
		private var content:Dictionary;
		private var length:int;

		/**
		 * 清空哈希链表
		 */
		public function clear():void
		{
			length=0;
			content=new Dictionary();
		}

		/**
		 * 复制<code>HashMap</code>
		 * @return 复制品
		 */
		public function clone():HashMap
		{
			var temp:HashMap=new HashMap();
			for (var i:*in content)
			{
				temp.put(i, content[i]);
			}
			return temp;
		}

		/**
		 * 是否包含指定键
		 * 如果键是字符串则运算速度非常快
		 * @param key 要检测的键
		 * @return <tt>true</tt> 链表包含指定映射
		 */
		public function containsKey(key:*):Boolean
		{
			return (content[key] !== undefined);
		}

		/**
		 * 是否包含指定键值；
		 * @param value 要检测的键值
		 * @return <code>Boolean</code>
		 */
		public function containsValue(value:*):Boolean
		{
			for each (var i:*in content)
			{
				if (i === value)
				{
					return true;
				}
			}
			return false;
		}

		/**
		 * 遍历键并回调
		 * @param func 回调函数
		 */
		public function eachKey(func:Function):void
		{
			for (var i:*in content)
			{
				func(i);
			}
		}

		/**
		 * 遍历键值并回调
		 * @param func 回调函数
		 */
		public function eachValue(func:Function):void
		{
			for each (var i:*in content)
			{
				func(i);
			}
		}

		/**
		 * 获取与键匹配的键值
		 * @param key 键
		 * @return 与键匹配的键值
		 */
		public function get(key:*):*
		{
			var value:*=content[key];
			if (value !== undefined)
			{
				return value;
			}
			return null;
		}

		/**
		 * @copy #this.get();
		 */
		public function getValue(key:*):*
		{
			return get(key);
		}

		/**
		 * <code>HashMap<code>是否含有键、键值对.
		 * @return <code>Boolean</code>
		 */
		public function isEmpty():Boolean
		{
			return length == 0;
		}

		/**
		 * 以数组的形式返回<code>HashMap</code>键
		 * @return <code>Array</code>键组成的数组
		 */
		public function get keys():Array
		{
			var temp:Array=new Array(length);
			var index:int=0;
			for (var i:*in content)
			{
				temp[index]=i;
				index++;
			}
			return temp;
		}

		/**
		 * 输入键、键值对，如果键已存在则取代之前的键值，如果键值为空则从映射表中移除该键；
		 * @param key 与键值匹配的键；
		 * @param value 与键匹配的键值，为空则移除键；
		 * @return 在此之前与键配对的键值；
		 */
		public function put(key:*, value:*):*
		{
			if (key == null)
			{
				throw new ArgumentError("cannot put a value with undefined or null key!");
				return undefined;
			}
			else if (value == null)
			{
				return remove(key);
			}
			else
			{
				if (!containsKey(key))
				{
					length++;
				}
				var oldValue:*=this.get(key);
				content[key]=value;
				return oldValue;
			}
		}

		/**
		 * 移除键及键值映射
		 * @param key 将被移除的键及其映射
		 * @return 与被移除的键相关的键值
		 */
		public function remove(key:*):*
		{
			if (!containsKey(key))
			{
				return null;
			}
			var temp:*=content[key];
			delete content[key];
			length--;
			return temp;
		}

		/**
		 * <code>HashMap</code>键、键值数量
		 * @return <code>int</code>键、键值数量
		 */
		public function size():int
		{
			return length;
		}

		public function toString():String
		{
			var ks:Array=keys;
			var vs:Array=values;
			var temp:String="HashMap Content:\n";
			for (var i:int=0; i < ks.length; i++)
			{
				temp+=ks[i] + " -> " + vs[i] + "\n";
			}
			return temp;
		}

		/**
		 * 以数组的形式返回<code>HashMap</code>键值
		 * @return <code>Array</code>键值组成的数组
		 */
		public function get values():Array
		{
			var temp:Array=new Array(length);
			var index:int=0;
			for each (var i:*in content)
			{
				temp[index]=i;
				index++;
			}
			return temp;
		}
	}
}