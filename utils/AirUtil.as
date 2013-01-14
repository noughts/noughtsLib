package jp.noughts.utils{

	import flash.desktop.*;

	public class AirUtil{


		static public function getVersionNumber():String{
			var appXML:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = appXML.namespace();
			return appXML.ns::versionNumber;
		}
	}
}