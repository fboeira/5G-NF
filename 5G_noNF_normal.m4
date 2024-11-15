changequote(<!,!>)dnl
changecom(<!@,@!>)dnl
theory 5G

/*
This model is an extended version of the 5G AKA model by Cremers and Dehnel-Wild as described in the paper. We have updated the original comments in this file to reflect our changes.

Results obtained using tamarin-prover 1.6.1
But latest release of Tamarin should work as well.

   Protocols:    		NF SETUP + 5G AKA + INITIAL_CONTEXT_SETUP_REQUEST + NAS SMC + AS SMC

   Based on:	Security Architecture and Procedures for 5G System:
				  3GPP TS 33.501 V17.4.2.

   Comments:	This theory models 5G AKA including the sequence number.
		The AMF and SEAF are modeled as an entity as the standards state that they are co-located.

		We do not model XOR (this is covered by Basin et al.)
			We do not believe this affects the validity of our results.
		Counter (SQN) re-sync is not modelled.

   Acronyms:
   	SUPI 	-> 	Subscription Permanent Identifier (IMSI).
		SUCI 	-> 	Subscription Concealed Identifier.

		UE 		-> 	User Equipment.
		SEAF 	-> 	Security Anchor Function.
		AUSF 	-> 	Authentication Server Function.
		ARPF 	-> 	Authentication Repository and Processing Function.

		SNID	->	Visited Public Land Mobile Network ID (VPLMN-Id)
				of the serving network, appended to string '5G'.
		HN 	->	Home network including AUSF and ARPF.
		SN	->	Serving network.

   Channels:	UE <-> gNB .<-->. SEAF/AMF .<-->. AUSF .<-->. ARPF/UDM
              SEAF/AMF .<-->. UPF
              gNB .<-->. UPF

   Terms:
		Assumptions:
		 ~SUPI is unique.
		 VPLMNID is unique and public.
		 ~sqn is the freshly generated part of SQN.
		 SQN = ~sqn + '1' + ... + '1'
		 req_confirm = 'true' | 'false'
		 SQN is a freshly initialized sequence number.

		TS 33.102 6.3 (3G):
		 ~RAND is freshly generated and unique.
		 MAC = f1(K, <SQN, RAND, AMF>)
		 XRES = f2(K, RAND)
		 CK = f3(K, RAND)
		 IK = f4(K, RAND)
		 AK = f5(K, RAND)
		 AUTN = <SQN, MAC>

		TS 33.501 6.1, A, X (5G):
		 SNID = <'5G', VPLMNID>
		 K_AUSF = KDFA(<CK, IK>, <SNID, SQN>)
		 	While K_AUSF and AUTN have been simplified, we do not believe this affects our results.
		 K_SEAF = KDFA( K_AUSF, SNID ) // As per TS 33.501 Annex A.6
		 XRES* = FX(<CK, IK, XRES, RAND>, SNID)
		 HXRES* = SHA256(<XRES*, RAND>)

     TS 33.501 6.2:
     KgNB is a key derived by ME and AMF from KAMF.

     TS 33.501 6.2.2.1
     NOTE 2: The SEAF is co-located with the AMF.

     TS 33.501 6.1.1.1
     Upon successful completion of the 5G AKA primary authentication, the AMF shall initiate NAS security mode command procedure (see clause 6.7.2) with the UE.


   Functions:
		TS 33.102 6.3:
		 f1 is a message authentication function.
		 f2 is a (possibly truncated) message authentication function.
		 f3 and f4 are key generating functions.
		 f5 is a key generating function or f5 = 0.

		TS 33.501 A, X:
		  Define key derivation function KDFA
		  Defines function FX
		  Both modelled here as hash functions.

   Pre-shared secret values:
   		Symmetric subscription key: (UE, ARPF, ~K)
		Sequence number: (UE, ARPF, ~sqn+'1')


   Model assumptions:
		- Each specific ARPF is initialized at most once.
		- Each specific AUSF is initialized at most once.
		- Each specific SEAF is initialized at most once.
		- A UE is subscribed at most once to a specific ARPF.
		- SEAF only requests one AV each time.
		- The channel between SEAF and AUSF provides
		  confidentiality and authenticity. Ditto AUSF-ARPF.


Partial deconstructions: Many rules contain In(x) where x is a term known by the attacker. This is used to prevent partial deconstructions according to the Tamarin manual: https://tamarin-prover.github.io/manual/book/009_precomputation.html
*/


dnl **************************************************************************************************
dnl
dnl // README:
dnl // With all the below section's macros, please remove the letters 'dnl' at the beginning of the
dnl // relevant line if you want to enable the specific macro definition. We use the model generation script
dnl // to generate the variants according to our scenarios
dnl
dnl **************************************************************************************************
dnl // If this is enabled, put a bunch of restrictions in to make the attack graphs look cleaner
dnl define(clean_attack, ``'')dnl
dnl **************************************************************************************************
dnl
dnl **************************************************************************************************
dnl // Non-Frameability enable
dnl define(enable_non_frameability, ``'')dnl
dnl **************************************************************************************************
dnl
dnl // Channel Compromise Section
dnl
dnl // This is the correct one for no channel compromise
define(normal_channels, ``'')dnl
dnl
dnl // SEAF_AUSF channel only compromised (DY)
dnl define(seaf_ausf_chan_only_dy, ``'')dnl
dnl // AUSF_ARPF channel only compromised (DY)
dnl define(ausf_arpf_chan_only_dy, ``'')dnl
dnl
dnl // Non DY compromises: Adversary gets Read-Only access to the channel
dnl // Both channels readable by adversary
dnl define(both_channels_readable, ``'')dnl
dnl // SEAF_AUSF channel only readable by adversary
dnl define(seaf_ausf_chan_only_readable, ``'')dnl
dnl // AUSF_ARPF channel only readable by adversary
dnl define(ausf_arpf_chan_only_readable, ``'')dnl
dnl
dnl // gNB channels only readable by adversary (gNB .<-->. SEAF/AMF and gNB .<-->. UPF)
dnl define(gnb_channels_only_readable, ``'')dnl
dnl
dnl // any_channel_dy: any channel with Dolev-Yao capaibilities
dnl define(any_channel_dy, ``'')dnl
dnl
dnl // dy and ro rules
dnl define(dy_ro_rules, ``'')dnl
dnl
dnl // internal_ro_rules, makes all internal channel read-only by attacker
dnl define(internal_ro_rules, ``'')dnl
dnl
dnl // secure_and_ro_rules, creates both secure and RO channel rules
dnl define(secure_and_ro_rules, ``'')dnl
dnl
dnl **************************************************************************************************
dnl
dnl
dnl
define(SndS, F_SndS($*))dnl
define(RcvS, F_RcvS($*))dnl


begin

builtins:
	multiset, symmetric-encryption, asymmetric-encryption, signing

functions:
	// AKA functions (TS 33.102)
	f1/2, 	 // MAC-function --> MAC
	f2/2, 	 // MAC-function --> RES
	f3/2, 	 // KDF 	 --> CK
	f4/2, 	 // KDF          --> IK
	f5/2, 	 // KDF          --> AK
	// KDFs
	KDFA/2,	 // KDF		 --> KASME* (Now also used for K_AUSF and K_SEAF generation; read Annex A.1, A.2, and A.6 of TS 33.501)
	FX/2,	 // (KD)F	 --> XRES*
	SHA256/2, // KDF		 --> HXRES*
  // NAS MAC
  NIA/2,
  //ECIES (https://www.usenix.org/system/files/sec21-wang-yuchen.pdf)
  encap/2,
  getkey/1,
  getcipher/1,
  decap/2

equations:
  decap(sk,getcipher(encap(pk(sk),R))) = getkey(encap(pk(sk),R))

dnl // DO NOT REMOVE THIS INCLUDE
dnl // The Channel Compromise rules and macros are in the following file:
include(channel_compromise.m4i)
dnl
dnl

/**********************************************************************************************************
 * Main 5G Models section
 **********************************************************************************************************/

// Initialize a serving network
rule init_ServNet:
	let SNID = <'5G', $VPLMNID>
	in
	[]
	--[
		ServNet($VPLMNID),
		SERV_NET()
	]->
	[!SEAF(SNID), Out(SNID)]

// Initialize a base station (gNB) connected to an AMF/SEAF
rule init_gNB:
  [!SEAF(SNID)]
  --[GNB_init($gNB)]->
  [!GNB($gNB, SNID)]

// Initialize a home network: ARPF
rule init_ARPF:
	[Fr(~HN)]
	--[ARPF_HomeNet($ARPF), Secret_HN($ARPF, ~HN)]->
	[!ARPF($ARPF, pk(~HN)), !ARPF_HN($ARPF, ~HN), Out(pk(~HN))]

// Initialize a home network: AUSF, attached to a particular ARPF ($ARPF)
rule init_AUSF:
	[!ARPF($ARPF, pk_HN)]
	--[
		AUSF_HomeNet($AUSF, $ARPF),
		AUSF_ID($AUSF)
	]->
	[!AUSF($AUSF, $ARPF)]

// Initialize the subscription
rule init_UE_ARPF:
	[Fr(~SUPI), Fr(~K), Fr(~sqn), !ARPF(ARPF, pk_HN)]
	--[
		Subscribe(~SUPI, ARPF),
		Sqn_Create(~sqn),       // used for sources lemma
		SUPI_ID(~SUPI),
		LongTermKey(~SUPI,~K)
	]->
	[!LTKSym(~SUPI, ARPF, ~K),
	  UESQN(~SUPI, ARPF, ~sqn+'1'),
	  ARPFEntry(ARPF, ~SUPI, ~sqn+'1', '1'),
    Out(~sqn)

    ifdef(<!enable_non_frameability!>,<!dnl
    , Setup_NF(~SUPI)
    !>,<! !>)dnl
    ]

ifdef(<!enable_non_frameability!>,<!dnl
/************************************/
/*    		 NF Setup Rules    	      */
/************************************/

rule UE_setup_send_req:
	let
    k_ECIES = getkey(encap(pk_HN, ~R))
    C0 = getcipher(encap(pk_HN,~R))

		sReq = <~SUPI, senc(<$t1, pk(~NF)>, ~K)>
    C = senc(sReq, k_ECIES)
    sig_req = sign(sReq, ~NF)
		setupReq = <<C0, C>, sig_req>
	in
	[	!LTKSym(~SUPI, ARPF, ~K),
    !ARPF(ARPF, pk_HN),
		Fr(~NF),
    Fr(~R),
		Setup_NF(~SUPI)
	]
	--[	UE_setup_send_req(~SUPI, ARPF, ~NF)
		]->
	[	Out(setupReq),
		UE_sent_req(~SUPI, ARPF, ~NF)]

rule HN_recv_setup_req_send_res:
	let
		sReq = <~SUPI, senc(<$t1, pk_NF>, ~K)>
    setupReq = <<C0, senc(sReq, k_ECIES)>, sig_req>
    k_ECIES = decap(~HN, C0)

		sig_setup = sign(<$t2, ~SUPI, pk_NF>, ~HN)
		setupRes = <$t2, sig_setup>
    beta_SUPI = <$t2, sig_setup, pk_NF>
	in
	[	In(setupReq),
    !ARPF_HN($ARPF, ~HN),
		!LTKSym(~SUPI, $ARPF, ~K), Fr(~R)]
	--[
			Eq(verify(sig_req, sReq, pk_NF), true), // check signature
			HN_recv_setup_req_send_res($ARPF, ~SUPI, pk_NF),
      Secret_HN($ARPF, ~HN)
		]->
	[	Out(setupRes),
		!ARPF_NF_Setup(~SUPI, beta_SUPI)
    ]

rule UE_recv_setup_res:
	let
		setupRes = <$t2, sig_setup>
    beta_SUPI = <$t2, sig_setup, pk(~NF)>
	in
	[	UE_sent_req(~SUPI, ARPF, ~NF),
		In(setupRes),
    !ARPF(ARPF, pk_HN),
	  !LTKSym(~SUPI, ARPF, ~K)]
	--[
			Eq(verify(sig_setup, <$t2, ~SUPI, pk(~NF)>, pk_HN), true), // check signature
			UE_recv_setup_res(~SUPI, ARPF, ~NF),
      Dispute(~SUPI, beta_SUPI)
			, Secret_NF(~NF)
		]->
	[!UE_NF_Setup(~SUPI, ~NF, beta_SUPI), !Rev_NF(~SUPI, ~NF)]
!>,<! !>)dnl

