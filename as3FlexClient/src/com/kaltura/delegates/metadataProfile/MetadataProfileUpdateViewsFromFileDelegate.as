package com.kaltura.delegates.metadataProfile
{
	import com.kaltura.config.KalturaConfig;
	import com.kaltura.net.KalturaCall;
	import com.kaltura.delegates.WebDelegateBase;
	import com.kaltura.core.KClassFactory;
	import com.kaltura.errors.KalturaError;
	import com.kaltura.commands.metadataProfile.MetadataProfileUpdateViewsFromFile;

	import ru.inspirit.net.MultipartURLLoader;
	import mx.utils.UIDUtil;

	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.net.FileReference;
	import flash.net.URLLoaderDataFormat;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;

	public class MetadataProfileUpdateViewsFromFileDelegate extends WebDelegateBase
	{
		protected var mrloader:MultipartURLLoader;

		public function MetadataProfileUpdateViewsFromFileDelegate(call:KalturaCall, config:KalturaConfig)
		{
			super(call, config);
		}

		override public function parse(result:XML):* {
			if ((call as MetadataProfileUpdateViewsFromFile).viewsFile is FileReference) {
				return super.parse(result);
			}
			else {
				var cls : Class = getDefinitionByName('com.kaltura.vo.'+ result.result.objectType) as Class;
				var obj : * = (new KClassFactory( cls )).newInstanceFromXML( result.result );
				return obj;
			}
		}

		override protected function sendRequest():void {
			//construct the loader
			createURLLoader();
			
			//create the service request for normal calls
			var variables:String = decodeURIComponent(call.args.toString());
			var req:String = _config.protocol + _config.domain + "/" + _config.srvUrl + "?service=" + call.service + "&action=" + call.action + "&" + variables;
			if ((call as MetadataProfileUpdateViewsFromFile).viewsFile is FileReference) {
				(call as MetadataProfileUpdateViewsFromFile).viewsFile.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA,onDataComplete);
				var urlRequest:URLRequest = new URLRequest(req);
				((call as MetadataProfileUpdateViewsFromFile).viewsFile as FileReference).upload(urlRequest,"viewsFile");
			}
			else{
				mrloader.addFile(((call as MetadataProfileUpdateViewsFromFile).viewsFile as ByteArray), UIDUtil.createUID(), 'viewsFile');	
				mrloader.dataFormat = URLLoaderDataFormat.TEXT;
				mrloader.load(req);
			}
		}

		// Event Handlers
		override protected function onDataComplete(event:Event):void {
			try{
				if ((call as MetadataProfileUpdateViewsFromFile).viewsFile is FileReference) {
					handleResult( XML(event["data"]) );
				}
				else {
					handleResult( XML(event.target.loader.data) );
				}
			}
			catch( e:Error ){
				var kErr : KalturaError = new KalturaError();
				kErr.errorCode = String(e.errorID);
				kErr.errorMsg = e.message;
				_call.handleError( kErr );
			}
		}

		override protected function createURLLoader():void {
			mrloader = new MultipartURLLoader();
			mrloader.addEventListener(Event.COMPLETE, onDataComplete);
		}

	}
}
