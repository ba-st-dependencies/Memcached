MDCacheClientBase
		materializationAction: [ :bytes | STON fromString: bytes utf8Decoded ]
		serializationAction: [ :object | (STON toString: object) utf8Encoded ]
