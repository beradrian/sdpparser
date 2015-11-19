/** Developed according to https://tools.ietf.org/html/rfc4566 */

{
var jsCommon = require("jscommon");
var guessType = jsCommon.guessType, isInt = jsCommon.isInt;

/** The offset of the NTP time compared to Unix time. */
var NTP_OFFSET = 2208988800;

var DURATIONS = { "d": 86400, "h": 3600, "m": 60, "s": 1};
DURATIONS.FORMAT_ORDER = ["d", "h", "m"];

/** End of line. */
var EOL = "\r\n";

/** The SDP types and the corresponding properties. */
var SDP_TYPES = {
	v: "version"
	, o: "origin"
	, s: "sessionName"
	, i: "sessionDescription"
	, u: "uri"
	, e: "emailAddress"
	, p: "phoneNumber"
	, c: "connection"
	, m: "media"
	, b: "bandwidth"
	, t: "timing"
	, r: "repeat"
	, z: "timezones"
	, k: "encryptionKey"
	, cat: "category"
	, keywds: "keywords"
	, ptime: "packetTime"
	, maxptime: "maximumPacketTime"
	, orient: "orientation"
	, rtp: "rtpmap"
	, "payloads": ""
};

for (var t in SDP_TYPES) {
	if (SDP_TYPES.hasOwnProperty(t)) {
		SDP_TYPES[SDP_TYPES[t]] = t;
	}
}

var aggregateSdpProperties = function(sdpProperties) {
	var sdp = {};
	var obj = sdp;
	for (var i = 0; i < sdpProperties.length; i++) {
		for (var p in sdpProperties[i]) {
			if (sdpProperties[i].hasOwnProperty(p)) {
				if (options.useMediaSections !== false && p == SDP_TYPES["m"]) {
					obj = sdp;
				}
				if (obj[p]) {
					if (!obj[p].push) {
						obj[p] = [obj[p]];
					}
					obj[p].push(sdpProperties[i][p]);
				} else {
					obj[p] = sdpProperties[i][p];	
				}
				if (options.useMediaSections !== false && p == SDP_TYPES["m"]) {
					obj = sdpProperties[i][p];
				}
			}
		}
	}
	return sdp;
};

var aggregateSdp = function(sdpProperties) {
	var sdp = aggregateSdpProperties(sdpProperties);
	// ensure that media is an array
	if (sdp.media && !sdp.media.join) {
		sdp.media = [sdp.media];
	}

	// aggregate payloads in each media section
	if (options.aggregatePayloads !== false) {
		aggregatePayloads(sdp);
	}
	return sdp;
};

var aggregate = aggregateSdp;

var aggregatePayloads = function(sdp) {
	if (!sdp.media || !sdp.media.length) {
		return sdp;
	}
	for (var i = 0; i < sdp.media.length; i++) { 
		var m = sdp.media[i];
		if (!m.payloads) {
			continue;
		}
		var payloads = [];
		for (var j = 0; j < m.payloads.length; j++) { 
			var payload = {id: m.payloads[j]};
			aggregatePayloadAttribute(payload, m, "rtp");
			aggregatePayloadAttribute(payload, m, "fmtp");
			payloads[j] = payload;
		}
		if (m.rtp) {
			delete m.rtp;
		}
		if (m.fmtp) {
			delete m.fmtp;
		}
		m.payloads = payloads;
	}
	return sdp;
};

var aggregatePayloadAttribute = function(payload, media, attr) {
	if (media[attr] && !media[attr].push) {
		media[attr] = [media[attr]];
	}
	if (media[attr]) {
		payload[attr] = getPayload(media[attr], payload.id);
	}
	if (payload[attr]) {
		delete payload[attr].payload;
	} else {
		delete payload[attr];
	}
};

var getPayload = function(payloads, id) {
	if (payloads.payload === id) {
		return payloads;
	}
	for (var i = 0; i < payloads.length; i++) {
		if (payloads[i].payload === id) {
			return payloads[i];
		}
	}
	return null;
};

var OUTPUT_ORDER = ["v", "o", "s", "i", "u", "e", "p", "c", "b", "t", "r", "z", "k", "a", "*", "m"];
var MEDIA_OUTPUT_ORDER = ["i", "c", "b", "k", "rtcp", "ice-ufrag", "ice-pwd", "fingerprint", "setup", "mid", "extmap", "sendrecv", "rtcp-mux", "payloads", "ptime", "maxptime", "ssrc"];
var getOutputOrder = function(order, property) {
	var idx = order.indexOf(property);
	if (idx < 0) {
		idx = order.indexOf(SDP_TYPES[property]);
	}
	if (idx < 0) {
		idx = order.indexOf("*");
	}
	if (idx < 0) {
		idx = order.length;
	}
};

var ordering = function(order) {
	return function(a, b) {
		return getOutputOrder(order, a) - getOutputOrder(order, b);
	};
};

var formatSdp = function(sdp) {
	return formatSdpSection(sdp, null, OUTPUT_ORDER);
};

parser.format = formatSdp;

var formatSdpSection = function(section, excluded, order) {
	var s = "";

	jsCommon.forEach(section, 
			function(value, property, section) {
				s += formatSdpProperty(section, property);
			}, 
			{
				blacklist: excluded ? function(p) { return excluded.indexOf(p) >= 0 || excluded.indexOf(SDP_TYPES[p]) >= 0;} : null,
				comparator: ordering(order)
			});

	// remove empty lines - it seems that browsers cannot deal with empty lines in SDP, even at the end 
	s = s.replace(/[\r\n]{2,}/g, EOL);
	return s;
};

var formatSdpProperty = function(section, propertyName) {
	// if the property does not exist, return empty
	if (section[propertyName] === undefined) {
		return "";
	}
	// get the prefix of the property according to SDP specs
	var prefix = SDP_TYPES[propertyName] !== undefined ? SDP_TYPES[propertyName] : propertyName;
	// gets the formatter for the property
	var formatter = FORMATTERS[propertyName] || FORMATTERS[prefix] || FORMATTERS["*"];
	// if the prefix is one single character, then it is a SDP type
	// otherwise it is a SDP attribute
	if (prefix.length > 1) {
		prefix = "a=" + prefix;
		if (section[propertyName] === false) {
			return "";
		}
		if (section[propertyName] === true) {
			return prefix + EOL;
		}
		prefix += ":";
	} else if (prefix.length > 0) {
		prefix += "=";
	}

	if (propertyName !== "timezones" && section[propertyName].push) {
		var s = "";
		for (var i = 0; i < section[propertyName].length; i++) {
			s += prefix + formatter(section[propertyName][i], section[propertyName]) + (prefix.length ? EOL : "");
		}
		return s;
	}
	return prefix + formatter(section[propertyName], section) + (prefix.length ? EOL : "");
};

// A formatter for each SDP property or attribute. The default one is "*"
// A formatter is a function that receives the property value and the section
var FORMATTERS = {
"*": function(value) {
	return value.toString();
}
, origin: function(origin) {
	return origin.username + " " + origin.sessionId 
			+ " " + origin.sessionVersion 
			+ " " + origin.networkType
			+ " " + origin.addressType
			+ " " + origin.unicastAddress;
}
, timing: function(timing) {
	return timing.start + " " + timing.stop;
}
, duration: function(duration) {
	if (duration === 0) {
		return duration;
	}
	for (var i = 0, n = DURATIONS.FORMAT_ORDER.length; i < n; i++) {
		var x = duration / DURATIONS[DURATIONS.FORMAT_ORDER[i]];
		if (isInt(x)) {
			return x + DURATIONS.FORMAT_ORDER[i];
		}
	}
	return duration;
}
, repeat: function(repeat) {
	var s = FORMATTERS.duration(repeat.interval) + " " + FORMATTERS.duration(repeat.activeDuration);
	for (var i = 0, n = repeat.offsets.length; i < n; i++) {
		s +=  " " + FORMATTERS.duration(repeat.offsets[i]);
	}
	return s;
}
, timezones: function(timezones) {
	var s = "";
	for (var i = 0, n = timezones.length; i < n; i++) {
		s += (i > 0 ? " " : "") + timezones[i].adjustment + " " + FORMATTERS.duration(timezones[i].offset);
	}
	return s;
}
, encryptionKey: function(encryptionKey) {
	return encryptionKey.method + (encryptionKey.key ? ":" + encryptionKey.key : "");
}
, media: function(media) {
	var s = media.type 
			+ " " + media.port 
			+ (media.numberOfPorts ? "/" + media.numberOfPorts : "")
			+ " " + media.protocol;
	if (media.formats) {
		s += " " + media.formats.join(" ") + EOL;
	}
	if (media.payloads) {
		for (var i = 0; i < media.payloads.length; i++) {
			s += " " + media.payloads[i].id;
		}
		s += EOL;
	}
	s += formatSdpSection(media, ["type", "port", "protocol", "numberOfPorts", "formats"], MEDIA_OUTPUT_ORDER);
	return s;
}
, payloads: function(payload) {
	return formatSdpSection(payload, ["id"], ["rtp", "fmtp"]);
}
, rtpmap: function(rtp, parent) {
	var s = parent.id + " " + rtp.codec + "/" + rtp.rate;
	if (rtp.codecParams) {
		s += "/" + rtp.codecParams;
	}
	return s;
}
, fmtp: function(fmtp, parent) {
	var s = parent.id + " ";
	if (fmtp.params.split) {
		s += fmtp.params;
	} else {
		var i = 0;
		for (var p in fmtp.params) {
			if (fmtp.params.hasOwnProperty(p)) {
				s += (++i === 1 ? "" : "; ") + p + "=" + fmtp.params[p];
			}
		}
	}
	return s;
}
, connection: function(connection) {
	return connection.networkType
			+ " " + connection.addressType
			+ " " + connection.connectionAddress;
}
};

}


