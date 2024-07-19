"
I am BaselineOfMemcached, I load the code for the Pharo client to Memcached, a distributed memory caching system.
I am a BaselineOf.
"
Class {
	#name : 'BaselineOfMemcached',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfMemcached',
	#package : 'BaselineOfMemcached'
}

{ #category : 'baselines' }
BaselineOfMemcached >> baseline: spec [

	<baseline>
	spec for: #pharo do: [
		self
			setUpDependencies: spec;
			setUpPackages: spec.
		spec postLoadDoIt: #configureMaterializationAndSerialization.
		spec
			group: 'CI' with: 'Tests';
			group: 'Development' with: 'Tests'
		]
]

{ #category : 'baselines' }
BaselineOfMemcached >> configureMaterializationAndSerialization [

	MDCacheClientBase
		materializationAction: [ :bytes | FLMaterializer materializeFromByteArray: bytes ]
		serializationAction: [ :object | FLSerializer serializeToByteArray: object ]
]

{ #category : 'initialization' }
BaselineOfMemcached >> setUpDependencies: spec [

	spec
		baseline: 'Buoy' with: [ spec repository: 'github://ba-st/Buoy:v8' ];
		project: 'Buoy-Deployment' copyFrom: 'Buoy' with: [ spec loads: 'Deployment' ]
]

{ #category : 'baselines' }
BaselineOfMemcached >> setUpPackages: spec [

	spec
		package: 'Memcached' with: [ spec requires: 'Buoy-Deployment' ];
		group: 'Deployment' with: 'Memcached'.

	spec
		package: 'Memcached-Tests' with: [ spec requires: 'Memcached' ];
		group: 'Tests' with: 'Memcached-Tests'
]
