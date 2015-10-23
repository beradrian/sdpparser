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

	it("should parse attribute", function() {
		var sdp = SdpParser.parse("v=0\r\na=group:BUNDLE audio video\r\n");
		expect(sdp.version).toBe(0);
		expect(sdp.group).toEqual("BUNDLE audio video");
		expect(SdpParser.format(sdp)).toEqual("v=0\r\na=group:BUNDLE audio video\r\n");
	});
});