sdp
	= line:(line:SdpLine {return line;}) lines:(_eol line:SdpLine {return line;})* _eol*
	{ 
		lines.splice(0, 0, line);
		var sdp = aggregate(lines);
		return sdp;
	};

_eol = [\r\n]+

_ =[ \t]+;

eq = "=";

versionNumber
	= n: number { return n; };

number
	= n: ([\-0-9]+) { return guessType(text()); };

str
	= s: ([^ \t\n\r]+) { return text();}

SdpLine
	= version / origin / media / connection / timing / repeat / timezones / encryptionKey / bandwidth / attribute / otherType;

version
	= "v" eq v: versionNumber { return {version: v}; };

time
	= t: number { return options.useUnixTimes ? t - NTP_OFFSET : t;};

duration
	= x:number p:("d" / "h" / "m" / "s") { return x * DURATIONS[p];} 
	/ x:number { return x;};

	
origin
	= "o" eq 
	username:str 
	_ sessionId:str
	_ sessionVersion:versionNumber
	_ networkType:str
	_ addressType:str
	_ unicastAddress:str 
	{
		var o = {
				username: username, 
				sessionId: sessionId,
				sessionVersion: sessionVersion,
				networkType: networkType,
				addressType: addressType,
				unicastAddress: unicastAddress
		};
		var or = {};
		or[SDP_TYPES["o"]] = o;
		return or;
	};

