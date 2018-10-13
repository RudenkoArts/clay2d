package clay.render;


// import kha.graphics4.Graphics;
import clay.components.graphics.Texture;
import clay.components.graphics.Geometry;
import clay.components.graphics.QuadGeometry;
import clay.components.graphics.LineGeometry;
import clay.components.graphics.Text;
import clay.resources.FontResource;
import clay.render.Layer;
import clay.render.Vertex;
import clay.math.Vector;
import clay.math.Matrix;
import clay.math.Mathf;
import clay.data.Color;
import clay.utils.Log.*;


class Draw {

	// image, text, geom cache
	var geometry:Array<Geometry>;


	@:allow(clay.Engine)
	inline function new() {

		geometry = [];
		
	}

	public function line(options:DrawLineOptions):LineGeometry {

		var immediate = def(options.immediate, true);
		var layer = def(options.layer, 0);
		
		var geom = new LineGeometry({
			p0: options.p0,
			p1: options.p1,
			color0: options.color0,
			color1: options.color1,
			strength: options.strength,
			layer: layer
		});

		add_to_layer(geom, layer, options.order);

		if(immediate) {
			geometry.push(geom);
		}

		return geom;

	}

	public function rectangle(options:DrawRectangleOptions):QuadGeometry {
		
		var x = def(options.x, 0);
		var y = def(options.y, 0);
		var ox = def(options.ox, 0);
		var oy = def(options.oy, 0);
		var w = def(options.w, 32);
		var h = def(options.h, 32);
		var angle = def(options.angle, 0);
		var color = def(options.color, new Color());
		var immediate = def(options.immediate, true);
		var layer = def(options.layer, 0);

		var rect = new QuadGeometry({
			size: new Vector(w, h),
			color: color,
			layer: layer
		});

		update_matrix(rect.transform_matrix, x, y, ox, oy, angle);
		add_to_layer(rect, layer, options.order);

		if(immediate) {
			geometry.push(rect);
		}

		return rect;

	}

	public function circle(options:DrawCircleOptions) {
		
		var cx = def(options.x, 0);
		var cy = def(options.y, 0);
		var ox = def(options.ox, 0);
		var oy = def(options.oy, 0);
		var r = def(options.r, 64);
		var segments = def(options.segments, Math.floor(10 * Math.sqrt(r)));
		var color = def(options.color, new Color());
		var layer = def(options.layer, 0);
		var immediate = def(options.immediate, true);

		var indices = [];
		var vertices = [];

		var theta = 2 * Math.PI / segments;
		var c = Math.cos(theta);
		var s = Math.sin(theta);

		var x = r;
		var y = 0.0;

		for (i in 0...segments) {
			var px = x;
			var py = y;

			var t = x;
			x = c * x - s * y;
			y = c * y + s * t;

			indices[i * 3 + 0] = i * 3 + 0;
			indices[i * 3 + 1] = i * 3 + 1;
			indices[i * 3 + 2] = i * 3 + 2;

			vertices.push(new Vertex(new Vector(px, py)));
			vertices.push(new Vertex(new Vector(x, y)));
			vertices.push(new Vertex(new Vector()));
		}

		var geom = new Geometry({
			vertices: vertices,
			indices: indices,
			layer: layer,
			color: color
		});

		update_matrix(geom.transform_matrix, cx, cy, ox, oy, 0);
		add_to_layer(geom, layer, options.order);

		if(immediate) {
			geometry.push(geom);
		}

		return geom;

	}

	public function polygon(options:DrawPolyOptions):Geometry {

		var x = def(options.x, 0);
		var y = def(options.y, 0);
		var ox = def(options.ox, 0);
		var oy = def(options.oy, 0);
		var angle = def(options.angle, 0);
		var color = def(options.color, new Color());
		var layer = def(options.layer, 0);
		var immediate = def(options.immediate, true);

		var iterator = options.vertices.iterator();

		if (!iterator.hasNext()) {
			return null;
		}

		var v0 = iterator.next();

		if (!iterator.hasNext()) {
			return null;
		}

		var v1 = iterator.next();

		var indices = options.indices;
		var vertices = [];

		var i = 0;
		while (iterator.hasNext()) {
			var v2 = iterator.next();

			vertices.push(new Vertex(v0.clone()));
			vertices.push(new Vertex(v1.clone()));
			vertices.push(new Vertex(v2.clone()));

			v1 = v2;
			i++;
		}

		if(indices == null) {
			indices = [];
			for (i in 0...options.vertices.length) {
				indices[i * 3 + 0] = i * 3 + 0;
				indices[i * 3 + 1] = i * 3 + 1;
				indices[i * 3 + 2] = i * 3 + 2;
			}
		}

		var geom = new Geometry({
			vertices: vertices,
			indices: indices,
			layer: layer,
			color: color
		});

		update_matrix(geom.transform_matrix, x, y, ox, oy, angle);
		add_to_layer(geom, layer, options.order);

		if(immediate) {
			geometry.push(geom);
		}

		return geom;

	}