/************************************/
/*    	   	    Reveal    	      */
/************************************/

ifdef(<!enable_non_frameability!>,<!dnl
// Model compromised NF key for SUPI
rule reveal_NF:
  [!Rev_NF(~SUPI, ~NF)]
  --[Rev(<'NF', ~SUPI, ~NF>)]->
  [Out(~NF)]

!>,<! !>)dnl

// Model compromised home network private key
rule reveal_HN:
  [!ARPF_HN($ARPF, ~HN)]
  --[Rev(<'HN',$ARPF, ~HN>)]->
  [Out(~HN)]


// Model compromised subscriptions
rule reveal_LTKSym:
	[!LTKSym(~SUPI, ARPF, K)]
	--[ Rev(<~SUPI, ARPF>),
		RevealKforSUPI(~SUPI)
	]->
	[Out(<K, ~SUPI>)] // Reveal both K and SUPI

/************************************/
/*    	  Protocol Rules    	      */
/************************************/

// Attach Request
rule ue_send_attachReq:
	let
    UE_sec_capabilities = 'integrity_encryption'
    k_ECIES = getkey(encap(pk_HN, ~R))
    C0 = getcipher(encap(pk_HN,~R))
    SUCI = <C0, senc(~SUPI, k_ECIES)>
		msg = <SUCI, ARPF, UE_sec_capabilities, $gNB> // we add the gNB identity to abstract other layers that include this data element
	in
	[!LTKSym(~SUPI, ARPF, K), !GNB($gNB, SNID), !ARPF(ARPF, pk_HN), Fr(~R)
  ifdef(<!enable_non_frameability!>,<!dnl
    , !UE_NF_Setup(~SUPI, ~NF, beta_SUPI)
  !>,<! !>)dnl
  ]
	--[UE_send_attach()]->
	[St_1_USIM(~SUPI, ARPF, K, $gNB, k_ECIES, UE_sec_capabilities, SNID), Out(msg)]