connection
	= "c" eq 
	networkType:str
	_ addressType:str
	_ connectionAddress: str
	{ 
		return {connection: {
				networkType: networkType,
				addressType: addressType,
				connectionAddress: connectionAddress
		}};
	};

media
	= "m" eq type:str 
	_ port:number 
	numberOfPorts:("/" n:number {return n;}) ?
	_ protocol:([^ \t]+ {return text();})
	formats:(_ format:str { return format;})+
	{
		var m = {
			type: type
			, port: port
			, protocol: protocol
		};
		if (numberOfPorts) {
			m.numberOfPorts = numberOfPorts;
		}
		// TODO better detection of RTP
		if (options.parseRtpPayloads !== false && protocol.indexOf("RTP/") >= 0) {
			m.payloads = formats;
			m.payloads.forEach(function(value, index, arr) {
					arr[index] = guessType(value);
				});
		} else {
			m.formats = formats;
		}
		return {media: m};
	}

bandwidth
	= "b" eq type: str ":" value: str { return {bandwidth: {type: type, value: value}}};

timing
	= "t" eq start:time _ stop:time {return {timing:{start: start, stop: stop}}};

repeat
	= "r" eq interval:duration _ activeDuration:duration offsets:(_ d:duration {return d;})*
	{ return {repeat: {interval: interval, activeDuration: activeDuration, offsets: offsets}}};

timezones
	= "z" eq t:timezone ts:(_ t:timezone {return t;})+
	{ return {timezones: [t].concat(ts)};};

timezone
	= adjustment:number _ offset:duration {return {adjustment: adjustment, offset: offset}};

encryptionKey
	= "k" eq method:([^:\r\n]+ {return text();}) ":" key:str { return {encryptionKey: {method: method, key: key}};}
	/ "k" eq method:str { return {encryptionKey: {method: method}};};

attribute
	= rtpmapAttribute / fmtpAttribute / valueAttribute / propertyAttribute;

rtpmapAttribute
	= "a" eq "rtpmap" ":" payload:number 
	_ codec:([^/]+ {return text();})
	"/" rate:number codecParams:("/" params:str {return guessType(params);})?
	{
		var rtp = {
				payload: payload,
				codec: codec,
				rate: rate
		};
		if (codecParams) {
			rtp.codecParams = codecParams;
		}
		return {rtp: rtp};
	};

fmtpAttribute
	= "a" eq "fmtp" ":" payload:number 
	_ params:formatParameters
	{
		return { fmtp: {
				payload: payload,
				params: params
		}};
	};

formatParameters
	= param:formatParameter params:(";" [ \t]* p:formatParameter {return p;})*
	{
		if (params) {
			params.splice(0, 0, param);
		} else {
			params = [param];
		}
		return aggregateSdpProperties(params);
	}
	/ config:[^\r\n]+ { return text();};

formatParameter
	= name:([^=;\r\n]+ {return text()}) 
	eq value:([^;\r\n]+ {return guessType(text());}) 
	{ var param = {}; param[name] = value; return param;}

propertyAttribute
	= "a" eq property: attributeName
	{
		var p = {}; 
		p[property] = true; 
		return p;
	}

valueAttribute
	= "a" eq property: attributeName ":" value:([^\n\r]+ {return guessType(text());})
	{
		var p = {}; 
		p[property] = value; 
		return p;
	}

attributeName
	= ([^\n\r:]+)
	{
		var name = text(); 
		if (options["useLongNames"] !== false && SDP_TYPES[name]) {
			return SDP_TYPES[name];
		}
		return name;
	};

otherType
	= type: [a-z] eq value: ([^\r\n]+ {return text();}) 
	{ 
		var t = {};
		t[SDP_TYPES[type] ? SDP_TYPES[type] : type] = value;
		return t;
	};
