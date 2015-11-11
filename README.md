# SdpParser
A parser for SDP partially compliant with [RFC 4566](https://tools.ietf.org/html/rfc4566#page-7). More about [Sesssion Description Protocol](http://en.wikipedia.org/wiki/Session_Description_Protocol). Another interesting RFC is the [RFC draft for Opus codec](https://tools.ietf.org/html/draft-spittka-payload-rtp-opus-03). This parser was written to be used in conjuction with WebRTC. This way you can easily modify settings like codec parameters.

## Installation
Using 
- *npm*: `npm install sdpparser`. See below an example using `require`.
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


## Example
Given the following SDP

	v=0
	o=- 718035783275703419 2 IN IP4 127.0.0.1
	s=-
	t=0 0
	a=group:BUNDLE audio video
	a=msid-semantic: WMS 8pjbfuaudqpe5s3uA
	m=audio 9 UDP/TLS/RTP/SAVPF 111 103 104 9 0 8 106 105 13 126
	c=IN IP4 0.0.0.0
	a=rtcp:9 IN IP4 0.0.0.0
	a=ice-ufrag:Lw5NgNWQ
	a=ice-pwd:qfy9wvi9J3g7G
	a=fingerprint:sha-256 36:B6:83:67:03:BB:
	a=setup:active
	a=mid:audio
	a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level
	a=extmap:3 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time
	a=sendrecv
	a=rtcp-mux
	a=rtpmap:111 opus/48000/2
	a=fmtp:111 minptime=10; useinbandfec=1
	a=rtpmap:103 ISAC/16000
	a=rtpmap:104 ISAC/32000
	a=rtpmap:9 G722/8000
	a=rtpmap:0 PCMU/8000
	a=rtpmap:8 PCMA/8000
	a=rtpmap:106 CN/32000
	a=rtpmap:105 CN/16000
	a=rtpmap:13 CN/8000
	a=rtpmap:126 telephone-event/8000
	a=maxptime:60
	a=ssrc:3140675822 cname:STNh4RdVs
	a=ssrc:3140675822 msid:8pjbfuaudq
	a=ssrc:3140675822 mslabel:8pjbfua
	a=ssrc:3140675822 label:40fff5e6-d618-4b7a

the parsed JSON object will be

	{
		"version": 0,
		"origin": {
			"username": "-",
			"sessionId": "718035783275703419",
			"sessionVersion": 2,
			"networkType": "IN",
			"addressType": "IP4",
			"unicastAddress": "127.0.0.1"
		},
		"sessionName": "-",
		"timing": {
			"start":0,
			"stop":0
		},
		"group": "BUNDLE audio video",
		"msid-semantic": " WMS 8pjbfuaudqpe5s3uA",
		"media": [
			{
				"type": "audio",
				"port": 9,
				"protocol": "UDP/TLS/RTP/SAVPF",
				"payloads": [
					{
						"id":111,
						"rtp": {
							"codec": "opus",
							"rate": 48000,
							"codecParams": 2
						},
						"fmtp": {
							"params": {
								"minptime":10,
								"useinbandfec":1
							}
						}
					},
					{
						"id":103,
						"rtp": {
							"codec": "ISAC",
							"rate":16000
						}
					},
					{
						"id":104,
						"rtp": {
							"codec": "ISAC",
							"rate":32000
						}
					},
					{
						"id":9,
						"rtp": {
							"codec": "G722",
							"rate":8000
						}
					},
					{
						"id":0,
						"rtp": {
							"codec": "PCMU",
							"rate":8000
						}
					},
					{
						"id":8,
						"rtp": {
							"codec": "PCMA",
							"rate":8000
						}
					},
					{
						"id":106,
						"rtp": {
							"codec": "CN",
							"rate":32000
						}
					},
					{
						"id":105,
						"rtp": {
							"codec": "CN",
							"rate":16000
						}
					},
					{
						"id":13,
						"rtp": {
							"codec": "CN",
							"rate":8000
						}
					},
					{
						"id":126,
						"rtp": {
							"codec": "telephone-event",
							"rate": 8000
						}
					}
				],
				"connection": {
					"networkType": "IN",
					"addressType": "IP4",
					"connectionAddress": "0.0.0.0"
				},
				"rtcp": "9 IN IP4 0.0.0.0",
				"ice-ufrag": "Lw5NgNWQ",
				"ice-pwd": "qfy9wvi9J3g7G",
				"fingerprint": "sha-256 36:B6:83:67:03:BB:",
				"setup": "active",
				"mid": "audio",
				"extmap": [
					"1 urn:ietf:params:rtp-hdrext:ssrc-audio-level",
					"3 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time"
				],
				"sendrecv": true,
				"rtcp-mux":true,
				"maximumPacketTime": 60,
				"ssrc": [
					"3140675822 cname:STNh4RdVs",
					"3140675822 msid:8pjbfuaudq",
					"3140675822 mslabel:8pjbfua",
					"3140675822 label:40fff5e6-d618-4b7a"
				]
			}
		]
	}

Please note that 
- `payloads` have been aggregated
- for some SDP parameters, the object property names are expanded
- the properties with multiple values are aggregated into an array

## Development
If you want to involve in this project as a developer please read the short [development guide](dev.md).