// Attach Request
rule gNB_receive_attachReq [color=#edc080]:
  let
    msg = <SUCI, ARPF, UE_sec_capabilities, $gNB>
  in
  [!GNB($gNB, SNID), In(msg), Fr(~gNB_State_ID), In(UE_sec_capabilities)]
  --[
    //Out_Attach_SUPI(SUCI),
     Out_Attach_UE_sec_capabilities(UE_sec_capabilities),
     GNB_State_ID_source(~gNB_State_ID),
     Relay(SUCI),
     Relay(ARPF),
     Relay(UE_sec_capabilities),
     GNB_receive_attachReq()
     ]->
  [St_1_gNB(~gNB_State_ID, SNID, SUCI, ARPF, $gNB),
   SndS(<'gNB_seaf','gNB','SEAF'>,$gNB,SNID, <'attach', msg, ~gNB_State_ID>)]

// Attach Request
rule seaf_receive_attachReq [color=#0037ff]:
  let
    msg = <SUCI, ARPF, UE_sec_capabilities, $gNB>
  in
	[!SEAF(SNID), Fr(~SEAF_State_ID), In(UE_sec_capabilities), In(SUCI),
   RcvS(<'gNB_seaf','gNB','SEAF'>,$gNB,SNID, <'attach', msg, ~gNB_State_ID>)]
	--[
		StartSeafSession(SNID),
		SEAF_SUPI(SNID, SUCI),
    In_Attach_SUPI(SUCI),
    In_Attach_UE_sec_capabilities(UE_sec_capabilities),
		SEAF_ID(SNID),
		SEAF_State_ID_source(~SEAF_State_ID),
    SEAF_receive_attachReq()
	]->
	[St_1_SEAF(~gNB_State_ID, SNID, SUCI, ARPF, $gNB, ~SEAF_State_ID, UE_sec_capabilities)]

// SEAF Send Authentication Initiation Request (AIR) to AUSF
rule seaf_send_air [color=#0037ff]:
	let
		msg = <SUCI, SNID, '3gpp_creds'>
	in
	[St_1_SEAF(~gNB_State_ID, SNID, SUCI, ARPF, $gNB, SEAF_State_ID, UE_sec_capabilities), In(UE_sec_capabilities), In(SNID), !AUSF(AUSF, ARPF)]
	--[
		Send_AIR_to(AUSF, ARPF)
	  ]->
	[St_2_SEAF(~gNB_State_ID, SNID, SUCI, ARPF, AUSF, SEAF_State_ID, $gNB, UE_sec_capabilities),
	 SndS(<'seaf_ausf','SEAF','AUSF'>,SNID,AUSF, <'air', msg, SEAF_State_ID>)]

// Authentication Initiation Request (AIR)
rule ausf_receive_air:
	let
		msg = <SUCI, SNID, '3gpp_creds'>
	in
	[!AUSF(AUSF, ARPF), Fr(~AUSF_State_ID), In(SUCI), In(SNID),
	 RcvS(<'seaf_ausf','SEAF','AUSF'>,SNID,AUSF, <'air', msg, SEAF_State_ID>)]
	--[StartAUSFSession(AUSF),
	   AUSF_State_ID_source(~AUSF_State_ID)
	]->
	[St_1_AUSF(~AUSF_State_ID, SNID, SUCI, ARPF, AUSF, SEAF_State_ID)]

// AUSF Send AIReq to ARPF
rule ausf_send_AIReq:
	let
		msg = <SUCI, SNID, '3gpp_creds'>
	in
	[St_1_AUSF(~AUSF_State_ID, SNID, SUCI, ARPF, AUSF, SEAF_State_ID)]
	--[AUSF_source(AUSF),
	   ARPF_source(ARPF),
	   //SUPI_source(SUCI),
	   SEAF_source(SNID),
	   AUSF_Single_Session(AUSF)
		]->
	[St_2_AUSF(~AUSF_State_ID, SNID, SUCI, ARPF, AUSF, SEAF_State_ID),
	 SndS(<'ausf_arpf','AUSF','ARPF'>,AUSF,ARPF, <'air', msg, ~AUSF_State_ID>)]


// Authentication Initiation Request (AIR)
rule arpf_receive_AIReq:
	let
    SUCI = <C0, C>
		msg = <SUCI, SNID, '3gpp_creds'>

    k_ECIES = decap(~HN, C0)
    SUPI = sdec(C, k_ECIES)
	in
	[!ARPF(ARPF, pk_HN), !AUSF(AUSF, ARPF), !ARPF_HN(ARPF, ~HN), In(SUCI),
	 !LTKSym(SUPI, ARPF, K),
	 ARPFEntry(ARPF, SUPI, SQN, count),
	 Fr(~ARPF_State_ID),
	 In(count),
	RcvS(<'ausf_arpf','AUSF','ARPF'>,AUSF,ARPF, <'air', msg, ~AUSF_State_ID>)]
	--[
    Helper_kECIES_source(k_ECIES),
		StartARPFSession(ARPF),
		Sqn_ARPF_Use(SQN, count),
		ARPF_1()
	]->
	[ARPFEntry(ARPF, SUPI, SQN+'1', count+'1'),
	St_1_ARPF(~ARPF_State_ID, ARPF, AUSF, SUPI, SNID, K, k_ECIES, SQN+'1', ~AUSF_State_ID)]

// 5G Authentication Initiation Answer (5G-AIA)
rule arpf_send_AIResp:
	let
    RAND = ~RAND
		MAC = f1(K, <SQN, RAND>)
		XRES = f2(K, RAND)
		CK = f3(K, RAND)
		IK = f4(K, RAND)
		AUTN = < SQN, MAC >
		K_AUSF = KDFA(<CK, IK>, <SNID, SQN>)
		XRES_star = FX(<CK, IK, XRES, RAND>, SNID)

    5G_HE_AV = <RAND, AUTN, XRES_star, K_AUSF> // This is a 5G HE AV as per 33.501 v0.7.0 §6.1.3.2

    ifdef(<!enable_non_frameability!>,<!dnl
        msg = <5G_HE_AV, ~SUPI, k_ECIES, beta_SUPI>
    !>,<!
        msg = <5G_HE_AV, ~SUPI>
    !>)dnl
	in
	[St_1_ARPF(~ARPF_State_ID, ARPF, AUSF, ~SUPI, SNID, K, k_ECIES, SQN, ~AUSF_State_ID)
	, Fr(~RAND)

  ifdef(<!enable_non_frameability!>,<!dnl
  , !ARPF_NF_Setup(~SUPI, beta_SUPI)
  !>,<! !>)dnl

	]
	--[	Running(ARPF,<~SUPI,SNID,AUSF,ARPF>,KDFA(K_AUSF,SNID),<'ARPF','K_SEAF'>),
		Src(RAND, AUTN),
		SrcRand(RAND, ~SUPI),
		Secret1(<~SUPI,SNID,AUSF,ARPF>,<'K_AUSF', ARPF>, K_AUSF),
		Honest(<~SUPI, ARPF>),
		Honest(SNID),
    Out_AIResp(5G_HE_AV),
		ARPF_send(ARPF)
		, AUSF_State_ID_use(~AUSF_State_ID)
	]->
	[
	SndS(<'ausf_arpf','ARPF','AUSF'>, ARPF, AUSF, <'AIResp', msg, ~AUSF_State_ID>) // As per our proposed fix
	]

rule ausf_receive_AIResp:
	let
  5G_HE_AV = <RAND, AUTN, XRES_star, K_AUSF> // This is a 5G HE AV as per 33.501 v0.7.0 §6.1.3.2

  ifdef(<!enable_non_frameability!>,<!dnl
      beta_SUPI = <$t2, sig_setup, pk_NF>
      msg = <5G_HE_AV, ~SUPI, k_ECIES, beta_SUPI>
  !>,<!
      msg = <5G_HE_AV, ~SUPI>
  !>)dnl

	in
	[St_2_AUSF(~AUSF_State_ID, SNID, SUCI, ARPF, AUSF, SEAF_State_ID),
	 RcvS(<'ausf_arpf','ARPF','AUSF'>, ARPF, AUSF, <'AIResp', msg, ~AUSF_State_ID>)] // As per our proposed fix
	--[	In_AIResp(5G_HE_AV) ]->
  ifdef(<!enable_non_frameability!>,<!dnl
  	 [St_3_AUSF(~AUSF_State_ID, SNID, SUCI, ARPF, AUSF, 5G_HE_AV, SEAF_State_ID, ~SUPI, k_ECIES, beta_SUPI)]
    !>,<!
     [St_3_AUSF(~AUSF_State_ID, SNID, SUCI, ARPF, AUSF, 5G_HE_AV, SEAF_State_ID, ~SUPI)]
    !>)dnl

rule ausf_send_aia:
	let
    5G_HE_AV = <RAND, AUTN, XRES_star, K_AUSF>

  	HXRES_star = SHA256(XRES_star, RAND)
		K_SEAF = KDFA( K_AUSF, SNID ) // As per TS 33.501 Annex A.6
		5G_SE_AV = < RAND, AUTN, HXRES_star > // K_SEAF removed according to 33 501 v 17.4.2

		aia_msg = < 5G_SE_AV, 'true' > // SUPI removed according to 33 501 v 17.4.2
	in
    ifdef(<!enable_non_frameability!>,<!dnl
       [St_3_AUSF(~AUSF_State_ID, SNID, SUCI, ARPF, AUSF, 5G_HE_AV, ~SEAF_State_ID, ~SUPI, k_ECIES, beta_SUPI)]
      !>,<!
       [St_3_AUSF(~AUSF_State_ID, SNID, SUCI, ARPF, AUSF, 5G_HE_AV, ~SEAF_State_ID, ~SUPI)]
      !>)dnl
	--[	Running(AUSF,<~SUPI,SNID,AUSF,ARPF>,K_SEAF,<'AUSF','K_SEAF'>),
		Secret1(<~SUPI,SNID,AUSF,ARPF>,<'AUSF', AUSF>, K_SEAF),
		Honest(<~SUPI, ARPF>),
		AUSF_source(AUSF),
		SEAF_source(SNID),
		RAND_source(RAND),
		AUTN_source(AUTN),
		SUPI_source(~SUPI)
		, SEAF_State_ID_use(~SEAF_State_ID)
	]->
	[
ifdef(<!enable_non_frameability!>,<!dnl
  St_4_AUSF(~AUSF_State_ID, SNID, SUCI, ARPF, AUSF, XRES_star, K_SEAF, RAND, ~SEAF_State_ID, ~SUPI, k_ECIES, beta_SUPI),
!>,<!
  St_4_AUSF(~AUSF_State_ID, SNID, SUCI, ARPF, AUSF, XRES_star, K_SEAF, RAND, ~SEAF_State_ID, ~SUPI),
!>)dnl
	 SndS(<'seaf_ausf','AUSF','SEAF'>, AUSF, SNID, <'aia', aia_msg, ~SEAF_State_ID>)]

// 5G Authentication Initiation Answer (5G-AIA)
rule seaf_receive_aia [color=#0037ff]:
	let
		5G_SE_AV = < RAND, AUTN, HXRES_star > // K_SEAF removed according to 33 501 v 17.4.2

    msg = < 5G_SE_AV, 'true' > // SUPI removed according to 33 501 v 17.4.2
	in
	[St_2_SEAF(~gNB_State_ID, SNID, SUCI, ARPF, AUSF, ~SEAF_State_ID, $gNB, UE_sec_capabilities), In(UE_sec_capabilities), In(SNID),
	 RcvS(<'seaf_ausf','AUSF','SEAF'>, AUSF, SNID, <'aia', msg, ~SEAF_State_ID>)]
	--[	// Running(SNID,<~SUPI,SNID,AUSF,ARPF>,K_SEAF,<'SEAF','K_SEAF'>), // K_SEAF it not available at this point
      // Honest(<~SUPI, ARPF>) // SUPI not available at this point
      SEAF_receive_aia()
	]->
	[
  St_3_SEAF(~SEAF_State_ID, SNID, SUCI, ARPF, AUSF, RAND, HXRES_star, AUTN, ~gNB_State_ID, $gNB, UE_sec_capabilities)
  ]

// Authentication Request (Auth-Req)
rule seaf_send_authReq [color=#0037ff]:
	let
    msg = <RAND, AUTN>
	in
	[
  St_3_SEAF(~SEAF_State_ID, SNID, SUCI, ARPF, AUSF, RAND, HXRES_star, AUTN, ~gNB_State_ID, $gNB, UE_sec_capabilities), In(UE_sec_capabilities)
  ]
	--[
		Out_Src(RAND, AUTN),
		AuthReq_RAND_source(RAND),
		AuthReq_AUTN_source(AUTN),
    GNB_State_ID_use(~gNB_State_ID),
    SEAF_send_authReq()
	]->
	[
    St_4_SEAF(~SEAF_State_ID, SNID, SUCI, ARPF, AUSF, RAND, HXRES_star, $gNB, ~gNB_State_ID, UE_sec_capabilities),
    SndS(<'gNB_seaf','SEAF','gNB'>,SNID,$gNB, <'air', msg, ~gNB_State_ID>)
   ]

rule gnb_receive_authReq [color=#edc080]:
  let
    AUTN = <SQN, MAC>
    msg = <RAND, AUTN>
  in
  [St_1_gNB(~gNB_State_ID, SNID, SUCI, ARPF, $gNB),
   RcvS(<'gNB_seaf','SEAF','gNB'>,SNID, $gNB, <'air', msg, ~gNB_State_ID>)]
  --[Out_Src(RAND, AUTN),
      AuthReq_RAND_source(RAND),
      AuthReq_AUTN_source(AUTN),
      GNB_receive_authReq()
      ]->
  [
  St_2_gNB(~gNB_State_ID, SNID, SUCI, ARPF, $gNB, RAND, AUTN),
   Out(msg)]


// Authentication Request (Auth-Req)
// Note that SNID is sent here;
// this is not part of the protocol, but this is just a public value.
// The UE accepts a SQN iff it is greater than SQNMAX.
// The UE stores the greatest SQN accepted. (we allow jumps)
rule ue_receive_authReq:
	let
		RES = f2(K, RAND)
		IK = f4(K, RAND)
		CK = f3(K, RAND)
	  MAC = f1(K, <SQN, RAND>)
		AUTN = <SQN, MAC>
		RES_star = FX(<CK, IK, RES, RAND>, SNID)
		K_AUSF = KDFA(<CK, IK>, <SNID, SQN>)
		msg = <RAND, AUTN>
	in
	[St_1_USIM(~SUPI, ARPF, K, $gNB, k_ECIES, UE_sec_capabilities, SNID), UESQN(~SUPI, ARPF, SQNMAX), !AUSF(AUSF, ARPF), In(msg), In(UE_sec_capabilities), In(SNID)
	]
	--[
    UE_receive_authReq(),
		LessThan(SQNMAX, SQN),
		Sqn_Ue_Use(~SUPI, ARPF, SQN),
		Running(~SUPI,<~SUPI,SNID,AUSF,ARPF>,KDFA( K_AUSF, SNID ),<'SUPI','K_SEAF'>),
		Honest(<~SUPI, ARPF>),
		Honest(SNID)
	]->
	[St_2_UE(~SUPI, ARPF, K, $gNB, k_ECIES, RAND, SNID, AUSF, SQN, UE_sec_capabilities), UESQN(~SUPI, ARPF, SQN)]

// Authentication Response (Auth-Resp)
rule ue_send_authResp:
	let
		RES = f2(K, RAND)
		CK = f3(K, RAND)
		IK = f4(K, RAND)
		MAC = f1(K, <SQN, RAND>) // Broken (original: true to spec) version
		AUTN = <SQN, MAC>
		RES_star = FX(<CK, IK, RES, RAND>, SNID)
		K_AUSF = KDFA(<CK, IK>, <SNID, SQN>)
		K_SEAF = KDFA( K_AUSF, SNID ) // As per TS 33.501 Annex A.6 / TS 33.501 v0.7.0 6.1.3.2-6

    ifdef(<!enable_non_frameability!>,<!dnl
    msg = <RES_star, sign(<RES_star, $gNB, k_ECIES, $t>, ~NF), $t>
    !>,<!
    msg = RES_star
    !>)dnl

    ABBA = '5G_security_features' // TS 33 501 A.7.1
    K_AMF = KDFA(K_SEAF, <~SUPI, ABBA>)
    NAS_COUNT = '0' // initial NAS COUNT
    K_gNB = KDFA(K_AMF, NAS_COUNT)
	in
	[St_2_UE(~SUPI, ARPF, K, $gNB, k_ECIES, RAND, SNID, AUSF, SQN, UE_sec_capabilities), In(UE_sec_capabilities)
  ifdef(<!enable_non_frameability!>,<!dnl
    , !UE_NF_Setup(~SUPI, ~NF, beta_SUPI)
    !>,<! !>)dnl
  ]
	--[
		UE_END(),
		Secret1(<~SUPI,SNID,AUSF,ARPF>,<'UE', ~SUPI>, K_SEAF),
		Commit(~SUPI,<~SUPI,SNID,AUSF,ARPF>,K_SEAF,<'SUPI','K_SEAF'>),
		Honest(<~SUPI, ARPF>),
		Honest(SNID),
    Out_RES_star(RES_star)

    ifdef(<!enable_non_frameability!>,<!dnl
      , Running(~SUPI,<~SUPI,SNID,AUSF,ARPF>,K_gNB,<'SUPI','K_gNB'>)
    !>,<!
    !>)dnl
	]->
	[Out(msg), St_3_UE(~SUPI, ARPF, K, RAND, SNID, AUSF, SQN, K_AUSF, K_SEAF, UE_sec_capabilities)]

// Authentication Response (Auth-Resp) UE->gNB->SEAF
rule gnb_receive_authResp [color=#edc080]:
  let
    ifdef(<!enable_non_frameability!>,<!dnl
      msg = <RES_star, sig_NF, $t>
    !>,<!
      msg = RES_star
    !>)dnl
  in
  [
  St_2_gNB(~gNB_State_ID, SNID, SUCI, ARPF, $gNB, RAND, AUTN),
  In(msg)
  ]
  --[GNB_State_ID_use(~gNB_State_ID)
  ]->
  [St_3_gNB(~gNB_State_ID, SNID, SUCI, ARPF, $gNB, RAND, AUTN),
   SndS(<'gNB_seaf','gNB','SEAF'>, $gNB, SNID, <'attach', msg, ~gNB_State_ID>)
   ]
// Authentication Response (Auth-Resp)
rule seaf_receive_authResp [color=#0037ff]:
	let
		HXRES_star = SHA256(RES_star, RAND)

    ifdef(<!enable_non_frameability!>,<!dnl
      msg = <RES_star, sig_NF, $t>
    !>,<!
      msg = RES_star
    !>)dnl
	in
	[
    St_4_SEAF(~SEAF_State_ID, SNID, SUCI, ARPF, AUSF, RAND, HXRES_star, $gNB, ~gNB_State_ID, UE_sec_capabilities), In(UE_sec_capabilities),
    RcvS(<'gNB_seaf','gNB','SEAF'>,$gNB,SNID, <'attach', msg, ~gNB_State_ID>)
  ]
	--[GNB_State_ID_use(~gNB_State_ID)
    //, Eq(SHA256(RES_star, RAND), HXRES_star)
  ]->
	[
  ifdef(<!enable_non_frameability!>,<!dnl
  St_5_SEAF(~SEAF_State_ID, SNID, SUCI, ARPF, AUSF, RAND, RES_star, $gNB, ~gNB_State_ID, UE_sec_capabilities, sig_NF, $t)
  !>,<!
  St_5_SEAF(~SEAF_State_ID, SNID, SUCI, ARPF, AUSF, RAND, RES_star, $gNB, ~gNB_State_ID, UE_sec_capabilities)
  !>)dnl
  ]

// 5G Authentication Confirmation (5G-AC)
rule seaf_send_ac [color=#0037ff]:
	let
    ifdef(<!enable_non_frameability!>,<!dnl
		ac_msg = < RES_star, sig_NF, $t, $gNB > // no SUPI according to 33 501 v17.4.2
    !>,<!
    ac_msg = < RES_star >
    !>)dnl
	in
	[In(UE_sec_capabilities),
  ifdef(<!enable_non_frameability!>,<!dnl
  St_5_SEAF(~SEAF_State_ID, SNID, SUCI, ARPF, AUSF, RAND, RES_star, $gNB, ~gNB_State_ID, UE_sec_capabilities, sig_NF, $t)
  !>,<!
  St_5_SEAF(~SEAF_State_ID, SNID, SUCI, ARPF, AUSF, RAND, RES_star, $gNB, ~gNB_State_ID, UE_sec_capabilities)
  !>)dnl
  ]
	--[
		SEAF_END(),
		//Secret1(<~SUPI,SNID,AUSF,ARPF>,<'SEAF', SNID>, K_SEAF), // no K_SEAF available
		//Commit(SNID,<~SUPI,SNID,AUSF,ARPF>,K_SEAF,<'SEAF','K_SEAF'>), // no K_SEAF available
		//Honest(<~SUPI, ARPF>), // no SUPI available
		Honest(SNID),
    In_RES_star(RES_star)
	]->
	[SndS(<'seaf_ausf','SEAF','AUSF'>, SNID, AUSF, <'ac', ac_msg>),
  ifdef(<!enable_non_frameability!>,<!dnl
    St_6_SEAF(~SEAF_State_ID, SNID, SUCI, ARPF, AUSF, RAND, RES_star, $gNB, ~gNB_State_ID, UE_sec_capabilities, RES_star, sig_NF, $t)
    !>,<!
    St_6_SEAF(~SEAF_State_ID, SNID, SUCI, ARPF, AUSF, RAND, RES_star, $gNB, ~gNB_State_ID, UE_sec_capabilities)
    !>)dnl
   ]

// 5G Authentication Confirmation (5G-AC)
rule ausf_receive_ac_send_aca:
	let
    ifdef(<!enable_non_frameability!>,<!dnl
      beta_SUPI = <$t2, sig_setup, pk_NF>
      msg = < RES_star, sig_NF, $t, $gNB >
      aca_msg = <~SUPI, K_SEAF, k_ECIES, beta_SUPI>
    !>,<!
      msg = < RES_star >
      aca_msg = <~SUPI, K_SEAF>
    !>)dnl
	in
	[
  ifdef(<!enable_non_frameability!>,<!dnl
    St_4_AUSF(~AUSF_State_ID, SNID, SUCI, ARPF, AUSF, XRES_star, K_SEAF, RAND, SEAF_State_ID, ~SUPI, k_ECIES, beta_SUPI),
  !>,<!
    St_4_AUSF(~AUSF_State_ID, SNID, SUCI, ARPF, AUSF, XRES_star, K_SEAF, RAND, SEAF_State_ID, ~SUPI),
  !>)dnl
	 RcvS(<'seaf_ausf','SEAF','AUSF'>, SNID, AUSF, <'ac', msg>), In(SNID)]
	--[
		HSS_END(),
		Secret1(<~SUPI,SNID,AUSF,ARPF>,<'AUSF', AUSF>, K_SEAF),
		Commit(AUSF,<~SUPI,SNID,AUSF,ARPF>,K_SEAF,<'AUSF','K_SEAF'>),
		Honest(<~SUPI, ARPF>),
		Honest(SNID)
    ifdef(<!enable_non_frameability!>,<!dnl
      , Eq(verify(sig_NF, <RES_star, $gNB, k_ECIES, $t>, pk_NF), true) // check signature
    !>,<! !>)dnl
	]->
	[SndS(<'seaf_ausf','AUSF','SEAF'>,AUSF,SNID, <'confirm', aca_msg, SEAF_State_ID>)]

// 5G NAS Security Mode Command

// TS 24 501 5.4.2 Security mode control procedure
// TS 24 501 5.4.2.2  The AMF shall send the SECURITY MODE COMMAND message unciphered, but shall integrity protect the message with the 5G NAS integrity key based on KAMF or mapped K'AMF indicated by the ngKSI included in the message. The AMF shall set the security header type of the message to "integrity protected with new 5G NAS security context".

// TS 33 501 6.2.3.2
// A native ngKSI is associated with the KSEAF and KAMF derived during primary authentication. It is allocated by the SEAF and sent with the authentication request message to the UE where it is stored together with the KAMF.

// NAS Security Mode Command, TS 33 501 6.7.2
//1b. NAS Security Mode Command (ngKSI, UE sec capabilities, Ciphering Algorithm, Integrity Algorithm, [K_AMF_change_flag, ABBA parameter, request Initial NAS message flag, ]NAS MAC)
// This message shall be integrity protected (but not ciphered) with NAS integrity key based on the KAMF indicated by the ngKSI in the NAS Security Mode Command message (see Figure 6.7.2-1).

rule seaf_recv_aca_send_nas_SMCommand [color=#0037ff]: // SEAF -> gNB -> UE
let
  ifdef(<!enable_non_frameability!>,<!dnl
    beta_SUPI = <$t2, sig_setup, pk_NF>
    msg = <~SUPI, K_SEAF, k_ECIES, beta_SUPI>
    CTX_NF = <~SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, $t, $gNB>
  !>,<!
    msg = <~SUPI, K_SEAF>
  !>)dnl

  IEI = 'NAS_key_set_identifier_IEI'
  TSC = '0'
  NAS_ksi = $NAS_ksi
  ngKSI = <IEI, TSC, NAS_ksi> // TS 24 501 9.11.3.32

  Ciphering_Algorithm = 'NEAx'
  Integrity_Algorithm = 'NIAx'
  K_AMF_change_flag = '0'
  ABBA = '5G_security_features' // TS 33 501 A.7.1
  request_Initial_NAS_message_flag = '1'

  K_AMF = KDFA(K_SEAF, <~SUPI, ABBA>)
  K_NASint = KDFA(K_AMF, 'NASint')

  SMCommand_Payload = <ngKSI, UE_sec_capabilities, Ciphering_Algorithm, Integrity_Algorithm, K_AMF_change_flag, ABBA, request_Initial_NAS_message_flag>
  MAC = NIA(K_NASint, SMCommand_Payload)

  SMCommand = <SMCommand_Payload, MAC>
in
  [
  ifdef(<!enable_non_frameability!>,<!dnl
    St_6_SEAF(~SEAF_State_ID, SNID, SUCI, ARPF, AUSF, RAND, RES_star, $gNB, ~gNB_State_ID, UE_sec_capabilities, RES_star, sig_NF, $t),
    !>,<!
    St_6_SEAF(~SEAF_State_ID, SNID, SUCI, ARPF, AUSF, RAND, RES_star, $gNB, ~gNB_State_ID, UE_sec_capabilities),
    !>)dnl
   RcvS(<'seaf_ausf','AUSF','SEAF'>,AUSF,SNID, <'confirm', msg, ~SEAF_State_ID>), In(UE_sec_capabilities), In(SNID),
   !ARPF(ARPF, pk_HN), In(RES_star)]
  --[Out_SMC(SMCommand), GNB_State_ID_use(~gNB_State_ID),

      ifdef(<!enable_non_frameability!>,<!dnl
      Eq(verify(sig_setup, <$t2, ~SUPI, pk_NF>, pk_HN), true), // check signature
      Eq(verify(sig_NF, <RES_star, $gNB, k_ECIES, $t>, pk_NF), true), // check signature
      POI_CTX_SEAF(CTX_NF),
      !>,<! !>)dnl

      Out_MAC(MAC),
      Secret1(<~SUPI,SNID,AUSF,ARPF>,<'K_SEAF', SNID>, K_SEAF),
      Secret1(<~SUPI,SNID,AUSF,ARPF>,<'K_AMF', SNID>, K_AMF),
      Honest(<~SUPI,ARPF>),
      Honest(SNID)
      ]->
  [
  ifdef(<!enable_non_frameability!>,<!dnl
  St_7_SEAF(~SEAF_State_ID, SNID, ~SUPI, ARPF, AUSF, RAND, RES_star, K_SEAF, K_AMF, $gNB, ~gNB_State_ID, UE_sec_capabilities, CTX_NF),
  !>,<!
  St_7_SEAF(~SEAF_State_ID, SNID, ~SUPI, ARPF, AUSF, RAND, RES_star, K_SEAF, K_AMF, $gNB, ~gNB_State_ID, UE_sec_capabilities),
  !>)dnl
   SndS(<'gNB_seaf','SEAF','gNB'>,SNID,$gNB, <'SMCommand', SMCommand, ~gNB_State_ID>)]

rule gnb_relay_nas_SMCommand [color=#edc080]:
let
  SMCommand_Payload = <ngKSI, UE_sec_capabilities, Ciphering_Algorithm, Integrity_Algorithm, K_AMF_change_flag, ABBA, request_Initial_NAS_message_flag>
  SMCommand = <SMCommand_Payload, MAC>
  msg = SMCommand
in
  [St_3_gNB(~gNB_State_ID, SNID, SUCI, ARPF, $gNB, RAND, AUTN), In(UE_sec_capabilities), In(SMCommand_Payload),
   RcvS(<'gNB_seaf','SEAF','gNB'>,SNID,$gNB, <'SMCommand', msg, ~gNB_State_ID>)]
  --[In_SMC(SMCommand), In_Sec_Cap(UE_sec_capabilities), In_MAC(MAC)]->
  [St_4_gNB(~gNB_State_ID, SNID, SUCI, ARPF, $gNB, RAND, AUTN),
   Out(SMCommand)]

// 5G NAS Security Mode Complete

rule ue_recv_nas_SMCommand_send_nas_SMComplete:
let
  ABBA = '5G_security_features' // TS 33 501 A.7.1
  K_AMF = KDFA(K_SEAF, <~SUPI, ABBA>)
  K_NASint = KDFA(K_AMF, 'NASint')
  K_NASenc = KDFA(K_AMF, 'NASenc')

  SMCommand_Payload = <ngKSI, UE_sec_capabilities, Ciphering_Algorithm, Integrity_Algorithm, K_AMF_change_flag, ABBA, request_Initial_NAS_message_flag>
  MAC = NIA(K_NASint, SMCommand_Payload)
  SMCommand = <SMCommand_Payload, MAC>

  NASContainer = <~SUPI, ARPF, UE_sec_capabilities>
  SMComplete_Payload = <NASContainer, NIA(K_NASint, NASContainer)>
  SMComplete = senc(SMComplete_Payload, K_NASenc)
in
  [St_3_UE(~SUPI, ARPF, K, RAND, SNID, AUSF, SQN, K_AUSF, K_SEAF, UE_sec_capabilities), In(UE_sec_capabilities),
   In(SMCommand)]
  --[Out_Sec_Cap(UE_sec_capabilities), Out_NAS_SMComplete(SMComplete)
  ]->
  [Out(SMComplete),
   St_4_UE(~SUPI, ARPF, K, RAND, SNID, AUSF, SQN, K_AUSF, K_SEAF, ngKSI, K_AMF, K_NASint, K_NASenc, UE_sec_capabilities)]

rule gnb_relay_nas_SMComplete [color=#edc080]:
let
msg = SMComplete
in
  [St_4_gNB(~gNB_State_ID, SNID, SUCI, ARPF, $gNB, RAND, AUTN),
   In(SMComplete)]
  --[
      In_NAS_SMComplete(SMComplete), GNB_State_ID_use(~gNB_State_ID)
    ]->
  [SndS(<'gNB_seaf','gNB','SEAF'>,$gNB,SNID, <'SMComplete', msg, ~gNB_State_ID>),
   St_5_gNB(~gNB_State_ID, SNID, SUCI, ARPF, $gNB, RAND, AUTN)]

 // TS 33 501 6.8.1.2.2
 // The AMF shall communicate the KgNB/KeNB to the serving gNB/ng-eNB in the NGAP procedure INITIAL CONTEXT SETUP. The UE shall derive the KgNB/KeNB from the KAMF of the current 5G NAS security context using the NAS uplink COUNT corresponding to the NAS message that initiated transition from CM-IDLE to CM-CONNECTED state.

// TS 33 501 6.9.2.1.1
// The AMF shall not send the NH value to gNB/ng-eNB at the initial connection setup. The gNB/ng-eNB shall initialize the NCC value to zero after receiving NGAP Initial Context Setup Request message.
rule seaf_recv_SMComplete [color=#0037ff]:
  let
    NAS_COUNT = '0' // initial NAS COUNT
    K_gNB = KDFA(K_AMF, NAS_COUNT)
    K_NASint = KDFA(K_AMF, 'NASint')
    K_NASenc = KDFA(K_AMF, 'NASenc')

    NASContainer = <~SUPI, ARPF, UE_sec_capabilities>
    SMComplete_Payload = <NASContainer, NIA(K_NASint, NASContainer)>
    SMComplete = senc(SMComplete_Payload, K_NASenc)
    msg = SMComplete

    ifdef(<!enable_non_frameability!>,<!dnl
    CTX_NF = <~SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, $t, $gNB>
    init_PDUSession = <~SUPI, ~PDUsession, CTX_NF>
    init_PDUSession_gNB = <~PDUsession, CTX_NF>
    !>,<!
    init_PDUSession = <~SUPI, ~PDUsession>
    init_PDUSession_gNB = <~PDUsession>
    !>)dnl

    msg_out = <'INITIAL_CONTEXT_SETUP_REQUEST', K_gNB, init_PDUSession_gNB>
  in
    [
    In(UE_sec_capabilities),
    ifdef(<!enable_non_frameability!>,<!dnl
    St_7_SEAF(~SEAF_State_ID, SNID, ~SUPI, ARPF, AUSF, RAND, RES_star, K_SEAF, K_AMF, $gNB, ~gNB_State_ID, UE_sec_capabilities, CTX_NF),
    !>,<!
    St_7_SEAF(~SEAF_State_ID, SNID, ~SUPI, ARPF, AUSF, RAND, RES_star, K_SEAF, K_AMF, $gNB, ~gNB_State_ID, UE_sec_capabilities),
    !>)dnl
   RcvS(<'gNB_seaf','gNB','SEAF'>,$gNB,SNID, <'SMComplete', msg, ~gNB_State_ID>), Fr(~PDUsession), Fr(~seaf_UPF_ID), In(RES_star)]
  --[
    ifdef(<!enable_non_frameability!>,<!dnl
    Helper_kECIES(k_ECIES),
    !>,<! !>)dnl
    Rule_seaf_recv_SMComplete(), GNB_State_ID_use(~gNB_State_ID), UPF_State_ID_source(~seaf_UPF_ID)
  ]->
  [St_8_SEAF(~SEAF_State_ID, SNID, ~SUPI, ARPF, AUSF, RAND, RES_star, K_SEAF, K_AMF, K_gNB, $gNB, ~gNB_State_ID, UE_sec_capabilities),
  SndS(<'seaf_UPF','SEAF','UPF'>,SNID,$UPF, <'INIT_PDU_SESSION', init_PDUSession, ~seaf_UPF_ID>),
  SndS(<'gNB_seaf','SEAF','gNB'>,SNID,$gNB, <'INITIAL_CONTEXT_SETUP_REQUEST', msg_out, ~gNB_State_ID>)
  ]

rule init_PDU_session_UPF:
let
ifdef(<!enable_non_frameability!>,<!dnl
beta_SUPI = <$t2, sig_setup, pk_NF>
CTX_NF = <~SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, $t, $gNB>
init_PDUSession = <~SUPI, ~PDUsession, CTX_NF>
!>,<!
init_PDUSession = <~SUPI, ~PDUsession>
!>)dnl
msg = init_PDUSession
in
[RcvS(<'seaf_UPF','SEAF','UPF'>,SNID,$UPF, <'INIT_PDU_SESSION', msg, ~seaf_UPF_ID>)
, !ARPF(ARPF, pk_HN) // This can be seen as the public key of the operator being configured into the UPF
, In(RES_star)
]
--[
UPF_State_ID_use(~seaf_UPF_ID)
ifdef(<!enable_non_frameability!>,<!dnl
      , Eq(verify(sig_setup, <$t2, ~SUPI, pk_NF>, pk_HN), true) // check signature
      , Eq(verify(sig_NF, <RES_star, $gNB, k_ECIES, $t>, pk_NF), true) // check signature
      , POI_CTX_UPF(CTX_NF)
!>,<!
!>)dnl
]->
[St_1_UPF(init_PDUSession)]

// 5G AS Security Mode Command
// TS 33 51 6.7.4
// AS SMC shall be used only during an initial context setup between the UE and the gNB/ng-eNB (i.e., to activate an initial KgNB at RRC_IDLE to RRC_CONNECTED state transition).

rule gnb_send_as_SMCommand [color=#edc080]:
  let
    K_RRCint = KDFA(K_gNB, 'N_RRC_int_alg') // TS 33 501 A.8
    K_RRCenc = KDFA(K_gNB, 'N_RRC_enc_alg') // TS 33 501 A.8
    K_UPenc = KDFA(K_gNB, 'N_UP_enc_alg') // TS 33 501 A.8
    K_UPint = KDFA(K_gNB, 'N_UP_int_alg') // TS 33 501 A.8

    ifdef(<!enable_non_frameability!>,<!dnl
    beta_SUPI = <$t2, sig_setup, pk_NF>
    CTX_NF = <~SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, $t, $gNB>
    init_PDUSession_gNB = <~PDUsession, CTX_NF>
    !>,<!
    init_PDUSession_gNB = <~PDUsession>
    !>)dnl

    msg = <'INITIAL_CONTEXT_SETUP_REQUEST', K_gNB, init_PDUSession_gNB>

    Ciphering_Algorithm = 'NEAx'
    Integrity_Algorithm = 'NIAx'
    AS_SMCommand = <Ciphering_Algorithm, Integrity_Algorithm, NIA(K_RRCint, <Ciphering_Algorithm, Integrity_Algorithm>)>

  in
  [St_5_gNB(~gNB_State_ID, SNID, SUCI, ARPF, $gNB, RAND, AUTN),
   RcvS(<'gNB_seaf','SEAF','gNB'>,SNID,$gNB, <'INITIAL_CONTEXT_SETUP_REQUEST', msg, ~gNB_State_ID>)
   , In(RES_star)
   ]
  --[
     ]->
  [St_6_gNB(~gNB_State_ID, SNID, SUCI, ARPF, $gNB, RAND, AUTN, K_gNB, K_RRCint, K_RRCenc, K_UPenc, K_UPint, ~PDUsession),
  ifdef(<!enable_non_frameability!>,<!dnl
  St_gNB_CTX_NF(CTX_NF),
  !>,<!
  !>)dnl
   Out(AS_SMCommand)]

// 5G AS Security Mode Complete
// TS 38 331 5.3.4.3
// Reception of the SecurityModeCommand by the UE

rule ue_recv_as_SMCommand_send_as_SMComplete:
  let
    NAS_COUNT = '0' // initial NAS COUNT
    K_gNB = KDFA(K_AMF, NAS_COUNT)
    K_RRCint = KDFA(K_gNB, 'N_RRC_int_alg') // TS 33 501 A.8
    K_RRCenc = KDFA(K_gNB, 'N_RRC_enc_alg') // TS 33 501 A.8
    K_UPenc = KDFA(K_gNB, 'N_UP_enc_alg') // TS 33 501 A.8
    K_UPint = KDFA(K_gNB, 'N_UP_int_alg') // TS 33 501 A.8

    AS_SMCommand = <Ciphering_Algorithm, Integrity_Algorithm, NIA(K_RRCint, <Ciphering_Algorithm, Integrity_Algorithm>)>
    AS_SMComplete = <'Secure_Command_Complete', NIA(K_RRCint, 'Secure_Command_Complete')>
  in
  [St_4_UE(~SUPI, ARPF, K, RAND, SNID, AUSF, SQN, K_AUSF, K_SEAF, ngKSI, K_AMF, K_NASint, K_NASenc, UE_sec_capabilities), In(UE_sec_capabilities),
    In(AS_SMCommand)]
  --[AS_SMComplete(),
     Secret1(<~SUPI,SNID,'AUSF',ARPF>,<'KGNB', ARPF>, K_gNB),
     Honest(<~SUPI, ARPF>)
  ]->
  [Out(AS_SMComplete),
    St_5_UE(~SUPI, ARPF, K, RAND, SNID, AUSF, SQN, K_AUSF, K_SEAF, ngKSI, K_AMF, K_NASint, K_NASenc, UE_sec_capabilities, K_gNB, K_RRCint, K_RRCenc, K_UPint, K_UPenc)]

rule gnb_recv_as_SMComplete [color=#edc080]:
let
AS_SMComplete = <'Secure_Command_Complete', NIA(K_RRCint, 'Secure_Command_Complete')>
in
[St_6_gNB(~gNB_State_ID, SNID, SUCI, ARPF, $gNB, RAND, AUTN, K_gNB, K_RRCint, K_RRCenc, K_UPenc, K_UPint, ~PDUsession),
In(AS_SMComplete)]
--[
ifdef(<!enable_non_frameability!>,<!dnl
//  Commit(SNID,<~SUPI,SNID,'AUSF',ARPF>,K_gNB,<'gNB','K_gNB'>)
!>,<!
!>)dnl
]->
[St_7_gNB(~gNB_State_ID, SNID, SUCI, ARPF, $gNB, RAND, AUTN, K_gNB, K_RRCint, K_RRCenc, K_UPenc, K_UPint, ~PDUsession)]

ifdef(<!enable_non_frameability!>,<!dnl

// TS 38.323 4.2.2
rule ue_send_data:
let
  APP = <~appData, sign(~appData, ~NF)>
  APP_int = NIA(K_UPint, ~appData)
  PDCP = senc(<APP, APP_int>, K_UPenc)
in
[St_5_UE(~SUPI, ARPF, K, RAND, SNID, AUSF, SQN, K_AUSF, K_SEAF, ngKSI, K_AMF, K_NASint, K_NASenc, UE_sec_capabilities, K_gNB, K_RRCint, K_RRCenc, K_UPint, K_UPenc), Fr(~appData), !UE_NF_Setup(~SUPI, ~NF, beta_SUPI), In(UE_sec_capabilities)]
--[UserSend(~SUPI, APP)]->
[Out(PDCP)]

rule gnb_recv_data:
let
  APP = <~appData, sigApp>
  APP_int = NIA(K_UPint, ~appData)
  PDCP = senc(<APP, APP_int>, K_UPenc)

  ifdef(<!enable_non_frameability!>,<!dnl
  beta_SUPI = <$t2, sig_setup, pk_NF>
  CTX_NF = <~SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, $t, $gNB>
  !>,<!
  !>)dnl
in
[St_7_gNB(~gNB_State_ID, SNID, SUCI, ARPF, $gNB, RAND, AUTN, K_gNB, K_RRCint, K_RRCenc, K_UPenc, K_UPint, ~PDUsession), In(PDCP) , In(RES_star)
ifdef(<!enable_non_frameability!>,<!dnl
, St_gNB_CTX_NF(CTX_NF)
!>,<!
!>)dnl
]
--[ UPF_GNB_State_ID_source(~PDUsession),
    Eq(verify(sigApp, ~appData, pk_NF), true) // check signature
    ]->
[SndS(<'gNB_UPF','gNB','UPF'>, $gNB, ~PDUsession, <'UP', APP, ~PDUsession>)]

rule upf_rcv_data:
let
beta_SUPI = <$t2, sig_setup, pk_NF>
CTX_NF = <~SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, $t, $gNB>
init_PDUSession = <~SUPI, ~PDUsession, CTX_NF>
APP = <~appData, sigApp>
msg = APP
in
[St_1_UPF(init_PDUSession), RcvS(<'gNB_UPF','gNB','UPF'>, $gNB, ~PDUsession, <'UP', msg, ~PDUsession>), In(RES_star)]
--[POI_UPF(CTX_NF, APP), Eq(verify(sigApp, ~appData, pk_NF), true), UPF_recv_data(),
    UPF_GNB_State_ID_use(~PDUsession)]->
[]

!>,<!
!>)dnl

/************************************************************************************************************/
/* End of Models */
/************************************************************************************************************/

/* Restrictions & Axioms */

restriction ARPF_HomeNet_once:
	" All ARPF #i #j. ARPF_HomeNet(ARPF)@i & ARPF_HomeNet(ARPF)@j ==> #i = #j "

restriction AUSF_HomeNet_once_link:
	" All AUSF ARPF ARPF1 #i #j. AUSF_HomeNet(AUSF, ARPF)@i & AUSF_HomeNet(AUSF, ARPF1)@j ==> #i = #j "

restriction Subscribe_once:
	" All ARPF ARPF1 SUPI #i #j. Subscribe(SUPI, ARPF)@i & Subscribe(SUPI, ARPF1)@j ==> #i = #j "

restriction ServNet_once:
	" All VPLMNID #i #j. ServNet(VPLMNID)@i & ServNet(VPLMNID)@j ==> #i = #j "

restriction gNB_once:
  " All gNB #i #j. GNB_init(gNB)@i & GNB_init(gNB)@j ==> #i = #j "

ifdef(<!enable_non_frameability!>,<!dnl

restriction Equality:
/* Restriction used to only consider traces where x is equal to y when the action fact Eq(x, y) is used */
		"All x y #i. Eq(x,y) @i ==> x = y"

restriction setup_once:
  "All ARPF ARPF2 SUPI pk_NF pk_NF2 #i #j. HN_recv_setup_req_send_res(ARPF, SUPI, pk_NF)@i & HN_recv_setup_req_send_res(ARPF2, SUPI, pk_NF2)@j ==> #i = #j"

restriction setup_req_once:
  "All SUPI ARPF ARPF1 NF NF1 #i #j. UE_setup_send_req(SUPI, ARPF, NF)@i & UE_setup_send_req(SUPI, ARPF1, NF1)@j ==> #i = #j"

!>,<! !>)dnl

ifdef(<!clean_attack!>, <!dnl
    // This is just to see if we can still create the attack with these rules firing only once.
    // The aim of these is to make the attack graphs look cleaner overall.
    restriction One_home_net:
    	" All x y ARPF SUPI #i #j. Subscribe(x, y)@i & Subscribe(SUPI, ARPF)@j ==> #i = #j "
    restriction AUSF_once:
    	" All AUSF #i #j. AUSF_ID(AUSF)@i & AUSF_ID(AUSF)@j ==> #i = #j "
    restriction serv_net_ONCE:
    	" All #i #j. SERV_NET()@i & SERV_NET()@j ==> #i = #j "
    restriction ARPF_once:
    	" All #i #j. ARPF_1()@i & ARPF_1()@j ==> #i = #j "
    restriction seaf_supi_once:
      " All SNID SUPI #i #j. SEAF_SUPI(SNID, SUPI)@i & SEAF_SUPI(SNID, SUPI)@j ==> #i = #j "
!>,<!dnl
!>)dnl
dnl

restriction LessThan:
	" All x y #i. LessThan(x,y)@#i ==> Ex z. x + z = y "

/************************************************************************************************************/
/* Beginning of Lemmas */
/************************************************************************************************************/

/** Sources lemmas **/

ifdef(<!enable_non_frameability!>,<!dnl
/*
lemma helper_ecies [sources]:
"All k #i. Helper_kECIES(k)@i ==> Ex #j. Helper_kECIES_source(k)@j & #j < #i"
*/
!>,<!
!>)dnl

lemma mac_sources [sources]:
"All MAC #i. In_MAC(MAC)@i ==> (
			(Ex #j. Out_MAC(MAC)@j & #j < #i)
		| (Ex #k. KU(MAC)@k & #k<#i)
	)
"

lemma 5G_HE_AV_sources [sources]:
"All 5G_HE_AV #i. In_AIResp(5G_HE_AV)@i ==>
  (
      (Ex #j. KU(5G_HE_AV)@j & #j < #i)
    | (Ex #j. Out_AIResp(5G_HE_AV)@j & #j < #i)
  )"

/*
lemma Attach_SUPI_sources [sources]:
"All SUPI #i. In_Attach_SUPI(SUPI)@i ==>
  (
      (Ex #j. KU(SUPI)@j & #j < #i)
    | (Ex #j. Out_Attach_SUPI(SUPI)@j & #j < #i)
  )"
  */

lemma UE_sec_capabilities_attach_sources [sources]:
"All UE_sec_capabilities #i. In_Attach_UE_sec_capabilities(UE_sec_capabilities)@i ==>
  (
      (Ex #j. KU(UE_sec_capabilities)@j & #j < #i)
    | (Ex #j. Out_Attach_UE_sec_capabilities(UE_sec_capabilities)@j & #j < #i)
  )"

lemma RES_star_sources [sources]:
"All RES_star #i. In_RES_star(RES_star)@i ==>
  (
      (Ex #j. KU(RES_star)@j & #j < #i)
    | (Ex #j. Out_RES_star(RES_star)@j & #j < #i)
  )"

/** Key Helper lemmas **/

ifdef(<!enable_non_frameability!>,<!dnl
lemma secrecy_NF [reuse]:
  " All NF #i. Secret_NF(NF)@i ==>
    (
          (not Ex #k. KU(NF)@k)
        | Ex SUPI #r. Rev(<'NF', SUPI, NF>)@r
    )
  "
!>,<!
!>)dnl

lemma secrecy_HN [reuse]:
  "All ARPF HN #i. Secret_HN(ARPF, HN)@i ==>
    (
        (not Ex #k. KU(HN)@k)
      | (Ex #r. Rev(<'HN', ARPF, HN>)@r)
    )
  "

/*
lemma ECIES_helper [reuse]:
  "All sk R #i. KU(getkey(encap(pk(sk), R)))@i ==>
  (
      (Ex #j. KU(R)@j & j<i)
    | (Ex #j. KU(sk)@j)
  )
  "
*/

/** Executability lemmas **/

lemma trace_exists:
	exists-trace
	" Ex #i. HSS_END()@i
		& not (Ex X #r. Rev(X)@r)
		& (All ARPF1 ARPF2 #j #k. ARPF_HomeNet(ARPF1)@j &
					  ARPF_HomeNet(ARPF2)@k ==> #j = #k)
		& (All S1 S2 ARPF1 ARPF2 #j #k. Subscribe(S1, ARPF1)@j &
						Subscribe(S2, ARPF2)@k ==> #j = #k)
		& (All SQN1 c1 SQN2 c2 #j #k. Sqn_ARPF_Use(SQN1, c1)@j &
						  Sqn_ARPF_Use(SQN2, c2)@k ==> #j = #k)
		& (All AUSF AUSF2 #j #k. StartAUSFSession(AUSF)@j &
						  StartAUSFSession(AUSF2)@k ==> #j = #k)
		& (All AUSF AUSF2 #j #k. AUSF_ID(AUSF)@j &
						  AUSF_ID(AUSF2)@k ==> #j = #k)
		& (All SNID1 SNID2 #j #k. StartSeafSession(SNID1)@j &
						  StartSeafSession(SNID2)@k ==> #j = #k)
		& (All ARPF1 ARPF2 #j #k. StartARPFSession(ARPF1)@j &
					  StartARPFSession(ARPF2)@k ==> #j = #k)"

lemma trace_exists_NAS_SMC:
  exists-trace
  " Ex #j. Rule_seaf_recv_SMComplete()@j
    & not (Ex X #r. Rev(X)@r)
    & (All ARPF1 ARPF2 #j #k. ARPF_HomeNet(ARPF1)@j &
            ARPF_HomeNet(ARPF2)@k ==> #j = #k)
    & (All S1 S2 ARPF1 ARPF2 #j #k. Subscribe(S1, ARPF1)@j &
            Subscribe(S2, ARPF2)@k ==> #j = #k)
    & (All SQN1 c1 SQN2 c2 #j #k. Sqn_ARPF_Use(SQN1, c1)@j &
              Sqn_ARPF_Use(SQN2, c2)@k ==> #j = #k)
    & (All AUSF AUSF2 #j #k. StartAUSFSession(AUSF)@j &
              StartAUSFSession(AUSF2)@k ==> #j = #k)
    & (All AUSF AUSF2 #j #k. AUSF_ID(AUSF)@j &
              AUSF_ID(AUSF2)@k ==> #j = #k)
    & (All SNID1 SNID2 #j #k. StartSeafSession(SNID1)@j &
              StartSeafSession(SNID2)@k ==> #j = #k)
    & (All ARPF1 ARPF2 #j #k. StartARPFSession(ARPF1)@j &
            StartARPFSession(ARPF2)@k ==> #j = #k)"

lemma trace_exists_AS_SMComplete:
  exists-trace
  " Ex #j. AS_SMComplete()@j
    & not (Ex X #r. Rev(X)@r)
    & (All ARPF1 ARPF2 #j #k. ARPF_HomeNet(ARPF1)@j &
            ARPF_HomeNet(ARPF2)@k ==> #j = #k)
    & (All S1 S2 ARPF1 ARPF2 #j #k. Subscribe(S1, ARPF1)@j &
            Subscribe(S2, ARPF2)@k ==> #j = #k)
    & (All SQN1 c1 SQN2 c2 #j #k. Sqn_ARPF_Use(SQN1, c1)@j &
              Sqn_ARPF_Use(SQN2, c2)@k ==> #j = #k)
    & (All AUSF AUSF2 #j #k. StartAUSFSession(AUSF)@j &
              StartAUSFSession(AUSF2)@k ==> #j = #k)
    & (All AUSF AUSF2 #j #k. AUSF_ID(AUSF)@j &
              AUSF_ID(AUSF2)@k ==> #j = #k)
    & (All SNID1 SNID2 #j #k. StartSeafSession(SNID1)@j &
              StartSeafSession(SNID2)@k ==> #j = #k)
    & (All ARPF1 ARPF2 #j #k. StartARPFSession(ARPF1)@j &
            StartARPFSession(ARPF2)@k ==> #j = #k)
    & (All gNB1 gNB2 #j #k. GNB_init(gNB1)@j &
            GNB_init(gNB2)@k ==> #j = #k)
    & (All SUPI1 SUPI2 #j #k. In_Attach_SUPI(SUPI1)@j &
            In_Attach_SUPI(SUPI2)@k ==> #j = #k)
            "

ifdef(<!enable_non_frameability!>,<!dnl
lemma trace_exists_setup:
  exists-trace
  " Ex SUPI ARPF NF #j. UE_recv_setup_res(SUPI, ARPF, NF)@j
    & not (Ex X #r. Rev(X)@r)
    & (All ARPF1 ARPF2 #j #k. ARPF_HomeNet(ARPF1)@j &
            ARPF_HomeNet(ARPF2)@k ==> #j = #k)
    & (All S1 S2 ARPF1 ARPF2 #j #k. Subscribe(S1, ARPF1)@j &
            Subscribe(S2, ARPF2)@k ==> #j = #k)
    & (All SQN1 c1 SQN2 c2 #j #k. Sqn_ARPF_Use(SQN1, c1)@j &
              Sqn_ARPF_Use(SQN2, c2)@k ==> #j = #k)
    & (All AUSF AUSF2 #j #k. StartAUSFSession(AUSF)@j &
              StartAUSFSession(AUSF2)@k ==> #j = #k)
    & (All AUSF AUSF2 #j #k. AUSF_ID(AUSF)@j &
              AUSF_ID(AUSF2)@k ==> #j = #k)
    & (All SNID1 SNID2 #j #k. StartSeafSession(SNID1)@j &
              StartSeafSession(SNID2)@k ==> #j = #k)
    & (All ARPF1 ARPF2 #j #k. StartARPFSession(ARPF1)@j &
            StartARPFSession(ARPF2)@k ==> #j = #k)
    & (All gNB1 gNB2 #j #k. GNB_init(gNB1)@j &
            GNB_init(gNB2)@k ==> #j = #k)
    & (All SUPI1 SUPI2 #j #k. In_Attach_SUPI(SUPI1)@j &
            In_Attach_SUPI(SUPI2)@k ==> #j = #k)
          "
!>,<! !>)dnl

lemma trace_exists_seaf_end:
exists-trace
"Ex #j. SEAF_END()@j
  & not (Ex X #r. Rev(X)@r)
  & (All ARPF1 ARPF2 #j #k. ARPF_HomeNet(ARPF1)@j &
          ARPF_HomeNet(ARPF2)@k ==> #j = #k)
  & (All S1 S2 ARPF1 ARPF2 #j #k. Subscribe(S1, ARPF1)@j &
          Subscribe(S2, ARPF2)@k ==> #j = #k)
  & (All SQN1 c1 SQN2 c2 #j #k. Sqn_ARPF_Use(SQN1, c1)@j &
            Sqn_ARPF_Use(SQN2, c2)@k ==> #j = #k)
  & (All AUSF AUSF2 #j #k. StartAUSFSession(AUSF)@j &
            StartAUSFSession(AUSF2)@k ==> #j = #k)
  & (All AUSF AUSF2 #j #k. AUSF_ID(AUSF)@j &
            AUSF_ID(AUSF2)@k ==> #j = #k)
  & (All SNID1 SNID2 #j #k. StartSeafSession(SNID1)@j &
            StartSeafSession(SNID2)@k ==> #j = #k)
  & (All ARPF1 ARPF2 #j #k. StartARPFSession(ARPF1)@j &
          StartARPFSession(ARPF2)@k ==> #j = #k)
  & (All gNB1 gNB2 #j #k. GNB_init(gNB1)@j &
          GNB_init(gNB2)@k ==> #j = #k)
  & (All SUPI1 SUPI2 #j #k. In_Attach_SUPI(SUPI1)@j &
          In_Attach_SUPI(SUPI2)@k ==> #j = #k)
"

lemma trace_exists_SEAF_send_authReq:
exists-trace
"Ex #j. SEAF_send_authReq()@j
& not (Ex X #r. Rev(X)@r)
& (All ARPF1 ARPF2 #j #k. ARPF_HomeNet(ARPF1)@j &
        ARPF_HomeNet(ARPF2)@k ==> #j = #k)
& (All S1 S2 ARPF1 ARPF2 #j #k. Subscribe(S1, ARPF1)@j &
        Subscribe(S2, ARPF2)@k ==> #j = #k)
& (All SQN1 c1 SQN2 c2 #j #k. Sqn_ARPF_Use(SQN1, c1)@j &
          Sqn_ARPF_Use(SQN2, c2)@k ==> #j = #k)
& (All AUSF AUSF2 #j #k. StartAUSFSession(AUSF)@j &
          StartAUSFSession(AUSF2)@k ==> #j = #k)
& (All AUSF AUSF2 #j #k. AUSF_ID(AUSF)@j &
          AUSF_ID(AUSF2)@k ==> #j = #k)
& (All SNID1 SNID2 #j #k. StartSeafSession(SNID1)@j &
          StartSeafSession(SNID2)@k ==> #j = #k)
& (All ARPF1 ARPF2 #j #k. StartARPFSession(ARPF1)@j &
        StartARPFSession(ARPF2)@k ==> #j = #k)
& (All gNB1 gNB2 #j #k. GNB_init(gNB1)@j &
        GNB_init(gNB2)@k ==> #j = #k)
& (All SUPI1 SUPI2 #j #k. In_Attach_SUPI(SUPI1)@j &
        In_Attach_SUPI(SUPI2)@k ==> #j = #k)
"

lemma trace_UE_receive_authReq:
exists-trace
"Ex #j. UE_receive_authReq()@j
& not (Ex X #r. Rev(X)@r)
& (All ARPF1 ARPF2 #j #k. ARPF_HomeNet(ARPF1)@j &
        ARPF_HomeNet(ARPF2)@k ==> #j = #k)
& (All S1 S2 ARPF1 ARPF2 #j #k. Subscribe(S1, ARPF1)@j &
        Subscribe(S2, ARPF2)@k ==> #j = #k)
& (All SQN1 c1 SQN2 c2 #j #k. Sqn_ARPF_Use(SQN1, c1)@j &
          Sqn_ARPF_Use(SQN2, c2)@k ==> #j = #k)
& (All AUSF AUSF2 #j #k. StartAUSFSession(AUSF)@j &
          StartAUSFSession(AUSF2)@k ==> #j = #k)
& (All AUSF AUSF2 #j #k. AUSF_ID(AUSF)@j &
          AUSF_ID(AUSF2)@k ==> #j = #k)
& (All SNID1 SNID2 #j #k. StartSeafSession(SNID1)@j &
          StartSeafSession(SNID2)@k ==> #j = #k)
& (All ARPF1 ARPF2 #j #k. StartARPFSession(ARPF1)@j &
        StartARPFSession(ARPF2)@k ==> #j = #k)
& (All gNB1 gNB2 #j #k. GNB_init(gNB1)@j &
        GNB_init(gNB2)@k ==> #j = #k)
& (All SUPI1 SUPI2 #j #k. In_Attach_SUPI(SUPI1)@j &
        In_Attach_SUPI(SUPI2)@k ==> #j = #k)
& (All #j #k. UE_send_attach()@j &
        UE_send_attach()@k ==> #j = #k)
"

lemma trace_GNB_receive_authReq:
exists-trace
"Ex #j. GNB_receive_authReq()@j
& not (Ex X #r. Rev(X)@r)
"


lemma trace_exists_SEAF_receive_aia:
exists-trace
"Ex #j. SEAF_receive_aia()@j
& not (Ex X #r. Rev(X)@r)
& (All ARPF1 ARPF2 #j #k. ARPF_HomeNet(ARPF1)@j &
        ARPF_HomeNet(ARPF2)@k ==> #j = #k)
& (All S1 S2 ARPF1 ARPF2 #j #k. Subscribe(S1, ARPF1)@j &
        Subscribe(S2, ARPF2)@k ==> #j = #k)
& (All SQN1 c1 SQN2 c2 #j #k. Sqn_ARPF_Use(SQN1, c1)@j &
          Sqn_ARPF_Use(SQN2, c2)@k ==> #j = #k)
& (All AUSF AUSF2 #j #k. StartAUSFSession(AUSF)@j &
          StartAUSFSession(AUSF2)@k ==> #j = #k)
& (All AUSF AUSF2 #j #k. AUSF_ID(AUSF)@j &
          AUSF_ID(AUSF2)@k ==> #j = #k)
& (All SNID1 SNID2 #j #k. StartSeafSession(SNID1)@j &
          StartSeafSession(SNID2)@k ==> #j = #k)
& (All ARPF1 ARPF2 #j #k. StartARPFSession(ARPF1)@j &
        StartARPFSession(ARPF2)@k ==> #j = #k)
& (All gNB1 gNB2 #j #k. GNB_init(gNB1)@j &
        GNB_init(gNB2)@k ==> #j = #k)
& (All SUPI1 SUPI2 #j #k. In_Attach_SUPI(SUPI1)@j &
        In_Attach_SUPI(SUPI2)@k ==> #j = #k)
"
lemma trace_exists_SEAF_receive_attachReq:
exists-trace
"Ex #j. SEAF_receive_attachReq()@j
& not (Ex X #r. Rev(X)@r)
& (All ARPF1 ARPF2 #j #k. ARPF_HomeNet(ARPF1)@j &
        ARPF_HomeNet(ARPF2)@k ==> #j = #k)
& (All S1 S2 ARPF1 ARPF2 #j #k. Subscribe(S1, ARPF1)@j &
        Subscribe(S2, ARPF2)@k ==> #j = #k)
& (All SQN1 c1 SQN2 c2 #j #k. Sqn_ARPF_Use(SQN1, c1)@j &
          Sqn_ARPF_Use(SQN2, c2)@k ==> #j = #k)
& (All AUSF AUSF2 #j #k. StartAUSFSession(AUSF)@j &
          StartAUSFSession(AUSF2)@k ==> #j = #k)
& (All AUSF AUSF2 #j #k. AUSF_ID(AUSF)@j &
          AUSF_ID(AUSF2)@k ==> #j = #k)
& (All SNID1 SNID2 #j #k. StartSeafSession(SNID1)@j &
          StartSeafSession(SNID2)@k ==> #j = #k)
& (All ARPF1 ARPF2 #j #k. StartARPFSession(ARPF1)@j &
        StartARPFSession(ARPF2)@k ==> #j = #k)
& (All gNB1 gNB2 #j #k. GNB_init(gNB1)@j &
        GNB_init(gNB2)@k ==> #j = #k)
& (All SUPI1 SUPI2 #j #k. In_Attach_SUPI(SUPI1)@j &
        In_Attach_SUPI(SUPI2)@k ==> #j = #k)
"

lemma trace_exists_GNB_receive_attachReq:
exists-trace
"Ex #j. GNB_receive_attachReq()@j
& not (Ex X #r. Rev(X)@r)
& (All ARPF1 ARPF2 #j #k. ARPF_HomeNet(ARPF1)@j &
        ARPF_HomeNet(ARPF2)@k ==> #j = #k)
& (All S1 S2 ARPF1 ARPF2 #j #k. Subscribe(S1, ARPF1)@j &
        Subscribe(S2, ARPF2)@k ==> #j = #k)
& (All SQN1 c1 SQN2 c2 #j #k. Sqn_ARPF_Use(SQN1, c1)@j &
          Sqn_ARPF_Use(SQN2, c2)@k ==> #j = #k)
& (All AUSF AUSF2 #j #k. StartAUSFSession(AUSF)@j &
          StartAUSFSession(AUSF2)@k ==> #j = #k)
& (All AUSF AUSF2 #j #k. AUSF_ID(AUSF)@j &
          AUSF_ID(AUSF2)@k ==> #j = #k)
& (All SNID1 SNID2 #j #k. StartSeafSession(SNID1)@j &
          StartSeafSession(SNID2)@k ==> #j = #k)
& (All ARPF1 ARPF2 #j #k. StartARPFSession(ARPF1)@j &
        StartARPFSession(ARPF2)@k ==> #j = #k)
& (All gNB1 gNB2 #j #k. GNB_init(gNB1)@j &
        GNB_init(gNB2)@k ==> #j = #k)
& (All SUPI1 SUPI2 #j #k. In_Attach_SUPI(SUPI1)@j &
        In_Attach_SUPI(SUPI2)@k ==> #j = #k)
"

ifdef(<!enable_non_frameability!>,<!dnl
lemma trace_exists_UPF_recv_data:
  exists-trace
  "Ex #j. UPF_recv_data()@j
  & not (Ex X #r. Rev(X)@r)
  & (All ARPF1 ARPF2 #j #k. ARPF_HomeNet(ARPF1)@j &
          ARPF_HomeNet(ARPF2)@k ==> #j = #k)
  & (All S1 S2 ARPF1 ARPF2 #j #k. Subscribe(S1, ARPF1)@j &
          Subscribe(S2, ARPF2)@k ==> #j = #k)
  & (All SQN1 c1 SQN2 c2 #j #k. Sqn_ARPF_Use(SQN1, c1)@j &
            Sqn_ARPF_Use(SQN2, c2)@k ==> #j = #k)
  & (All AUSF AUSF2 #j #k. StartAUSFSession(AUSF)@j &
            StartAUSFSession(AUSF2)@k ==> #j = #k)
  & (All AUSF AUSF2 #j #k. AUSF_ID(AUSF)@j &
            AUSF_ID(AUSF2)@k ==> #j = #k)
  & (All SNID1 SNID2 #j #k. StartSeafSession(SNID1)@j &
            StartSeafSession(SNID2)@k ==> #j = #k)
  & (All ARPF1 ARPF2 #j #k. StartARPFSession(ARPF1)@j &
          StartARPFSession(ARPF2)@k ==> #j = #k)
  & (All gNB1 gNB2 #j #k. GNB_init(gNB1)@j &
          GNB_init(gNB2)@k ==> #j = #k)
  & (All SUPI1 SUPI2 #j #k. In_Attach_SUPI(SUPI1)@j &
          In_Attach_SUPI(SUPI2)@k ==> #j = #k)
  & (All #j #k. GNB_receive_attachReq()@j &
          GNB_receive_attachReq()@k ==> #j = #k)
  "

// Rev(<'NF', ~SUPI, ~NF>)
// Rev(<'HN',$ARPF, ~HN>)
// Rev(<SUPI, ARPF>

//& not(Ex NF SUPI2 #r. Rev(<'NF', SUPI2, NF>)@r)
//& not(Ex HN SUPI2 #r. Rev(<'HN', SUPI2, HN>)@r)
//& not(Ex ARPF #r. Rev(<SUPI, ARPF>)@r)

//     CTX_NF = <~SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, $t, $gNB>
//     <SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, t, gNB>

lemma LI_intercept_noRevs:
"All SUPI beta_SUPI RES_star k_ECIES sig_NF t gNB APP #li #seaf. POI_UPF(<SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, t, gNB>, APP)@li
                  & POI_CTX_SEAF(<SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, t, gNB>)@seaf
                  & not(Ex R #rev. Rev(R)@rev)
                  ==>
                  (
                      (Ex #send. UserSend(SUPI, APP)@send & send<li)
                  )
"

lemma LI_intercept_RevK:
"All SUPI beta_SUPI RES_star k_ECIES sig_NF t gNB APP ARPF NF #li #seaf #setup. POI_UPF(<SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, t, gNB>, APP)@li
                  & POI_CTX_SEAF(<SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, t, gNB>)@seaf
                  & UE_recv_setup_res(SUPI, ARPF, NF)@setup
                  & not(Ex ANY_NF ANY_SUPI #rev. Rev(<'NF', ANY_SUPI, ANY_NF>)@rev)
                  & not(Ex ANY_HN ANY_ARPF #rev. Rev(<'HN', ANY_ARPF, ANY_HN>)@rev)
                  ==>
                  (
                      (Ex #send. UserSend(SUPI, APP)@send & send<li)
                  )
"

lemma LI_intercept_RevK_RevNFstar:
"All SUPI beta_SUPI RES_star k_ECIES sig_NF t gNB APP ARPF NF #li #seaf #setup. POI_UPF(<SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, t, gNB>, APP)@li
                  & POI_CTX_SEAF(<SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, t, gNB>)@seaf
                  & UE_recv_setup_res(SUPI, ARPF, NF)@setup
                  & not(Ex #rev. Rev(<'NF', SUPI, NF>)@rev)
                  & not(Ex ANY_HN ANY_SUPI #rev. Rev(<'HN', ANY_SUPI, ANY_HN>)@rev)
                  ==>
                  (
                      (Ex #send. UserSend(SUPI, APP)@send & send<li)
                  )
"
// helpers: secrecy_NF, secrecy_HN
lemma LI_intercept_RevHN [hide_lemma=secrecy_HN, use_induction]:
"All SUPI beta_SUPI RES_star k_ECIES sig_NF t gNB APP ARPF NF #li #seaf #setup. POI_UPF(<SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, t, gNB>, APP)@li
                  & POI_CTX_SEAF(<SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, t, gNB>)@seaf
                  & UE_recv_setup_res(SUPI, ARPF, NF)@setup
                  & not(Ex ANY_NF ANY_SUPI #rev. Rev(<'NF', ANY_SUPI, ANY_NF>)@rev)
                  & not(Ex ARPF #rev. Rev(<SUPI, ARPF>)@rev)
                  ==>
                  (
                      (Ex #send. UserSend(SUPI, APP)@send & send<li)
                  )
"

lemma LI_intercept_RevK_RevHN [hide_lemma=secrecy_HN, use_induction]:
"All SUPI beta_SUPI RES_star k_ECIES sig_NF t gNB APP ARPF NF #li #seaf #setup. POI_UPF(<SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, t, gNB>, APP)@li
                  & POI_CTX_SEAF(<SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, t, gNB>)@seaf
                  & UE_recv_setup_res(SUPI, ARPF, NF)@setup
                  & not(Ex ANY_NF ANY_SUPI #rev. Rev(<'NF', ANY_SUPI, ANY_NF>)@rev)
                  ==>
                  (
                      (Ex #send. UserSend(SUPI, APP)@send & send<li)
                  )
"

lemma LI_intercept_RevK_RevHN_after_Setup [hide_lemma=secrecy_HN, use_induction]:
"All SUPI beta_SUPI RES_star k_ECIES sig_NF t gNB APP ARPF NF #li #seaf #setup. POI_UPF(<SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, t, gNB>, APP)@li
                  & POI_CTX_SEAF(<SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, t, gNB>)@seaf
                  & UE_recv_setup_res(SUPI, ARPF, NF)@setup
                  & not(Ex ANY_NF ANY_SUPI #rev. Rev(<'NF', ANY_SUPI, ANY_NF>)@rev)
                  & not(Ex ANY_HN ANY_SUPI #rev. Rev(<'HN', ANY_SUPI, ANY_HN>)@rev & rev<setup)
                  ==>
                  (
                      (Ex #send. UserSend(SUPI, APP)@send & send<li)
                  )
"

lemma LI_intercept_RevHN_dispute [hide_lemma=secrecy_HN]:
"All SUPI beta_SUPI RES_star k_ECIES sig_NF t gNB APP ARPF NF #li #seaf #setup. POI_UPF(<SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, t, gNB>, APP)@li
                  & POI_CTX_SEAF(<SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, t, gNB>)@seaf
                  & UE_recv_setup_res(SUPI, ARPF, NF)@setup
                  & not(Ex ANY_NF ANY_SUPI #rev. Rev(<'NF', ANY_SUPI, ANY_NF>)@rev)
                  & not(Ex ARPF #rev. Rev(<SUPI, ARPF>)@rev)
                  ==>
                  (
                        (Ex #send. UserSend(SUPI, APP)@send & send<li)
                      | (Ex beta_SUPI_d #dispute. Dispute(SUPI, beta_SUPI_d)@dispute & not(beta_SUPI_d = beta_SUPI))
                  )
"

lemma LI_intercept_RevK_RevHN_dispute [hide_lemma=secrecy_HN]:
"All SUPI beta_SUPI RES_star k_ECIES sig_NF t gNB APP ARPF NF #li #seaf #setup. POI_UPF(<SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, t, gNB>, APP)@li
                  & POI_CTX_SEAF(<SUPI, beta_SUPI, RES_star, k_ECIES, sig_NF, t, gNB>)@seaf
                  & UE_recv_setup_res(SUPI, ARPF, NF)@setup
                  & not(Ex ANY_NF ANY_SUPI #rev. Rev(<'NF', ANY_SUPI, ANY_NF>)@rev)
                  ==>
                  (
                        (Ex #send. UserSend(SUPI, APP)@send & send<li)
                      | (Ex beta_SUPI_d #dispute. Dispute(SUPI, beta_SUPI_d)@dispute & not(beta_SUPI_d = beta_SUPI))
                  )
"

!>,<! !>)dnl


/** Secrecy lemmas **/

// Secrecy of long-term key Ki
lemma secrecy_Ki:
	" All supi ki #i. LongTermKey(supi,ki) @i & not(Ex #r. RevealKforSUPI(supi)@r)
		==> not (Ex #j. K(ki)@j)"

lemma secrecy_K_AUSF:
	" All a b c d t #i . Secret1(<a,b,c,d>,<'K_AUSF', d>, t) @i
  & not(Ex R #rev. Rev(R)@rev)
  		==> not (Ex #j. K(t)@j)"

lemma secrecy_K_AUSF_restricted:
	" All a b c d t #i . (Secret1(<a,b,c,d>,<'K_AUSF', d>, t) @i
  & not(Ex R #rev. Rev(R)@rev)
	& (All x y ARPF SUPI #i #j. Subscribe(x, y)@i & Subscribe(SUPI, ARPF)@j ==> #i = #j) &
	(All AUSF #i #j. AUSF_ID(AUSF)@i & AUSF_ID(AUSF)@j ==> #i = #j) &
	(All #i #j. SERV_NET()@i & SERV_NET()@j ==> #i = #j) &
	(All #i #j. ARPF_1()@i & ARPF_1()@j ==> #i = #j) &
	(All SNID SUPI #i #j. SEAF_SUPI(SNID, SUPI)@i & SEAF_SUPI(SNID, SUPI)@j ==> #i = #j) &
	(All ARPF1 ARPF2 #j #k. ARPF_HomeNet(ARPF1)@j & ARPF_HomeNet(ARPF2)@k ==> #j = #k) &
  (All gNB1 gNB2 #j #k. GNB_init(gNB1)@j & GNB_init(gNB2)@k ==> #j = #k) &
  (All SUPI1 SUPI2 #j #k. In_Attach_SUPI(SUPI1)@j & In_Attach_SUPI(SUPI2)@k ==> #j = #k)
		)
  		==> not (Ex #j. K(t)@j)"

lemma secrecy_K_SEAF:
	" All a b c d t #i . Secret1(<a,b,c,d>,<'K_SEAF', b>, t) @i
  & not(Ex R #rev. Rev(R)@rev)
  & not(Ex h1 h2 #r. Rev(<'HN', h1, h2>)@r)
		==> not (Ex #j. K(t)@j)"

lemma secrecy_K_SEAF_restricted:
	" All a b c d t #i . (Secret1(<a,b,c,d>,<'K_SEAF', b>, t) @i
  & not(Ex R #rev. Rev(R)@rev)
	& (All x y ARPF SUPI #i #j. Subscribe(x, y)@i & Subscribe(SUPI, ARPF)@j ==> #i = #j) &
	(All AUSF #i #j. AUSF_ID(AUSF)@i & AUSF_ID(AUSF)@j ==> #i = #j) &
	(All #i #j. SERV_NET()@i & SERV_NET()@j ==> #i = #j) &
	(All #i #j. ARPF_1()@i & ARPF_1()@j ==> #i = #j) &
	(All SNID SUPI #i #j. SEAF_SUPI(SNID, SUPI)@i & SEAF_SUPI(SNID, SUPI)@j ==> #i = #j) &
	(All ARPF1 ARPF2 #j #k. ARPF_HomeNet(ARPF1)@j & ARPF_HomeNet(ARPF2)@k ==> #j = #k) &
  (All gNB1 gNB2 #j #k. GNB_init(gNB1)@j & GNB_init(gNB2)@k ==> #j = #k) &
  (All SUPI1 SUPI2 #j #k. In_Attach_SUPI(SUPI1)@j & In_Attach_SUPI(SUPI2)@k ==> #j = #k)
		)
		==> not (Ex #j. K(t)@j)"

lemma secrecy_K_AMF:
	" All a b c d t #i . Secret1(<a,b,c,d>,<'K_AMF', b>, t) @i
    & not(Ex R #rev. Rev(R)@rev)
		==> not (Ex #j. K(t)@j)"

lemma secrecy_K_AMF_restricted:
	" All a b c d t #i . (Secret1(<a,b,c,d>,<'K_AMF', b>, t) @i
  & not(Ex R #rev. Rev(R)@rev)
  & (All x y ARPF SUPI #i #j. Subscribe(x, y)@i & Subscribe(SUPI, ARPF)@j ==> #i = #j) &
	(All AUSF #i #j. AUSF_ID(AUSF)@i & AUSF_ID(AUSF)@j ==> #i = #j) &
	(All #i #j. SERV_NET()@i & SERV_NET()@j ==> #i = #j) &
	(All #i #j. ARPF_1()@i & ARPF_1()@j ==> #i = #j) &
	(All SNID SUPI #i #j. SEAF_SUPI(SNID, SUPI)@i & SEAF_SUPI(SNID, SUPI)@j ==> #i = #j) &
	(All ARPF1 ARPF2 #j #k. ARPF_HomeNet(ARPF1)@j & ARPF_HomeNet(ARPF2)@k ==> #j = #k) &
  (All gNB1 gNB2 #j #k. GNB_init(gNB1)@j & GNB_init(gNB2)@k ==> #j = #k) &
  (All SUPI1 SUPI2 #j #k. In_Attach_SUPI(SUPI1)@j & In_Attach_SUPI(SUPI2)@k ==> #j = #k)
		)
		==> not (Ex #j. K(t)@j)"

lemma secrecy_KgNB:
	" All a b c d t #i . Secret1(<a,b,c,d>,<'KGNB', d>, t) @i
    & not(Ex R #rev. Rev(R)@rev)
		==> not (Ex #j. K(t)@j)"

lemma secrecy_KgNB_restricted:
	" All a b c d t #i . (Secret1(<a,b,c,d>,<'KGNB', d>, t) @i
  & not(Ex R #rev. Rev(R)@rev)
  & (All x y ARPF SUPI #i #j. Subscribe(x, y)@i & Subscribe(SUPI, ARPF)@j ==> #i = #j) &
  (All AUSF #i #j. AUSF_ID(AUSF)@i & AUSF_ID(AUSF)@j ==> #i = #j) &
  (All #i #j. SERV_NET()@i & SERV_NET()@j ==> #i = #j) &
  (All #i #j. ARPF_1()@i & ARPF_1()@j ==> #i = #j) &
  (All SNID SUPI #i #j. SEAF_SUPI(SNID, SUPI)@i & SEAF_SUPI(SNID, SUPI)@j ==> #i = #j) &
  (All ARPF1 ARPF2 #j #k. ARPF_HomeNet(ARPF1)@j & ARPF_HomeNet(ARPF2)@k ==> #j = #k) &
  (All gNB1 gNB2 #j #k. GNB_init(gNB1)@j & GNB_init(gNB2)@k ==> #j = #k) &
  (All SUPI1 SUPI2 #j #k. In_Attach_SUPI(SUPI1)@j & In_Attach_SUPI(SUPI2)@k ==> #j = #k)
    )
    ==> not (Ex #j. K(t)@j)"


end