	public function image(options:DrawImageOptions) {
		
		var x = def(options.x, 0);
		var y = def(options.y, 0);
		var ox = def(options.ox, 0);
		var oy = def(options.oy, 0);
		var w = def(options.w, 32);
		var h = def(options.h, 32);
		var angle = def(options.angle, 0);
		var color = def(options.color, new Color());
		var immediate = def(options.immediate, true);
		var layer = def(options.layer, 0);

		var texture = options.texture;

		var rect = new QuadGeometry({
			size: new Vector(w, h),
			color: color,
			layer: layer,
			texture: texture
		});

		update_matrix(rect.transform_matrix, x, y, ox, oy, angle);
		add_to_layer(rect, layer, options.order);

		if(immediate) {
			geometry.push(rect);
		}

		return rect;

	}

	public function text(options:DrawTextOptions) {
		
		var x = def(options.x, 0);
		var y = def(options.y, 0);
		var ox = def(options.ox, 0);
		var oy = def(options.oy, 0);
		var size = def(options.size, 16);
		var angle = def(options.angle, 0);
		var color = def(options.color, new Color());
		var immediate = def(options.immediate, true);
		var layer = def(options.layer, 0);
		
		var text = options.text;
		var font = options.font;

		var text = new Text({
			size: size,
			color: color,
			layer: layer,
			font: font,
			text: text,
			align: options.align,
			align_vertical: options.align_vertical
		});

		update_matrix(text.transform_matrix, x, y, ox, oy, angle);
		add_to_layer(text, layer, options.order);

		if(immediate) {
			geometry.push(text);
		}

		return text;

	}

	@:allow(clay.Engine)
	function update() {

		if(geometry.length > 0) {
			var lr:Layer = null;

			for (g in geometry) {
				lr = Clay.renderer.layers.get(g.layer);
				lr.remove(g);
			}

			geometry.splice(0, geometry.length);
		}
		
	}
	
	inline function add_to_layer(geom:Geometry, lid:Int, ?order:Null<Int>) {

		var layer = Clay.renderer.layers.get(lid);

		if(layer != null) {
			if(order != null) {
				geom.order = order;
				layer.geometry_list.add(geom);
			} else {
				layer.geometry_list.add_first(geom);
			}
		} else {
			log('cant draw geometry in $lid layer');
		}

	}

	inline function update_matrix(matrix:Matrix, x:Float, y:Float, ox:Float, oy:Float, angle:Float) {
		
		matrix.identity().translate(x, y).rotate(Mathf.radians(-angle)).apply(-ox, -oy);

	}


}


typedef DrawGeometryOptions = {

	@:optional var layer:Int;
	@:optional var immediate:Bool;
	@:optional var order:Int;

}

typedef DrawLineOptions = {

	> DrawGeometryOptions,

	var p0:Vector;
	var p1:Vector;

	@:optional var color0:Color;
	@:optional var color1:Color;

	@:optional var strength:Float;

}

typedef DrawCircleOptions = {

	> DrawGeometryOptions,

	@:optional var x:Float;
	@:optional var y:Float;

	@:optional var ox:Float;
	@:optional var oy:Float;

	@:optional var r:Float;

	@:optional var segments:Int;

	@:optional var color:Color;

}

typedef DrawRectangleOptions = {

	> DrawGeometryOptions,

	@:optional var x:Float;
	@:optional var y:Float;

	@:optional var ox:Float;
	@:optional var oy:Float;

	@:optional var w:Float;
	@:optional var h:Float;
	
	@:optional var angle:Float;

	@:optional var color:Color;

}

typedef DrawImageOptions = {

	> DrawRectangleOptions,

	var texture:Texture;

	@:optional var color:Color;

}

typedef DrawPolyOptions = {

	> DrawGeometryOptions,

	var vertices:Array<Vector>;
	@:optional var indices:Array<Int>;

	@:optional var x:Float;
	@:optional var y:Float;

	@:optional var ox:Float;
	@:optional var oy:Float;

	@:optional var angle:Float;

	@:optional var color:Color;

}

typedef DrawTextOptions = {

	> DrawGeometryOptions,

	var font:FontResource;
	var text:String;

	@:optional var size:Int;

	@:optional var x:Float;
	@:optional var y:Float;

	@:optional var ox:Float;
	@:optional var oy:Float;

	@:optional var angle:Float;

	@:optional var color:Color;

	@:optional var align:TextAlign;
	@:optional var align_vertical:TextAlign;

}