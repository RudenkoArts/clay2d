package clay.tween.tweens;


class NumTween extends Tween {


	var names:Array<String>;
	var from:Array<Float>;
	var from_current:Array<Float>;
	// var to:Array<Float>;
	var difference:Array<Float>;
	var props:Dynamic;


	public function new(_action:TweenAction, _props:Dynamic, _duration:Float) {

		super(_action, _duration);

		props = _props;

	}

	override function init() {
		
		names = [];
		from = [];
		// from_current = [];
		// to = [];
		difference = [];

		for (p in Reflect.fields(props)) {
			if(!Reflect.hasField(target, p)) {
				trace('cant find field: $p');
				continue;
			}

			var _from:Float = get_prop(p);
			var _to:Float = Reflect.getProperty(props, p);

			names.push(p);
			from.push(_from);
			// to.push(_to);
			difference.push(_to - _from);
		}
		
	}

	override function apply(tp:Float) {

		var n:Float = 0;
		for (i in 0...names.length) {
			n = action.node.easing(from[i], difference[i], tp);
			set_prop(names[i], n);
		}

	}


}
