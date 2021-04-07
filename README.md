# WORK IN PROGRESS

Far from finished. And propably quite wrong.

## Masterlist generator

Generate a set of CSCA, ML, DSC and BSC hierachies for a couple of countries (called AA, BB, CC).

And generate trust lists of these in the simplfified format of:

```
[
	{ "kid": 9223372036854775807,  
	  "coordiante": [ "c86306cf630383035b87b092b72769b2ce7117daaf290bf03f1a6558c2bd0ee0", "9d12a08088aba1457bdf518b0aa393a9bdb2de6db470203b36a8cc98e4aae7ba" ]
	},
	{ "kid": 7880631021713385367,  
	  "coordiante": [ "4c8bdec1e8fc997a525b2105fceda09f90159f790cb0ac16bfd55f2fe43e4c48", "3a87c38b7426419f6fac48ea749ac77089fa002be9db94bf82fe3fcca8f40da2" ]
	}
]
```

Where the KID is the first 8 bytes of the SHA256 of the certificates; and the coordinates are the X,Y (bignum, little endian) of the prime256p1.

Useful files in the directory ``out'' are:

* trustlist.json - a JSON style formatted file of KIDs and the raw coordinates of all known/trusted signers of all countries.
* CSCA-<country>-* Country Signer Certificate Authority Certifcate.
* BSC-<country>-, DSC-<country>-, MSL-<Country>-...
		Document, barcode and master list signer certificates and keys.
* BSC-<country>trustlist.json - JSON-ish formatted file of KIDs and the raw coordinates.
* BSC-<country>trustlist.json.p7 - same but signed by the countries MasterList Sginer
* masterlist-<country>txt and the .p7 version - list of the certificates; as simple concatenated PEMs.

## Source

This is based on the JRC scripts - see  jrc-original/simple-emrtd-pki/readme.txt for more information.

