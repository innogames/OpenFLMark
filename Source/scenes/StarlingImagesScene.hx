package scenes;

import openfl.display.Stage;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.EnterFrameEvent;
import starling.events.Event;
import starling.text.TextField;
import starling.textures.Texture;

@:keep class StarlingImagesScene extends Sprite implements Benchmarkable {
	private static inline var FRAME_TIME_WINDOW_SIZE:Int = 10;

	private var _resultText:TextField;
	private var _statusText:TextField;
	private var _container:Sprite;
	private var _objectPool:Array<DisplayObject>;
	private var _objectTexture:Texture;

	private var _frameCount:Int;
	private var _frameTimes:Array<Float>;
	private var _targetFps:Int;

	public function new(stage: Stage) {
		super();

		// the container will hold all test objects
		_container = new Sprite();
		_container.x = Constants.CenterX;
		_container.y = Constants.CenterY;
		_container.touchable = false; // we do not need touch events on the test objects --
									  // thus, it is more efficient to disable them.
		addChildAt(_container, 0);

		_frameTimes = new Array<Float>();
		_objectPool = [];
		_objectTexture = Game.assets.getTexture("benchmark_object");

		addEventListener(Event.ENTER_FRAME, onEnterFrame);

		onStartButtonTriggered();
	}

	public function addTestObjects(count:Int) {
		var scale:Float = 1.0 / _container.scale;

		for (i in 0...count) {
			var egg:DisplayObject = getObjectFromPool();
			var distance:Float = (100 + Math.random() * 100) * scale;
			var angle:Float = Math.random() * Math.PI * 2.0;

			egg.x = Math.cos(angle) * distance;
			egg.y = Math.sin(angle) * distance;
			egg.rotation = angle + Math.PI / 2.0;
			egg.scale = scale;

			_container.addChild(egg);
		}
	}

	public function getTestObjectCount():Int {
		return _container.numChildren;
	}

	public override function dispose() {
		removeEventListener(Event.ENTER_FRAME, onEnterFrame);

		for (object in _objectPool)
			object.dispose();

		super.dispose();
	}

	private function onStartButtonTriggered() {
		trace("Starting benchmark");

		_targetFps = Std.int(Starling.current.nativeStage.frameRate);
		_frameCount = 0;

		addTestObjects(10000);


		for (i in 0...FRAME_TIME_WINDOW_SIZE)
			_frameTimes[i] = 1.0 / _targetFps;

		if (_resultText != null) {
			_resultText.removeFromParent(true);
			_resultText = null;
		}
	}

	private function onEnterFrame(event:EnterFrameEvent, passedTime:Float) {
		_frameCount++;
		_container.rotation += event.passedTime * 0.5;
	}
	
	private function removeTestObjects(count:Int) {
		var numChildren:Int = _container.numChildren;

		if (count >= numChildren)
			count  = numChildren;

		for (i in 0...count)
			putObjectToPool(_container.removeChildAt(_container.numChildren-1));
	}

	private function getObjectFromPool():DisplayObject {
		// we pool mainly to avoid any garbage collection while the benchmark is running

		if (_objectPool.length == 0) {
			var image:Image = new Image(_objectTexture);
			image.alignPivot();
			//TODOimage.pixelSnapping = false; // slightly faster (and doesn't work here, anyway)
			return image;
		}
		else
			return _objectPool.pop();
	}

	private function putObjectToPool(object:DisplayObject) {
		_objectPool[_objectPool.length] = object;
	}
}