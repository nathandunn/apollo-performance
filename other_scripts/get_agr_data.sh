#!/bin/bash

AGR_ORGANISMS=("RGD" "HUMAN" "WB" "MGI" "ZFIN" "MGI" "FB")
# data URL is here: curl https://fms.alliancegenome.org/api/datafile/by/GFF/ |  jq '.[] | .s3Path' | grep 3.0.0
# data URL is here: curl https://fms.alliancegenome.org/api/datafile/by/VCF/ |  jq '.[] | .s3Path' | grep 3.0.0 # though we don't use that

function get_agr_gff3() {
  for organism in "${AGR_ORGANISMS[@]}" ; do
    echo "curl -o ${organism}.gff http://download.alliancegenome.org/3.0.0/GFF/${organism}/GFF_${organism}_0.gff"
    curl -o ${organism}.gff http://download.alliancegenome.org/3.0.0/GFF/${organism}/GFF_${organism}_0.gff
  done

}
