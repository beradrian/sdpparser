var SdpParser = require("../src/main/js/SdpParser.js");

describe("SdpParser", function() {
	it("should parse version", function() {
		var sdp = SdpParser.parse("v=0");
		expect(sdp.version).toBe(0);
		expect(SdpParser.format(sdp)).toEqual("v=0\r\n");
		sdp = SdpParser.parse("v=0\r\n");
		expect(sdp.version).toBe(0);
		expect(SdpParser.format(sdp)).toEqual("v=0\r\n");
	});

	it("should parse repeat", function() {
		var sdp = SdpParser.parse("v=0\r\nr=1d 30m 100 2h");
		expect(sdp.version).toBe(0);
		expect(sdp.repeat).toBeDefined();
		expect(sdp.repeat.interval).toEqual(86400);
		expect(sdp.repeat.activeDuration).toEqual(1800);
		expect(sdp.repeat.offsets).toEqual([100, 7200]);
	});

	it("should parse repeat without offsets", function() {
		var sdp = SdpParser.parse("v=0\r\nr=1d 30m");
		expect(sdp.version).toBe(0);
		expect(sdp.repeat).toBeDefined();
		expect(sdp.repeat.interval).toEqual(86400);
		expect(sdp.repeat.activeDuration).toEqual(1800);
		expect(sdp.repeat.offsets).toEqual([]);
	});

	it("should format compact repeat", function() {
		var sdp = SdpParser.parse("v=0\r\nr=1d 1800 100 3600");
		expect(sdp.version).toBe(0);
		expect(sdp.repeat).toBeDefined();
		expect(sdp.repeat.interval).toEqual(86400);
		expect(sdp.repeat.activeDuration).toEqual(1800);
		expect(sdp.repeat.offsets).toEqual([100, 3600]);
		var s = SdpParser.format(sdp);
		expect(s).toEqual("v=0\r\nr=1d 30m 100 1h\r\n");
	});

	it("should parse timezones", function() {
		var sdp = SdpParser.parse("v=0\r\nz=2882844526 -1h 2898848070 0 2898850010 200s");
		expect(sdp.version).toBe(0);
		expect(sdp.timezones[0].adjustment).toEqual(2882844526);
		expect(sdp.timezones[0].offset).toEqual(-3600);
		expect(sdp.timezones[1].adjustment).toEqual(2898848070);
		expect(sdp.timezones[1].offset).toEqual(0);
		expect(sdp.timezones[2].adjustment).toEqual(2898850010);
		expect(sdp.timezones[2].offset).toEqual(200);
		var s = SdpParser.format(sdp);
		expect(s).toEqual("v=0\r\nz=2882844526 -1h 2898848070 0 2898850010 200\r\n");
	});

	it("should parse encryption keys", function() {
		var sdp = SdpParser.parse("v=0\r\nk=prompt\r\nk=clear:123");
		expect(sdp.version).toBe(0);
		expect(sdp.encryptionKey[0].method).toEqual("prompt");
		expect(sdp.encryptionKey[0].key).toBe(undefined);
		expect(sdp.encryptionKey[1].method).toEqual("clear");
		expect(sdp.encryptionKey[1].key).toEqual("123");
		var s = SdpParser.format(sdp);
		expect(s).toEqual("v=0\r\nk=prompt\r\nk=clear:123\r\n");
	});

	it("should parse attribute", function() {
		var sdp = SdpParser.parse("v=0\r\na=group:BUNDLE audio video\r\n");
		expect(sdp.version).toBe(0);
		expect(sdp.group).toEqual("BUNDLE audio video");
		expect(SdpParser.format(sdp)).toEqual("v=0\r\na=group:BUNDLE audio video\r\n");
	});

	it("should aggregate", function() {
		var sdp = SdpParser.parse("v=0\r\na=ssrc:3140675822 mslabel:8pjbfua\r\na=ssrc:3140675822 label:40fff5e6-d618-4b7a\r\n");
		expect(sdp.version).toBe(0);
		expect(sdp.ssrc.length).toBe(2);
		expect(sdp.ssrc[0]).toEqual("3140675822 mslabel:8pjbfua");
	});

	it("should parse media", function() {
		var sdp = SdpParser.parse("v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111 103 104");
		expect(sdp.version).toBe(0);
		expect(sdp.media.length).toBe(1);
		expect(sdp.media[0].type).toEqual("audio");
		expect(sdp.media[0].payloads.length).toBe(3);
	});

	it("should parse media and payloads", function() {
		var sdp = SdpParser.parse("v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111 103 104\r\nc=IN IP4 0.0.0.0\r\na=rtpmap:111 opus/48000/2\r\na=fmtp:111 minptime=10; useinbandfec=1\r\na=rtpmap:103 ISAC/16000\r\na=fmtp:103 foo=1\r\n\r\na=rtpmap:104 ISAC/32000\r\n");
		expect(sdp.version).toBe(0);
		expect(sdp.media.length).toBe(1);
		expect(sdp.media[0].payloads[0].id).toBe(111);
		expect(sdp.media[0].payloads[0].rtp.codec).toBe("opus");
		expect(SdpParser.format(sdp)).toMatch(/v=0.*/g);
	});

	it("should parse real life example", function() {
		var sdp = SdpParser.parse("v=0\r\no=- 718035783275703419 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\na=group:BUNDLE audio video\r\na=msid-semantic: WMS 8pjbfuaudqpe5s3uA\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111 103 104 9 0 8 106 105 13 126\r\nc=IN IP4 0.0.0.0\r\na=rtcp:9 IN IP4 0.0.0.0\r\na=ice-ufrag:Lw5NgNWQ\r\na=ice-pwd:qfy9wvi9J3g7G\r\na=fingerprint:sha-256 36:B6:83:67:03:BB:\r\na=setup:active\r\na=mid:audio\r\na=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level\r\na=extmap:3 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\r\na=sendrecv\r\na=rtcp-mux\r\na=rtpmap:111 opus/48000/2\r\na=fmtp:111 minptime=10; useinbandfec=1\r\na=rtpmap:103 ISAC/16000\r\na=rtpmap:104 ISAC/32000\r\na=rtpmap:9 G722/8000\r\na=rtpmap:0 PCMU/8000\r\na=rtpmap:8 PCMA/8000\r\na=rtpmap:106 CN/32000\r\na=rtpmap:105 CN/16000\r\na=rtpmap:13 CN/8000\r\na=rtpmap:126 telephone-event/8000\r\na=maxptime:60\r\na=ssrc:3140675822 cname:STNh4RdVs\r\na=ssrc:3140675822 msid:8pjbfuaudq\r\na=ssrc:3140675822 mslabel:8pjbfua\r\na=ssrc:3140675822 label:40fff5e6-d618-4b7a\r\n");
		expect(sdp.version).toBe(0);
		expect(sdp.media.length).toBe(1);
		expect(sdp.media[0].payloads[0].id).toBe(111);
		expect(sdp.media[0].payloads[0].rtp.codec).toBe("opus");
		var sdpText = SdpParser.format(sdp);
		expect(sdpText).toMatch(/v=0.*/g);
		expect(sdpText).not.toMatch(/\[object Object\]/g);
	});

});