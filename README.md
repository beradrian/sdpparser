# SdpParser
A parser for SDP partially compliant with [RFC 4566](https://tools.ietf.org/html/rfc4566#page-7). More about [Sesssion Description Protocol](http://en.wikipedia.org/wiki/Session_Description_Protocol). Another interesting RFC is the [RFC draft for Opus codec](https://tools.ietf.org/html/draft-spittka-payload-rtp-opus-03). This parser was written to be used in conjuction with WebRTC. This way you can easily modify settings like codec parameters.

## Installation
Using 
- *npm*: `npm install sdpparser`
- directly: download the archive from releases and include `SdpParser.js`

This can be used either from a browser or on the server side.

## Usage

	var SdpParser = require("SdpParser");
	var filterSdp = function(sdpText) {
		var sdp = SdpParser.parse(sdpText);
		// ... do your changes to the sdp object ...
		sdpText = SdpParser.format(sdp);
		return sdpText;
	}
	
	peerConnection.createOffer(function(sessionDescription) {
		sessionDescription.sdp = filterSdp(sessionDescription.sdp);	
		peerConnection.setLocalDescription(sessionDescription);
	});

## Development
This parser was developed using [Peg.js](http://pegjs.org), a parser generator for JavaScript. The [grammar syntax](http://pegjs.org/documentation) is very easy to learn and use. There is also an [online development tool](http://pegjs.org/online).
