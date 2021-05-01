#!/bin/sh
set -e

CNFDIR=${CNFDIR:-cnf}
IMDIR=${IMDIR:-intermediates}
OUTDIR=${OUTDIR:-out}

PRIVDIR=${PRIVDIR:-$IMDIR}

export PRIV_KEY_START=20210401000000Z
export CA_PRIV_KEY_END=20240401000000Z
export DS_PRIV_KEY_END=20211101000000Z
export MLS_PRIV_KEY_END=20211101000000Z

mkdir -p ${IMDIR} ${OUTDIR}


gendocsign() {
        C=$1
        TYPE=$2

        openssl req -new -config ${CNFDIR}/doc_$TYPE.conf -nodes -newkey ec:<(openssl ecparam -name prime256v1 -genkey) -keyout ${PRIVDIR}/Health-DSC-$C-$TYPE.key | openssl req -noout -text

        openssl req -new -config ${CNFDIR}/doc_$TYPE.conf -nodes -newkey ec:<(openssl ecparam -name prime256v1 -genkey) -keyout ${PRIVDIR}/Health-DSC-$C-$TYPE.key |\
           openssl x509 -req -extfile ${CNFDIR}/csca.conf -CA ${IMDIR}/csca-Health$C.crt -CAkey ${PRIVDIR}/csca-Health$C.key -extensions document_signer_${TYPE}_ext -days 4017 -out ${IMDIR}/Health-DSC-$C-$TYPE.crt -set_serial $RANDOM
}
gencountry() {
        export C=$1
        openssl req -x509 -new -config ${CNFDIR}/csca.conf -newkey ec:<(openssl ecparam -name prime256v1 -genkey) -keyout ${PRIVDIR}/csca-Health$C.key -nodes  -extensions csca_ext -out  ${IMDIR}/csca-Health$C.crt -days 7300

        gendocsign $1 test
        gendocsign $1 recovery
        gendocsign $1 vaccinations

        #openssl ca -config ${CNFDIR}/csca.conf -gencrl -keyfile  ${PRIVDIR}/csca-Health$C.key -cert  ${PRIVDIR}/csca-Health$C.crt

}

gencountry NL

