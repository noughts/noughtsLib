package jp.noughts.cocoafish.sdk {
	import flash.net.FileReference;
	import flash.net.URLLoader;

	public class CCRequest {
		private var loader:URLLoader = null;
		private var fileUploader:FileReference = null;
		
		public function CCRequest(request:Object) {
			if(request is URLLoader) {
				loader = request as URLLoader;
			} else if (request is FileReference) {
				fileUploader = request as FileReference;
			}
		}
		
		public function cancel():void {
			try {
				if(loader != null) {
					loader.close();
				} else if (fileUploader != null) {
					fileUploader.cancel();
				}
			} catch (e:Error) {
				//mute
			}
		}
	}
}