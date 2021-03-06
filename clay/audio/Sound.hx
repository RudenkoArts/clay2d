package clay.audio;

import kha.arrays.Float32Array;
import clay.resources.AudioResource;
import clay.Audio;
import clay.audio.AudioChannel;
import clay.audio.AudioEffect;
import clay.audio.AudioGroup;
import clay.utils.Math;
import clay.utils.Log;

class Sound extends AudioChannel {

	public var resource(get, set):AudioResource;

	public var pitch(get, set):Float;
	public var time(get, set):Float;
	public var duration(get, never):Float;
	public var position(get, set):Int;
	public var length(get, never):Int;

	public var paused(get, null):Bool;
	public var playing(get, never):Bool;
	public var finished(get, null):Bool;
	public var channels(get, never):Int;

	public var loop(get, set):Bool;

	@:noCompletion public var _added:Bool;

	var _resource:AudioResource;
	var _paused:Bool;
	var _pitch:Float;
	var _position:Int;
	var _positionRaw:Float;
	var _loop:Bool;
	var _finished:Bool;

	var _cache:Float32Array;
	var _outputToPlay:AudioGroup;

	var _linInt:Float;

	public function new(?resource:AudioResource, output:AudioGroup = null, maxEffects:Int = 8) {
		super(maxEffects);

		_resource = resource;
		_outputToPlay = output != null ? output : Clay.audio;

		_pitch = 1;
		_position = 0;
		_positionRaw = 0;
		_linInt = 0;

		_paused = false;
		_loop = false;
		_finished = false;
		_added = false;

		_cache = new Float32Array(512);
	}

	override function process(data:Float32Array, bufferSamples:Int) {
		if(_resource == null || _paused) {
			return;
		}
		
		if (_cache.length < bufferSamples) {
			_cache = new Float32Array(bufferSamples);
		}

		if(_finished) {
			_outputToPlay.remove(this);
			_added = false;
			return;
		}

		// var soundData = _resource.uncompressedData;
		// var bufferIdx = 0;
		// var chunkIdx = 0;
		// var chunkLen = 0;
		// while (bufferIdx < bufferSamples) {
		// 	// chunkLen = Math.ceil((soundData.length - _position) / _pitch); // TODO: test this
		// 	chunkLen = Math.floor((soundData.length - _position) / _pitch); // TODO: test this
		// 	if(chunkLen > (bufferSamples - bufferIdx)) {
		// 		chunkLen = (bufferSamples - bufferIdx);
		// 	}
			
		// 	// output[outputPtr]=(currSample[ptr+1]*linInt)+(currSample[ptr]*(1-linInt));

		// 	while (chunkIdx++ < chunkLen) {
		// 		_linInt = _positionRaw - _position;

		// 		//linear interpolation pitch shifting
		// 		_cache[bufferIdx++] = (soundData[min(_position+1, soundData.length-1)] * _linInt) + (soundData[_position] * (1-_linInt));
		// 		// _cache[bufferIdx++] = soundData[_position];

		// 		_positionRaw += _pitch;
		// 		_position = Math.floor(_positionRaw);
		// 	}

		// 	if (!_loop) {
		// 		if (_position >= soundData.length) {
		// 			_finished = true;
		// 		}
		// 		break;
		// 	} else { 
		// 		if (_position >= soundData.length) {
		// 			_position = 0;
		// 			_positionRaw = 0;
		// 		}
		// 	}
		// 	chunkIdx = 0;
		// }

		var soundData = _resource.uncompressedData;
		var bufferIdx = 0;
		var chunkIdx = 0;
		var chunkLen = 0;
		var dataLen = Math.floor(soundData.length / 2)-1;
		var nextPos = 0;
		while (bufferIdx < bufferSamples) {
			// chunkLen = Math.ceil((soundData.length - _position) / _pitch); // TODO: test this
			// chunkLen = Math.floor((dataLen - _position)) * 2; // TODO: test this
			chunkLen = Math.floor((dataLen - _position) / _pitch) * 2; // TODO: test this
			if(chunkLen > (bufferSamples - bufferIdx)) {
				chunkLen = (bufferSamples - bufferIdx);
			}
			
			// output[outputPtr]=(currSample[ptr+1]*linInt)+(currSample[ptr]*(1-linInt));

			while (chunkIdx < chunkLen) {
				_linInt = _positionRaw - _position;

				//linear interpolation pitch shifting
				nextPos = min(Math.floor(_positionRaw + _pitch), dataLen-1);
				_cache[bufferIdx] = (soundData[nextPos*2] * _linInt) + (soundData[_position*2] * (1-_linInt));
				_cache[bufferIdx+1] = (soundData[nextPos*2+1] * _linInt) + (soundData[_position*2+1] * (1-_linInt));

				// _cache[bufferIdx] = soundData[_position*2];
				// _cache[bufferIdx+1] = soundData[_position*2+1];
				bufferIdx +=2;

				_positionRaw += _pitch;
				_position = Math.floor(_positionRaw);
				// _position++;
				chunkIdx +=2;
			}

			if (!_loop) {
				if (_position >= dataLen) {
					_finished = true;
				}
				break;
			} else { 
				if (_position >= dataLen) {
					_position = 0;
					_positionRaw = 0;
				}
			}
			chunkIdx = 0;
		}

		while (bufferIdx < bufferSamples) {
			_cache[bufferIdx++] = 0;
		}

		processEffects(_cache, bufferSamples);

		bufferIdx = 0;
		while(bufferIdx < bufferSamples) {
			data[bufferIdx] += _cache[bufferIdx] * _volume * _l;
			data[bufferIdx+1] += _cache[bufferIdx+1] * _volume * _r;
			bufferIdx +=2;
		}
	}
	
