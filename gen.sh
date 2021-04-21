#!/bin/sh
set -e

CNFDIR=${CNFDIR:-cnf}
IMDIR=${IMDIR:-intermediates}
OUTDIR=${OUTDIR:-out}

PRIVDIR=${PRIVDIR:-$IMDIR}

export PRIV_KEY_START=20210401000000Z
export CA_PRIV_KEY_END=20230401000000Z
export DS_PRIV_KEY_END=20210701000000Z
export MLS_PRIV_KEY_END=20210701000000Z

mkdir -p ${IMDIR} ${OUTDIR}

gencountry() {
	export C=$1
	openssl req -x509 -new -config ${CNFDIR}/csca.conf -keyout ${PRIVDIR}/csca-$C.key -nodes  -extensions csca_ext -out  ${IMDIR}/csca-$C.crt

	openssl req -new -config ${CNFDIR}/ml_signer.conf -keyout ${PRIVDIR}/ML-$C.key -nodes -subj "/C=$C/O=$C ML Manager/CN=MLS" |\
	    openssl x509 -req -extfile ${CNFDIR}/csca.conf \
			-CA  ${PRIVDIR}/csca-$C.crt -CAkey ${PRIVDIR}/csca-$C.key \
			-out ${IMDIR}/ML-$C.crt \
			-extensions document_signer_ext -days 1830 -set_serial $RANDOM

        for i in 1 2
        do
	    openssl req -new -config ${CNFDIR}/d_signer.conf -keyout ${PRIVDIR}/DSC-$C.key -nodes -subj "/C=$C/O=$C Document Issuer /CN=Document Signer $C-$i" |\
		openssl x509 -req -extfile ${CNFDIR}/csca.conf -CA  ${PRIVDIR}/csca-$C.crt -CAkey ${PRIVDIR}/csca-$C.key -out ${IMDIR}/DSC-$C-$i.crt -extensions document_signer_ext -days 1830 -set_serial $RANDOM
	done

	for i in 1 2 3 4 5
	do
	    openssl ecparam -name prime256v1 -genkey -noout -out ${PRIVDIR}/BSC-$C-$i.key
            openssl req -config ${CNFDIR}/barcode_signer.conf -new -key ${PRIVDIR}/BSC-$C-$i.key -subj "/C=$C/CN=B$i" |\
		openssl x509 -req -extfile ${CNFDIR}/csca.conf -CA  ${PRIVDIR}/csca-$C.crt -CAkey ${PRIVDIR}/csca-$C.key -out ${IMDIR}/BSC-$C-$i.crt -extensions barcode_signer_ext -days 1095 -set_serial $i
        done

	# openssl ca -config ${CNFDIR}/csca.conf -gencrl -keyfile ${PRIVDIR}/csca-$C.key -cert ${IMDIR}/csca-$C.crt

}

trustentry() {
	DN=$(openssl x509 -in "$1" -noout -subject -issuer)
	DN=$(echo $DN)
	KID=$(openssl x509 -fingerprint -sha256 -in "$1" -noout | sed -e 's/.*=//' -e 's/://g' | cut -c 1-16)
	RAW=$(echo `openssl x509 -in "$1" -noout -pubkey | openssl pkey  -pubin -text | grep '^ '` | sed -e 's/[: ]*//g')

	if ! echo $RAW | grep -q ^04; then
		echo $1 is not a raw/uncompressed curve. sorry.
		exit 1
	fi
	RAW=$(echo $RAW | sed -e 's/^04//')
	X=$(echo $RAW | cut -c 1-64)
	Y=$(echo $RAW | cut -c 65-128)
	echo "/* $DN */"
	echo "{ \"kid\": \"$KID\", \"coord\": [ \"$X\", \"$Y\" ] },"
}

maketrustlist() {
	for i in ${IMDIR}/$1-$2-*.crt
	do
		trustentry $i
	done
}

for C in AA BB CC DD EE FF GG HH
do
	gencountry $C
	cat ${IMDIR}/ML-$C*.crt ${IMDIR}/DSC-$C*.crt > ${IMDIR}/masterlist-$C.txt
	openssl cms -sign  -nodetach  -in ${IMDIR}/masterlist-$C.txt  -signer ${IMDIR}/ML-$C.crt -inkey ${IMDIR}/ML-$C.key \
		-out ${IMDIR}/masterlist-$C.p7 -outform DER

	for t in BSC
	do
		(
			for i in ${IMDIR}/$t-$C-*.crt
			do
				trustentry $i
			done
		) > ${IMDIR}/$t-$C-trustlist.json

		openssl cms -sign  -nodetach  -in ${IMDIR}/$t-$C-trustlist.json -signer ${IMDIR}/ML-$C.crt -inkey ${IMDIR}/ML-$C.key \
			-out ${IMDIR}/$t-trustlist.json.signed.p7 -outform DER
	done
done	

( echo '['; cat ${IMDIR}/*-trustlist.json; echo ']' ) | grep -v '*' > ${IMDIR}/trustlist.json

cp ${IMDIR}/trustlist.json  ${IMDIR}/*.p7  ${IMDIR}/BSC-AA-5* ${IMDIR}/csca-*.crt ${OUTDIR} 
exit 0
