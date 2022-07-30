#!/bin/sh

BASE_M4_FILE=5G.m4

NONF_NORMAL_BASE=5G_noNF_normal
# no non-frameability
# normal channels (no compromise)
cp $BASE_M4_FILE $NONF_NORMAL_BASE.m4
sed -i -e "s/dnl define.normal_channels,/define(normal_channels,/g" $NONF_NORMAL_BASE.m4
m4 $NONF_NORMAL_BASE.m4 > $NONF_NORMAL_BASE.spthy

NONF_GNB_SEAF_READ=5G_noNF_gNB_SEAF_read
# no non-frameability
# C_RO (read only) of gNB <-> SEAF channel
cp $BASE_M4_FILE $NONF_GNB_SEAF_READ.m4
sed -i -e "s/dnl define(secure_and_ro_rules,/define(secure_and_ro_rules,/g" $NONF_GNB_SEAF_READ.m4
sed -i -e "s/SndS(<'gNB_seaf'/SndS_RO(<'gNB_seaf'/g" $NONF_GNB_SEAF_READ.m4
sed -i -e "s/RcvS(<'gNB_seaf'/In(msg), RcvS_RO(<'gNB_seaf'/g" $NONF_GNB_SEAF_READ.m4
m4 $NONF_GNB_SEAF_READ.m4 > $NONF_GNB_SEAF_READ.spthy
rm $NONF_GNB_SEAF_READ.m4

NONF_SEAF_AUSF_READ=5G_noNF_SEAF_AUSF_read
# no non-frameability
# C_RO (read only) of SEAF <-> AUSF channel
cp $BASE_M4_FILE $NONF_SEAF_AUSF_READ.m4
sed -i -e "s/dnl define(secure_and_ro_rules,/define(secure_and_ro_rules,/g" $NONF_SEAF_AUSF_READ.m4
sed -i -e "s/SndS(<'seaf_ausf'/SndS_RO(<'seaf_ausf'/g" $NONF_SEAF_AUSF_READ.m4
sed -i -e "s/RcvS(<'seaf_ausf'/In(msg), RcvS_RO(<'seaf_ausf'/g" $NONF_SEAF_AUSF_READ.m4
m4 $NONF_SEAF_AUSF_READ.m4 > $NONF_SEAF_AUSF_READ.spthy
rm $NONF_SEAF_AUSF_READ.m4

NONF_AUSF_ARPF_READ=5G_noNF_AUSF_ARPF_read
# no non-frameability
# C_RO (read only) of AUSF <-> ARPF channel
cp $BASE_M4_FILE $NONF_AUSF_ARPF_READ.m4
sed -i -e "s/dnl define(secure_and_ro_rules,/define(secure_and_ro_rules,/g" $NONF_AUSF_ARPF_READ.m4
sed -i -e "s/SndS(<'ausf_arpf'/SndS_RO(<'ausf_arpf'/g" $NONF_AUSF_ARPF_READ.m4
sed -i -e "s/RcvS(<'ausf_arpf'/In(msg), RcvS_RO(<'ausf_arpf'/g" $NONF_AUSF_ARPF_READ.m4
m4 $NONF_AUSF_ARPF_READ.m4 > $NONF_AUSF_ARPF_READ.spthy
rm $NONF_AUSF_ARPF_READ.m4

NF_NORMAL_BASE=5G_NF_normal
# non-frameability
# normal channels (no compromise)
cp $BASE_M4_FILE $NF_NORMAL_BASE.m4
sed -i -e "s/dnl define(enable_non_frameability,/define(enable_non_frameability,/g" $NF_NORMAL_BASE.m4
sed -i -e "s/dnl define.normal_channels,/define(normal_channels,/g" $NF_NORMAL_BASE.m4
m4 $NF_NORMAL_BASE.m4 > $NF_NORMAL_BASE.spthy
rm $NF_NORMAL_BASE.m4

NF_ALL_DY_BASE=5G_NF_all_DY
# non-frameability
# C_DY of all channels
cp $BASE_M4_FILE $NF_ALL_DY_BASE.m4
sed -i -e "s/dnl define(enable_non_frameability,/define(enable_non_frameability,/g" $NF_ALL_DY_BASE.m4
sed -i -e "s/dnl define(any_channel_dy,/define(any_channel_dy,/g" $NF_ALL_DY_BASE.m4
m4 $NF_ALL_DY_BASE.m4 > $NF_ALL_DY_BASE.spthy
rm $NF_ALL_DY_BASE.m4

NF_ALL_RO_BASE=5G_NF_all_RO
# non-frameability
# C_RO of all internal channels
cp $BASE_M4_FILE $NF_ALL_RO_BASE.m4
sed -i -e "s/dnl define(enable_non_frameability,/define(enable_non_frameability,/g" $NF_ALL_RO_BASE.m4
sed -i -e "s/dnl define(internal_ro_rules,/define(internal_ro_rules,/g" $NF_ALL_RO_BASE.m4
sed -i -e "s/RcvS(</In(msg), RcvS(</g" $NF_ALL_RO_BASE.m4
m4 $NF_ALL_RO_BASE.m4 > $NF_ALL_RO_BASE.spthy
rm $NF_ALL_RO_BASE.m4