	// public function nextSamples(requestedSamples: Float32Array, requestedLength: Int, sampleRate: Int): Void {
	// 	if (paused || stopped) {
	// 		for (i in 0...requestedLength) {
	// 			requestedSamples[i] = 0;
	// 		}
	// 		return;
	// 	}
		
	// 	var requestedSamplesIndex = 0;
	// 	while (requestedSamplesIndex < requestedLength) {
	// 		for (i in 0...min(data.length - myPosition, requestedLength - requestedSamplesIndex)) {
	// 			requestedSamples[requestedSamplesIndex++] = data[myPosition++];
	// 		}

	// 		if (myPosition >= data.length) {
	// 			myPosition = 0;
	// 			if (!looping) {
	// 				stopped = true;
	// 				break;
	// 			}
	// 		}
	// 	}

	// 	while (requestedSamplesIndex < requestedLength) {
	// 		requestedSamples[requestedSamplesIndex++] = 0;
	// 	}
	// }



	static inline function min(a: Int, b: Int) {
		return a < b ? a : b;
	}

	public function play():Sound {
		Audio.mutexLock();

		_finished = false;
		_paused = false;
		_positionRaw = 0;
		_position = 0;

		if(_resource != null) {
			if(_outputToPlay != null) {
				if(!_added) {
					_outputToPlay.add(this);
					_added = true;
				}
			} else {
				Log.warning("cant play: there is no output channel for sound");
			}
		} else {
			Log.warning("there is no audio _resource to play");
		}

		Audio.mutexUnlock();
		
		return this;
	}

	public function stop():Sound {
		Audio.mutexLock();

		if(_resource != null) {
			if(_outputToPlay != null) {
				if(_added) {
					_outputToPlay.remove(this);
					_added = false;
				}
			} else {
				Log.warning("cant stop: there is no output channel for sound");
			}
		} else {
			Log.warning("there is no audio _resource, nothing to stop");
		}

		Audio.mutexUnlock();

		return this;
	}

	public function pause():Sound {
		Audio.mutexLock();
		_paused = true;
		Audio.mutexUnlock();

		return this;
	}

	public function unpause():Sound {
		Audio.mutexLock();
		_paused = false;
		Audio.mutexUnlock();
		
		return this;
	}

	public function setOutput(output:AudioGroup):Sound {
		Audio.mutexLock();
		if(_outputToPlay != null) {
			if(_added) {
				_outputToPlay.remove(this);
			}
		}
		_outputToPlay = output;
		Audio.mutexUnlock();

		return this;
	}

	function get_resource():AudioResource {
		Audio.mutexLock();
		if(_resource != null) {
			_resource.unref();
		}
		var v = _resource;
		if(_resource != null) {
			_resource.ref();
		}
		Audio.mutexUnlock();

		return v;
	}

	function set_resource(v:AudioResource):AudioResource {
		Audio.mutexLock();
		_resource = v;
		Audio.mutexUnlock();

		return v;
	}

	function get_paused():Bool {
		Audio.mutexLock();
		var v = _paused;
		Audio.mutexUnlock();

		return v;
	}

	function get_pitch():Float {
		Audio.mutexLock();
		var v = _pitch;
		Audio.mutexUnlock();

		return v;
	}

	function set_pitch(v:Float):Float {
		Audio.mutexLock();
		_pitch = Math.max(v, 0.01); // TODO: 0?
		v = _pitch;
		Audio.mutexUnlock();

		return v;
	}

	function get_loop():Bool {
		Audio.mutexLock();
		var v = _loop;
		Audio.mutexUnlock();

		return v;
	}

	function set_loop(v:Bool):Bool {
		Audio.mutexLock();
		_loop = v;
		Audio.mutexUnlock();

		return v;
	}

	function get_time():Float {
		Audio.mutexLock();
		// var v = _position / Clay.audio._sampleRate / _getChannels();
		var v = _position / Clay.audio.sampleRate / 2;
		Audio.mutexUnlock();

		return v;
	}

	function set_time(v:Float):Float { // TODO: implement this
		// Audio.mutexLock();
		// _position = Std.int(v * Clay.audio._sampleRate * _getChannels())
		// _positionRaw = _position;
		// Audio.mutexUnlock();

		return v;
	}

	function get_finished():Bool { 
		Audio.mutexLock();
		// var v = _position >= _getLength();
		var v = _finished;
		Audio.mutexUnlock();

		return v;
	}

	function get_playing():Bool { 
		Audio.mutexLock();
		var v = _added;
		Audio.mutexUnlock();

		return v;
	}

	function get_position():Int {
		Audio.mutexLock();
		var v = _position;
		Audio.mutexUnlock();

		return v;
	}

	function set_position(v:Int):Int {
		Audio.mutexLock();
		_position = v;
		Audio.mutexUnlock();

		return v;
	}

	function get_length():Int {
		Audio.mutexLock();
		var v = _getLength();
		Audio.mutexUnlock();

		return v;
	}

	function get_channels():Int {
		Audio.mutexLock();
		var v = _getChannels();
		Audio.mutexUnlock();

		return v;
	}

	function get_duration():Float {
		Audio.mutexLock();
		var v = _getDuration();
		Audio.mutexUnlock();

		return v;
	}

	function _getChannels():Int {
		if(_resource != null) {
			return _resource.channels;
		}

		return 0;
	}

	function _getLength():Int {
		if(_resource != null) {
			return _resource.uncompressedData.length;
		}

		return 0;
	}

	function _getDuration():Float {
		if(_resource != null) {
			// return _resource.uncompressedData.length / Clay.audio._sampleRate / _resource.channels;
			return _resource.uncompressedData.length / Clay.audio.sampleRate / 2; // kha uses 2 channels by default
		}

		return 0;
	}


}