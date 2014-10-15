(* Title: Stream_Fusion_LList
  Author: Andreas Lochbihler, ETH Zurich *)

header {* Stream fusion for coinductive lists *}

theory Stream_Fusion_LList imports
  Stream_Fusion_List
  "../Coinductive/Coinductive_List"
begin

text {*
  There are two choices of how many @{const Skip}s may occur consecutively.
  \begin{itemize}
  \item A generator for @{typ "'a llist"} may return only finitely many @{const Skip}s before
    it has to decide on a @{const Done} or @{const Yield}. Then, we can define stream versions
    for all functions that can be defined by corecursion up-to. This in particular excludes
    @{const lfilter}. Moreover, we have to prove that every generator satisfies this
    restriction.
  \item A generator for @{typ "'a llist"} may return infinitely many @{const Skip}s in a row.
    Then, the @{text lunstream} function suffers from the same difficulties as @{const lfilter} with
    definitions, but we can define it using the least fixpoint approach described in
    \cite{LochbihlerHoelzl2014ITP}. Consequently, we can only fuse transformers that are monotone and
    continuous with respect to the ccpo ordering. This in particular excludes @{const lappend}.
  \end{itemize}
  Here, we take the both approaches where we consider the first preferable to the second.
  Consequently, we define producers such that they produce generators of the first kind, if possible.
  There will be multiple equations for transformers and consumers that deal with all the different
  combinations for their parameter generators. Transformers should yield generators of the first
  kind whenever possible. Consumers can be defined using @{text lunstream} and refined with custom
  code equations, i.e., they can operate with infinitely many @{text Skip}s in a row. We just
  have to lift the fusion equation to the first kind, too.
*}

(* To be moved to Complete_Partial_Order2 *)

lemma monotone_if_fun [partial_function_mono]:
  "\<lbrakk> monotone (fun_ord orda) (fun_ord ordb) F; monotone (fun_ord orda) (fun_ord ordb) G \<rbrakk>
  \<Longrightarrow> monotone (fun_ord orda) (fun_ord ordb) (\<lambda>f n. if c n then F f n else G f n)"
by(simp add: monotone_def fun_ord_def)

lemma monotone_fun_apply_fun [partial_function_mono]: 
  "monotone (fun_ord (fun_ord ord)) (fun_ord ord) (\<lambda>f n. f t (g n))"
by(rule monotoneI)(simp add: fun_ord_def)

lemma monotone_fun_ord_apply: 
  "monotone orda (fun_ord ordb) f \<longleftrightarrow> (\<forall>x. monotone orda ordb (\<lambda>y. f y x))"
by(auto simp add: monotone_def fun_ord_def)

lemma cont_fun_lub_apply: 
  "cont luba orda (fun_lub lubb) (fun_ord ordb) f \<longleftrightarrow> (\<forall>x. cont luba orda lubb ordb (\<lambda>y. f y x))"
by(simp add: cont_def fun_lub_def fun_eq_iff)(auto simp add: image_def)

lemma mcont_fun_lub_apply: 
  "mcont luba orda (fun_lub lubb) (fun_ord ordb) f \<longleftrightarrow> (\<forall>x. mcont luba orda lubb ordb (\<lambda>y. f y x))"
by(auto simp add: monotone_fun_ord_apply cont_fun_lub_apply mcont_def)

(* To be moved to Coinductive_List *)

interpretation llist_lift!: partial_function_definitions "fun_ord lprefix" "fun_lub lSup"
  where "fun_lub lSup {} \<equiv> \<lambda>_. LNil"
by(rule llist_partial_function_definitions[THEN partial_function_lift])(simp)

abbreviation "mono_llist_lift \<equiv> monotone (fun_ord (fun_ord lprefix)) (fun_ord lprefix)"

lemma fixes f F
  defines "F \<equiv> \<lambda>ldropn xs. case xs of LNil \<Rightarrow> \<lambda>_. LNil | LCons x xs \<Rightarrow> \<lambda>n. if n = 0 then LCons x xs else ldropn xs (n - 1)"
  shows ldrop_conv_fixp: "(\<lambda>xs n. ldropn n xs) \<equiv> ccpo.fixp (fun_lub (fun_lub lSup)) (fun_ord (fun_ord lprefix)) (\<lambda>ldrop. F ldrop)" (is "?lhs \<equiv> ?rhs")
  and ldrop_mono: "\<And>xs. mono_llist_lift (\<lambda>ldrop. F ldrop xs)" (is "PROP ?mono")
proof(intro eq_reflection ext)
  show mono: "PROP ?mono" unfolding F_def by(tactic {* Partial_Function.mono_tac @{context} 1 *})
  fix n xs
  show "?lhs xs n = ?rhs xs n"
    by(induction n arbitrary: xs)
      (subst llist_lift.mono_body_fixp[OF mono], simp add: F_def split: llist.split)+
qed

lemma ldropn_fixp_case_conv: 
  "(\<lambda>xs. case xs of LNil \<Rightarrow> \<lambda>_. LNil | LCons x xs \<Rightarrow> \<lambda>n. if n = 0 then LCons x xs else f xs (n - 1)) =
   (\<lambda>xs n. case xs of LNil \<Rightarrow> LNil | LCons x xs \<Rightarrow> if n = 0 then LCons x xs else f xs (n - 1))"
by(auto simp add: fun_eq_iff split: llist.split)

lemma monotone_ldropn_aux: "monotone lprefix (fun_ord lprefix) (\<lambda>xs n. ldropn n xs)"
by(rule llist_lift.fixp_preserves_mono1[OF ldrop_mono ldrop_conv_fixp])
  (simp add: ldropn_fixp_case_conv monotone_fun_ord_apply)

lemma mono2mono_ldropn[THEN llist.mono2mono, cont_intro, simp]:
  shows monotone_ldropn': "monotone lprefix lprefix (\<lambda>xs. ldropn n xs)"
using monotone_ldropn_aux by(auto simp add: monotone_def fun_ord_def)

lemma mcont_ldropn_aux: "mcont lSup lprefix (fun_lub lSup) (fun_ord lprefix) (\<lambda>xs n. ldropn n xs)"
by(rule llist_lift.fixp_preserves_mcont1[OF ldrop_mono ldrop_conv_fixp])
  (simp add: ldropn_fixp_case_conv mcont_fun_lub_apply)

lemma mcont2mcont_ldropn [THEN llist.mcont2mcont, cont_intro, simp]:
  shows mcont_ldropn: "mcont lSup lprefix lSup lprefix (ldropn n)"
using mcont_ldropn_aux by(auto simp add: mcont_fun_lub_apply)


lemma fixes f F P
  defines "F \<equiv> \<lambda>ltakeWhile xs. case xs of LNil \<Rightarrow> LNil | LCons x xs \<Rightarrow> if P x then LCons x (ltakeWhile xs) else LNil"
  shows ltakeWhile_conv_fixp: "ltakeWhile P \<equiv> ccpo.fixp (fun_lub lSup) (fun_ord lprefix) F" (is "?lhs \<equiv> ?rhs")
  and ltakeWhile_mono: "\<And>xs. mono_llist (\<lambda>ltakeWhile. F ltakeWhile xs)" (is "PROP ?mono")
proof(intro eq_reflection ext)
  show mono: "PROP ?mono" unfolding F_def by(tactic {* Partial_Function.mono_tac @{context} 1 *})
  fix xs
  show "?lhs xs = ?rhs xs"
  proof(coinduction arbitrary: xs)
    case Eq_llist
    show ?case by(subst (1 3 4) llist.mono_body_fixp[OF mono])(auto simp add: F_def split: llist.split prod.split co.enat.split)
  qed
qed

lemma mono2mono_ltakeWhile[THEN llist.mono2mono, cont_intro, simp]:
  shows monotone_ltakeWhile: "monotone lprefix lprefix (ltakeWhile P)"
by(rule llist.fixp_preserves_mono1[OF ltakeWhile_mono ltakeWhile_conv_fixp]) simp

lemma mcont2mcont_ltakeWhile [THEN llist.mcont2mcont, cont_intro, simp]:
  shows mcont_ltakeWhile: "mcont lSup lprefix lSup lprefix (ltakeWhile P)"
by(rule llist.fixp_preserves_mcont1[OF ltakeWhile_mono ltakeWhile_conv_fixp]) simp

lemma [partial_function_mono]: "mono_llist F \<Longrightarrow> mono_llist (\<lambda>f. ltakeWhile P (F f))"
by(rule mono2mono_ltakeWhile)

(* Move end *)

type_synonym ('a, 's) lgenerator = "'s \<Rightarrow> ('a, 's) step"

inductive_set productive_on :: "('a, 's) lgenerator \<Rightarrow> 's set"
for g :: "('a, 's) lgenerator"
where
  Done: "g s = Done \<Longrightarrow> s \<in> productive_on g"
| Skip: "\<lbrakk> g s = Skip s'; s' \<in> productive_on g \<rbrakk> \<Longrightarrow> s \<in> productive_on g"
| Yield: "g s = Yield x s' \<Longrightarrow> s \<in> productive_on g"

definition productive :: "('a, 's) lgenerator \<Rightarrow> bool"
where "productive g \<longleftrightarrow> productive_on g = UNIV"

lemma productiveI [intro?]:
  "(\<And>s. s \<in> productive_on g) \<Longrightarrow> productive g"
by(auto simp add: productive_def)

lemma productive_onI [dest?]: "productive g \<Longrightarrow> s \<in> productive_on g"
by(simp add: productive_def)

text {* A type of generators that eventually will yield something else than a skip. *}

typedef ('a, 's) lgenerator' = "{g :: ('a, 's) lgenerator. productive g}"
  morphisms lgenerator Abs_lgenerator'
proof
  show "(\<lambda>_. Done) \<in> ?lgenerator'" by(auto intro: productive_on.intros productiveI)
qed

setup_lifting type_definition_lgenerator'

section {* Conversions to @{typ "'a llist"} *}

subsection {* Infinitely many consecutive @{term Skip}s *}

context fixes g :: "('a, 's) lgenerator" begin

partial_function (llist) lunstream :: "'s \<Rightarrow> 'a llist"
where
  "lunstream s = (case g s of 
     Done \<Rightarrow> LNil | Skip s' \<Rightarrow> lunstream s' | Yield x s' \<Rightarrow> LCons x (lunstream s'))"

declare lunstream.simps[code]

lemma lunstream_simps:
  "g s = Done \<Longrightarrow> lunstream s = LNil"
  "g s = Skip s' \<Longrightarrow> lunstream s = lunstream s'"
  "g s = Yield x s' \<Longrightarrow> lunstream s = LCons x (lunstream s')"
by(simp_all add: lunstream.simps)

lemma lunstream_sels:
  shows lnull_lunstream: "lnull (lunstream s) \<longleftrightarrow> 
  (case g s of Done \<Rightarrow> True | Skip s' \<Rightarrow> lnull (lunstream s') | Yield _ _ \<Rightarrow> False)"
  and lhd_lunstream: "lhd (lunstream s) =
  (case g s of Skip s' \<Rightarrow> lhd (lunstream s') | Yield x _ \<Rightarrow> x)"
  and ltl_lunstream: "ltl (lunstream s) =
  (case g s of Done \<Rightarrow> LNil | Skip s' \<Rightarrow> ltl (lunstream s') | Yield _ s' \<Rightarrow> lunstream s')"
by(simp_all add: lhd_def lunstream_simps split: step.split)

end

subsection {* Finitely many consecutive @{term Skip}s *}

lift_definition lunstream' :: "('a, 's) lgenerator' \<Rightarrow> 's \<Rightarrow> 'a llist"
is lunstream .

lemma lunstream'_simps:
  "lgenerator g s = Done \<Longrightarrow> lunstream' g s = LNil"
  "lgenerator g s = Skip s' \<Longrightarrow> lunstream' g s = lunstream' g s'"
  "lgenerator g s = Yield x s' \<Longrightarrow> lunstream' g s = LCons x (lunstream' g s')"
by(transfer, simp add: lunstream_simps)+

lemma lunstream'_sels:
  shows lnull_lunstream': "lnull (lunstream' g s) \<longleftrightarrow> 
  (case lgenerator g s of Done \<Rightarrow> True | Skip s' \<Rightarrow> lnull (lunstream' g s') | Yield _ _ \<Rightarrow> False)"
  and lhd_lunstream': "lhd (lunstream' g s) =
  (case lgenerator g s of Skip s' \<Rightarrow> lhd (lunstream' g s') | Yield x _ \<Rightarrow> x)"
  and ltl_lunstream': "ltl (lunstream' g s) =
  (case lgenerator g s of Done \<Rightarrow> LNil | Skip s' \<Rightarrow> ltl (lunstream' g s') | Yield _ s' \<Rightarrow> lunstream' g s')"
by(transfer, simp add: lunstream_sels)+

setup {* Context.theory_map (fold
  Stream_Fusion.add_unstream [@{const_name lunstream}, @{const_name lunstream'}]) *}

section {* Producers *}

subsection {* Conversion to streams *}

fun lstream :: "('a, 'a llist) lgenerator"
where
  "lstream LNil = Done"
| "lstream (LCons x xs) = Yield x xs"

lemma case_lstream_conv_case_llist:
  "(case lstream xs of Done \<Rightarrow> done | Skip xs' \<Rightarrow> skip xs' | Yield x xs' \<Rightarrow> yield x xs') =
   (case xs of LNil \<Rightarrow> done | LCons x xs' \<Rightarrow> yield x xs')"
by(simp split: llist.split)

lemma mcont2mcont_lunstream[THEN llist.mcont2mcont, simp, cont_intro]:
  shows mcont_lunstream: "mcont lSup lprefix lSup lprefix (lunstream lstream)"
by(rule llist.fixp_preserves_mcont1[OF lunstream.mono lunstream_def])(simp add: case_lstream_conv_case_llist)

lemma lunstream_lstream: "lunstream lstream xs = xs"
by(induction xs)(simp_all add: lunstream_simps)

lift_definition lstream' :: "('a, 'a llist) lgenerator'"
is lstream
proof
  fix s :: "'a llist"
  show "s \<in> productive_on lstream" by(cases s)(auto intro: productive_on.intros)
qed

lemma lunstream'_lstream: "lunstream' lstream' xs = xs"
by(transfer)(rule lunstream_lstream)

subsection {* @{const iterates} *}

definition iterates_raw :: "('a \<Rightarrow> 'a) \<Rightarrow> ('a, 'a) lgenerator"
where "iterates_raw f s = Yield s (f s)"

lemma lunstream_iterates_raw: "lunstream (iterates_raw f) x = iterates f x"
by(coinduction arbitrary: x)(auto simp add: iterates_raw_def lunstream_sels)

lift_definition iterates_prod :: "('a \<Rightarrow> 'a) \<Rightarrow> ('a, 'a) lgenerator'" is iterates_raw
by(auto 4 3 intro: productiveI productive_on.intros simp add: iterates_raw_def)

lemma lunstream'_iterates_prod [stream_fusion]: "lunstream' (iterates_prod f) x = iterates f x"
by transfer(rule lunstream_iterates_raw)

subsection {* @{const unfold_llist} *}

definition unfold_llist_raw :: "('a \<Rightarrow> bool) \<Rightarrow> ('a \<Rightarrow> 'b) \<Rightarrow> ('a \<Rightarrow> 'a) \<Rightarrow> ('b, 'a) lgenerator"
where
  "unfold_llist_raw stop head tail s = (if stop s then Done else Yield (head s) (tail s))"

lemma lunstream_unfold_llist_raw:
  "lunstream (unfold_llist_raw stop head tail) s = unfold_llist stop head tail s"
by(coinduction arbitrary: s)(auto simp add: lunstream_sels unfold_llist_raw_def)

lift_definition unfold_llist_prod :: "('a \<Rightarrow> bool) \<Rightarrow> ('a \<Rightarrow> 'b) \<Rightarrow> ('a \<Rightarrow> 'a) \<Rightarrow> ('b, 'a) lgenerator'"
is unfold_llist_raw
proof(rule productiveI)
  fix stop and head :: "'a \<Rightarrow> 'b" and tail s
  show "s \<in> productive_on (unfold_llist_raw stop head tail)"
    by(cases "stop s")(auto intro: productive_on.intros simp add: unfold_llist_raw_def)
qed

lemma lunstream'_unfold_llist_prod [stream_fusion]:
  "lunstream' (unfold_llist_prod stop head tail) s = unfold_llist stop head tail s"
by transfer(rule lunstream_unfold_llist_raw)

subsection {* @{const inf_llist} *}

definition inf_llist_raw :: "(nat \<Rightarrow> 'a) \<Rightarrow> ('a, nat) lgenerator"
where "inf_llist_raw f n = Yield (f n) (Suc n)"

lemma lunstream_inf_llist_raw: "lunstream (inf_llist_raw f) n = ldropn n (inf_llist f)"
by(coinduction arbitrary: n)(auto simp add: lunstream_sels inf_llist_raw_def)

lift_definition inf_llist_prod :: "(nat \<Rightarrow> 'a) \<Rightarrow> ('a, nat) lgenerator'" is inf_llist_raw
by(auto 4 3 intro: productiveI productive_on.intros simp add: inf_llist_raw_def)

lemma inf_llist_prod_fusion [stream_fusion]:
  "lunstream' (inf_llist_prod f) 0 = inf_llist f"
by transfer(simp add: lunstream_inf_llist_raw)

section {* Consumers *}

subsection {* @{const lhd} *}

context fixes g :: "('a, 's) lgenerator" begin

definition lhd_cons :: "'s \<Rightarrow> 'a"
where [stream_fusion]: "lhd_cons s = lhd (lunstream g s)"

lemma lhd_cons_code[code]:
  "lhd_cons s = (case g s of Done \<Rightarrow> undefined | Skip s' \<Rightarrow> lhd_cons s' | Yield x _ \<Rightarrow> x)"
by(simp add: lhd_cons_def lunstream_simps lhd_def split: step.split)

end

lemma lhd_cons_fusion2 [stream_fusion]:
  "lhd_cons (lgenerator g) s = lhd (lunstream' g s)"
by transfer(rule lhd_cons_def)

subsection {* @{const llength} *}

context fixes g :: "('a, 's) lgenerator" begin

definition gen_llength_cons :: "enat \<Rightarrow> 's \<Rightarrow> enat"
where "gen_llength_cons n s = n + llength (lunstream g s)"

lemma gen_llength_cons_code [code]:
  "gen_llength_cons n s = (case g s of
    Done \<Rightarrow> n | Skip s' \<Rightarrow> gen_llength_cons n s' | Yield _ s' \<Rightarrow> gen_llength_cons (eSuc n) s')"
by(simp add: gen_llength_cons_def lunstream_simps iadd_Suc_right iadd_Suc split: step.split)

lemma gen_llength_cons_fusion [stream_fusion]:
  "gen_llength_cons 0 s = llength (lunstream g s)"
by(simp add: gen_llength_cons_def)

end

context fixes g :: "('a, 's) lgenerator'" begin

definition gen_llength_cons' :: "enat \<Rightarrow> 's \<Rightarrow> enat"
where "gen_llength_cons' = gen_llength_cons (lgenerator g)"

lemma gen_llength_cons'_code [code]:
  "gen_llength_cons' n s = (case lgenerator g s of
    Done \<Rightarrow> n | Skip s' \<Rightarrow> gen_llength_cons' n s' | Yield _ s' \<Rightarrow> gen_llength_cons' (eSuc n) s')"
by(simp add: gen_llength_cons'_def cong: step.case_cong)(rule gen_llength_cons_code)

lemma gen_llength_cons'_fusion [stream_fusion]:
  "gen_llength_cons' 0 s = llength (lunstream' g s)"
by(simp add: gen_llength_cons'_def gen_llength_cons_fusion lunstream'.rep_eq)

end

subsection {* @{const lnull} *}

context fixes g :: "('a, 's) lgenerator" begin

definition lnull_cons :: "'s \<Rightarrow> bool"
where [stream_fusion]: "lnull_cons s \<longleftrightarrow> lnull (lunstream g s)"

lemma lnull_cons_code [code]:
  "lnull_cons s \<longleftrightarrow> (case g s of
    Done \<Rightarrow> True | Skip s' \<Rightarrow> lnull_cons s' | Yield _ _ \<Rightarrow> False)"
by(simp add: lnull_cons_def lunstream_simps split: step.split)

end

context fixes g :: "('a, 's) lgenerator'" begin

definition lnull_cons' :: "'s \<Rightarrow> bool"
where "lnull_cons' = lnull_cons (lgenerator g)"

lemma lnull_cons'_code [code]:
  "lnull_cons' s \<longleftrightarrow> (case lgenerator g s of
    Done \<Rightarrow> True | Skip s' \<Rightarrow> lnull_cons' s' | Yield _ _ \<Rightarrow> False)"
by(simp add: lnull_cons'_def cong: step.case_cong)(rule lnull_cons_code)

lemma lnull_cons'_fusion [stream_fusion]:
  "lnull_cons' s \<longleftrightarrow> lnull (lunstream' g s)"
by(simp add: lnull_cons'_def lnull_cons_def lunstream'.rep_eq)

end

subsection {* @{const llist_all2} *}

context
  fixes g :: "('a, 'sg) lgenerator"
  and h :: "('b, 'sh) lgenerator"
  and P :: "'a \<Rightarrow> 'b \<Rightarrow> bool"
begin

definition llist_all2_cons :: "'sg \<Rightarrow> 'sh \<Rightarrow> bool"
where [stream_fusion]: "llist_all2_cons sg sh \<longleftrightarrow> llist_all2 P (lunstream g sg) (lunstream h sh)"

definition llist_all2_cons1 :: "'a \<Rightarrow> 'sg \<Rightarrow> 'sh \<Rightarrow> bool"
where "llist_all2_cons1 x sg' sh = llist_all2 P (LCons x (lunstream g sg')) (lunstream h sh)"

lemma llist_all2_cons_code [code]:
  "llist_all2_cons sg sh = 
  (case g sg of
     Done \<Rightarrow> lnull_cons h sh
   | Skip sg' \<Rightarrow> llist_all2_cons sg' sh
   | Yield a sg' \<Rightarrow> llist_all2_cons1 a sg' sh)"
by(simp split: step.split add: llist_all2_cons_def lnull_cons_def llist_all2_cons1_def lunstream_simps lnull_def)

lemma llist_all2_cons1_code [code]:
  "llist_all2_cons1 x sg' sh = 
  (case h sh of
     Done \<Rightarrow> False
   | Skip sh' \<Rightarrow> llist_all2_cons1 x sg' sh'
   | Yield y sh' \<Rightarrow> P x y \<and> llist_all2_cons sg' sh')"
by(simp split: step.split add: llist_all2_cons_def lnull_cons_def lnull_def llist_all2_cons1_def lunstream_simps)

end

lemma llist_all2_cons_fusion2 [stream_fusion]:
  "llist_all2_cons (lgenerator g) (lgenerator h) P sg sh \<longleftrightarrow> llist_all2 P (lunstream' g sg) (lunstream' h sh)"
by transfer(rule llist_all2_cons_def)

lemma llist_all2_cons_fusion3 [stream_fusion]:
  "llist_all2_cons g (lgenerator h) P sg sh \<longleftrightarrow> llist_all2 P (lunstream g sg) (lunstream' h sh)"
by transfer(rule llist_all2_cons_def)

lemma llist_all2_cons_fusion4 [stream_fusion]:
  "llist_all2_cons (lgenerator g) h P sg sh \<longleftrightarrow> llist_all2 P (lunstream' g sg) (lunstream h sh)"
by transfer(rule llist_all2_cons_def)

subsection {* @{const lnth} *}

context fixes g :: "('a, 's) lgenerator" begin

definition lnth_cons :: "nat \<Rightarrow> 's \<Rightarrow> 'a"
where [stream_fusion]: "lnth_cons n s = lnth (lunstream g s) n"

lemma lnth_cons_code [code]:
  "lnth_cons n s = (case g s of
    Done \<Rightarrow> undefined n
  | Skip s' \<Rightarrow> lnth_cons n s'
  | Yield x s' \<Rightarrow> (if n = 0 then x else lnth_cons (n - 1) s'))"
by(cases n)(simp_all add: lnth_cons_def lunstream_simps lnth_LNil split: step.split)

end

lemma lnth_cons_fusion2 [stream_fusion]:
  "lnth_cons (lgenerator g) n s = lnth (lunstream' g s) n"
by transfer(rule lnth_cons_def)

subsection {* @{const lprefix} *}

context
  fixes g :: "('a, 'sg) lgenerator"
  and h :: "('a, 'sh) lgenerator"
begin

definition lprefix_cons :: "'sg \<Rightarrow> 'sh \<Rightarrow> bool"
where [stream_fusion]: "lprefix_cons sg sh \<longleftrightarrow> lprefix (lunstream g sg) (lunstream h sh)"

definition lprefix_cons1 :: "'a \<Rightarrow> 'sg \<Rightarrow> 'sh \<Rightarrow> bool"
where "lprefix_cons1 x sg' sh \<longleftrightarrow> lprefix (LCons x (lunstream g sg')) (lunstream h sh)"

lemma lprefix_cons_code [code]:
  "lprefix_cons sg sh \<longleftrightarrow> (case g sg of
     Done \<Rightarrow> True | Skip sg' \<Rightarrow> lprefix_cons sg' sh | Yield x sg' \<Rightarrow> lprefix_cons1 x sg' sh)"
by(simp add: lprefix_cons_def lprefix_cons1_def lunstream_simps split: step.split)

lemma lprefix_cons1_code [code]:
  "lprefix_cons1 x sg' sh \<longleftrightarrow> (case h sh of
     Done \<Rightarrow> False | Skip sh' \<Rightarrow> lprefix_cons1 x sg' sh'
   | Yield y sh' \<Rightarrow> x = y \<and> lprefix_cons sg' sh')"
by(simp add: lprefix_cons_def lprefix_cons1_def lunstream_simps split: step.split)

end

lemma lprefix_cons_fusion2 [stream_fusion]:
  "lprefix_cons (lgenerator g) (lgenerator h) sg sh \<longleftrightarrow> lprefix (lunstream' g sg) (lunstream' h sh)"
by transfer(rule lprefix_cons_def)

lemma lprefix_cons_fusion3 [stream_fusion]:
  "lprefix_cons g (lgenerator h) sg sh \<longleftrightarrow> lprefix (lunstream g sg) (lunstream' h sh)"
by transfer(rule lprefix_cons_def)

lemma lprefix_cons_fusion4 [stream_fusion]:
  "lprefix_cons (lgenerator g) h sg sh \<longleftrightarrow> lprefix (lunstream' g sg) (lunstream h sh)"
by transfer(rule lprefix_cons_def)

section {* Transformers *}

subsection {* @{const lmap} *}

definition lmap_trans :: "('a \<Rightarrow> 'b) \<Rightarrow> ('a, 's) lgenerator \<Rightarrow> ('b, 's) lgenerator"
where "lmap_trans = map_raw"

lemma lunstream_lmap_trans [stream_fusion]: fixes f g s
  defines [simp]: "g' \<equiv> lmap_trans f g"
  shows "lunstream g' s = lmap f (lunstream g s)" (is "?lhs = ?rhs")
proof(rule lprefix_antisym)
  show "lprefix ?lhs ?rhs"
  proof(induction g' arbitrary: s rule: lunstream.fixp_induct) 
    case (3 lunstream_g')
    then show ?case
      by(cases "g s")(simp_all add: lmap_trans_def map_raw_def lunstream_simps)
  qed simp_all
next
  note [cont_intro] = ccpo.admissible_leI[OF llist_ccpo]
  show "lprefix ?rhs ?lhs"
  proof(induction g arbitrary: s rule: lunstream.fixp_induct) 
    case (3 lunstream_g)
    thus ?case by(cases "g s")(simp_all add: lmap_trans_def map_raw_def lunstream_simps)
  qed simp_all
qed

lift_definition lmap_trans' :: "('a \<Rightarrow> 'b) \<Rightarrow> ('a, 's) lgenerator' \<Rightarrow> ('b, 's) lgenerator'"
is lmap_trans
proof
  fix f :: "'a \<Rightarrow> 'b" and g :: "('a, 's) lgenerator" and s
  assume "productive g"
  hence "s \<in> productive_on g" ..
  thus "s \<in> productive_on (lmap_trans f g)"
    by induction(auto simp add: lmap_trans_def map_raw_def intro: productive_on.intros)
qed

lemma lunstream'_lmap_trans' [stream_fusion]:
  "lunstream' (lmap_trans' f g) s = lmap f (lunstream' g s)"
by transfer(rule lunstream_lmap_trans)

subsection {* @{const ltake} *}

fun ltake_trans :: "('a, 's) lgenerator \<Rightarrow> ('a, (enat \<times> 's)) lgenerator"
where
  "ltake_trans g (n, s) =
  (if n = 0 then Done else case g s of 
    Done \<Rightarrow> Done | Skip s' \<Rightarrow> Skip (n, s') | Yield a s' \<Rightarrow> Yield a (epred n, s'))"

lemma ltake_trans_fusion [stream_fusion]:
  fixes g' g
  defines [simp]: "g' \<equiv> ltake_trans g"
  shows "lunstream g' (n, s) = ltake n (lunstream g s)" (is "?lhs = ?rhs")
proof(rule lprefix_antisym)
  show "lprefix ?lhs ?rhs"
  proof(induction g' arbitrary: n s rule: lunstream.fixp_induct)
    case (3 lunstream_g')
    thus ?case
      by(cases "g s")(auto simp add: lunstream_simps neq_zero_conv_eSuc)
  qed simp_all
  show "lprefix ?rhs ?lhs"
  proof(induction g arbitrary: s n rule: lunstream.fixp_induct)
    case (3 lunstream_g)
    thus ?case by(cases "g s" n rule: step.exhaust[case_product enat_coexhaust])(auto simp add: lunstream_simps)
  qed simp_all
qed

lift_definition ltake_trans' :: "('a, 's) lgenerator' \<Rightarrow> ('a, (enat \<times> 's)) lgenerator'"
is "ltake_trans"
proof
  fix g :: "('a, 's) lgenerator" and s :: "enat \<times> 's"
  obtain n sg where s: "s = (n, sg)" by(cases s)
  assume "productive g"
  hence "sg \<in> productive_on g" ..
  then show "s \<in> productive_on (ltake_trans g)" unfolding \<open>s = (n, sg)\<close>
    apply(induction arbitrary: n)
    apply(case_tac [!] n rule: enat_coexhaust)
    apply(auto intro: productive_on.intros)
    done
qed

lemma ltake_trans'_fusion [stream_fusion]:
  "lunstream' (ltake_trans' g) (n, s) = ltake n (lunstream' g s)"
by transfer(rule ltake_trans_fusion)

subsection {* @{const ldropn} *}

abbreviation (input) ldropn_trans :: "('b, 'a) lgenerator \<Rightarrow> ('b, nat \<times> 'a) lgenerator"
where "ldropn_trans \<equiv> drop_raw"

lemma ldropn_trans_fusion [stream_fusion]:
  fixes g defines [simp]: "g' \<equiv> ldropn_trans g"
  shows "lunstream g' (n, s) = ldropn n (lunstream g s)" (is "?lhs = ?rhs")
proof(rule lprefix_antisym)
  show "lprefix ?lhs ?rhs"
  proof(induction g' arbitrary: n s rule: lunstream.fixp_induct)
    case (3 lunstream_g')
    thus ?case
      by(cases "g s" n rule: step.exhaust[case_product nat.exhaust])
        (auto simp add: lunstream_simps elim: meta_allE[where x=0])
  qed simp_all
  note [cont_intro] = ccpo.admissible_leI[OF llist_ccpo]
  show "lprefix ?rhs ?lhs"
  proof(induction g arbitrary: n s rule: lunstream.fixp_induct)
    case (3 lunstream_g)
    thus ?case by(cases n)(auto split: step.split simp add: lunstream_simps elim: meta_allE[where x=0])
  qed simp_all
qed

lift_definition ldropn_trans' :: "('a, 's) lgenerator' \<Rightarrow> ('a, nat \<times> 's) lgenerator'"
is ldropn_trans
proof
  fix g :: "('a, 's) lgenerator" and ns :: "nat \<times> 's"
  obtain n s where ns: "ns = (n, s)" by(cases ns)
  assume g: "productive g"
  show "ns \<in> productive_on (ldropn_trans g)" unfolding ns
  proof(induction n arbitrary: s)
    case 0
    from g have "s \<in> productive_on g" ..
    thus ?case by induction(auto intro: productive_on.intros)
  next
    case (Suc n)
    from g have "s \<in> productive_on g" ..
    thus ?case by induction(auto intro: productive_on.intros Suc.IH)
  qed
qed

lemma ldropn_trans'_fusion [stream_fusion]:
  "lunstream' (ldropn_trans' g) (n, s) = ldropn n (lunstream' g s)"
by transfer(rule ldropn_trans_fusion)

subsection {* @{const ldrop} *}

fun ldrop_trans :: "('a, 's) lgenerator \<Rightarrow> ('a, enat \<times> 's) lgenerator"
where
  "ldrop_trans g (n, s) = (case g s of 
    Done \<Rightarrow> Done | Skip s' \<Rightarrow> Skip (n, s')
  | Yield x s' \<Rightarrow> (if n = 0 then Yield x (n, s') else Skip (epred n, s')))"

lemma ldrop_trans_fusion [stream_fusion]:
  fixes g g' defines [simp]: "g' \<equiv> ldrop_trans g"
  shows "lunstream g' (n, s) = ldrop n (lunstream g s)" (is "?lhs = ?rhs")
proof(rule lprefix_antisym)
  show "lprefix ?lhs ?rhs"
    by(induction g' arbitrary: n s rule: lunstream.fixp_induct)
      (auto simp add: lunstream_simps neq_zero_conv_eSuc elim: meta_allE[where x=0] split: step.split)
  show "lprefix ?rhs ?lhs"
  proof(induction g arbitrary: n s rule: lunstream.fixp_induct)
    case (3 lunstream_g)
    thus ?case
      by(cases n rule: enat_coexhaust)(auto simp add: lunstream_simps split: step.split elim: meta_allE[where x=0])
  qed simp_all
qed

lemma ldrop_trans_fusion2 [stream_fusion]:
  "lunstream (ldrop_trans (lgenerator g)) (n, s) = ldrop n (lunstream' g s)"
by transfer (rule ldrop_trans_fusion)

subsection {* @{const ltakeWhile} *}

abbreviation (input) ltakeWhile_trans :: "('a \<Rightarrow> bool) \<Rightarrow> ('a, 's) lgenerator \<Rightarrow> ('a, 's) lgenerator"
where "ltakeWhile_trans \<equiv> takeWhile_raw"

lemma ltakeWhile_trans_fusion [stream_fusion]:
  fixes P g g' defines [simp]: "g' \<equiv> ltakeWhile_trans P g"
  shows "lunstream g' s = ltakeWhile P (lunstream g s)" (is "?lhs = ?rhs")
proof(rule lprefix_antisym)
  show "lprefix ?lhs ?rhs"
    by(induction g' arbitrary: s rule: lunstream.fixp_induct)(auto simp add: lunstream_simps takeWhile_raw_def split: step.split)
  show "lprefix ?rhs ?lhs"
    by(induction g arbitrary: s rule: lunstream.fixp_induct)(auto split: step.split simp add: lunstream_simps takeWhile_raw_def)
qed

lift_definition ltakeWhile_trans' :: "('a \<Rightarrow> bool) \<Rightarrow> ('a, 's) lgenerator' \<Rightarrow> ('a, 's) lgenerator'"
is ltakeWhile_trans
proof
  fix P and g :: "('a, 's) lgenerator" and s
  assume "productive g"
  hence "s \<in> productive_on g" ..
  thus "s \<in> productive_on (ltakeWhile_trans P g)"
    apply(induction)
    apply(case_tac [3] "P x")
    apply(auto intro: productive_on.intros simp add: takeWhile_raw_def)
    done
qed

lemma ltakeWhile_trans'_fusion [stream_fusion]:
  "lunstream' (ltakeWhile_trans' P g) s = ltakeWhile P (lunstream' g s)"
by transfer(rule ltakeWhile_trans_fusion)

subsection {* @{const ldropWhile} *}

abbreviation (input) ldropWhile_trans :: "('a \<Rightarrow> bool) \<Rightarrow> ('a, 'b) lgenerator \<Rightarrow> ('a, bool \<times> 'b) lgenerator"
where "ldropWhile_trans \<equiv> dropWhile_raw"

lemma ldropWhile_trans_fusion [stream_fusion]:
  fixes P g g' defines [simp]: "g' \<equiv> ldropWhile_trans P g"
  shows "lunstream g' (True, s) = ldropWhile P (lunstream g s)" (is "?lhs = ?rhs")
proof -
  have "lprefix ?lhs ?rhs" "lprefix (lunstream g' (False, s)) (lunstream g s)"
    by(induction g' arbitrary: s rule: lunstream.fixp_induct)(simp_all add: lunstream_simps split: step.split)
  moreover have "lprefix ?rhs ?lhs" "lprefix (lunstream g s) (lunstream g' (False, s))"
    by(induction g arbitrary: s rule: lunstream.fixp_induct)(simp_all add: lunstream_simps split: step.split)
  ultimately show ?thesis by(blast intro: lprefix_antisym)
qed

lemma ldropWhile_trans_fusion2 [stream_fusion]:
  "lunstream (ldropWhile_trans P (lgenerator g)) (True, s) = ldropWhile P (lunstream' g s)"
by transfer(rule ldropWhile_trans_fusion)

subsection {* @{const lzip} *}

abbreviation (input) lzip_trans :: "('a, 's1) lgenerator \<Rightarrow> ('b, 's2) lgenerator \<Rightarrow> ('a \<times> 'b, 's1 \<times> 's2 \<times> 'a option) lgenerator"
where "lzip_trans \<equiv> zip_raw"

lemma lzip_trans_fusion [stream_fusion]:
  fixes g h gh defines [simp]: "gh \<equiv> lzip_trans g h"
  shows "lunstream gh (sg, sh, None) = lzip (lunstream g sg) (lunstream h sh)"
  (is "?lhs = ?rhs")
proof -
  have "lprefix ?lhs ?rhs"
    and "\<And>x. lprefix (lunstream gh (sg, sh, Some x)) (lzip (LCons x (lunstream g sg)) (lunstream h sh))"
  proof(induction gh arbitrary: sg sh rule: lunstream.fixp_induct) 
    case (3 lunstream)
    { case 1 show ?case using 3
        by(cases "g sg")(simp_all add: lunstream_simps) }
    { case 2 show ?case using 3
        by(cases "h sh")(simp_all add: lunstream_simps) }
  qed simp_all
  moreover
  note [cont_intro] = ccpo.admissible_leI[OF llist_ccpo]
  have "lprefix ?rhs ?lhs" 
    and "\<And>x. lprefix (lzip (LCons x (lunstream g sg)) (lunstream h sh)) (lunstream gh (sg, sh, Some x))"
  proof(induction g arbitrary: sg sh rule: lunstream.fixp_induct)
    case (3 lunstream_g)
    note IH = "3.IH"
    { case 1 show ?case using 3
        by(cases "g sg")(simp_all add: lunstream_simps fun_ord_def) }
    { case 2 show ?case
      proof(induction h arbitrary: sh sg x rule: lunstream.fixp_induct)
        case (3 unstream_h)
        thus ?case
        proof(cases "h sh")
          case (Yield y sh')
          thus ?thesis using "3.prems" IH "3.hyps"
            by(cases "g sg")(auto 4 3 simp add: lunstream_simps fun_ord_def intro: monotone_lzip2[THEN monotoneD] lprefix_trans)
        qed(simp_all add: lunstream_simps)
      qed simp_all }
  next
    case 2 case 2
    show ?case
      by(induction h arbitrary: sh rule: lunstream.fixp_induct)(simp_all add: lunstream_simps split: step.split)
  qed simp_all
  ultimately show ?thesis by(blast intro: lprefix_antisym)
qed

lemma lzip_trans_fusion2 [stream_fusion]:
  "lunstream (lzip_trans (lgenerator g) h) (sg, sh, None) = lzip (lunstream' g sg) (lunstream h sh)"
by transfer(rule lzip_trans_fusion)

lemma lzip_trans_fusion3 [stream_fusion]:
  "lunstream (lzip_trans g (lgenerator h)) (sg, sh, None) = lzip (lunstream g sg) (lunstream' h sh)"
by transfer(rule lzip_trans_fusion)

lift_definition lzip_trans' :: "('a, 's1) lgenerator' \<Rightarrow> ('b, 's2) lgenerator' \<Rightarrow> ('a \<times> 'b, 's1 \<times> 's2 \<times> 'a option) lgenerator'"
is "lzip_trans"
proof
  fix g :: "('a, 's1) lgenerator" and h :: "('b, 's2) lgenerator" and s :: "'s1 \<times> 's2 \<times> 'a option"
  assume "productive g" and "productive h"
  obtain sg sh mx where s: "s = (sg, sh, mx)" by(cases s)
  { fix x sg
    from \<open>productive h\<close> have "sh \<in> productive_on h" ..
    hence "(sg, sh, Some x) \<in> productive_on (lzip_trans g h)"
      by(induction)(auto simp add: intro: productive_on.intros) }
  moreover
  from \<open>productive g\<close> have "sg \<in> productive_on g" ..
  then have "(sg, sh, None) \<in> productive_on (lzip_trans g h)"
    by induction(auto intro: productive_on.intros calculation)
  ultimately show "s \<in> productive_on (lzip_trans g h)" unfolding s
    by(cases mx) auto
qed

lemma lzip_trans'_fusion [stream_fusion]:
  "lunstream' (lzip_trans' g h) (sg, sh, None) = lzip (lunstream' g sg) (lunstream' h sh)"
by transfer(rule lzip_trans_fusion)

subsection {* @{const lappend} *}

lift_definition lappend_trans :: "('a, 'sg) lgenerator' \<Rightarrow> ('a, 'sh) lgenerator \<Rightarrow> 'sh \<Rightarrow> ('a, 'sg + 'sh) lgenerator"
is append_raw .

lemma lunstream_append_raw:
  fixes g h sh gh defines [simp]: "gh \<equiv> append_raw g h sh"
  assumes "productive g"
  shows "lunstream gh (Inl sg) = lappend (lunstream g sg) (lunstream h sh)"
proof(coinduction arbitrary: sg rule: llist.strong_coinduct)
  case (Eq_llist sg)
  { fix sh'
    have "lprefix (lunstream gh (Inr sh')) (lunstream h sh')"
      by(induction gh arbitrary: sh' rule: lunstream.fixp_induct)(simp_all add: lunstream_simps split: step.split)
    moreover have "lprefix (lunstream h sh') (lunstream gh (Inr sh'))"
      by(induction h arbitrary: sh' rule: lunstream.fixp_induct)(simp_all add: lunstream_simps split: step.split)
    ultimately have "lunstream gh (Inr sh') = lunstream h sh'"
      by(blast intro: lprefix_antisym) }
  note Inr = this[unfolded gh_def]
  from \<open>productive g\<close> have sg: "sg \<in> productive_on g" ..
  then show ?case by induction(auto simp add: lunstream_sels Inr)
qed

lemma lappend_trans_fusion [stream_fusion]:
  "lunstream (lappend_trans g h sh) (Inl sg) = lappend (lunstream' g sg) (lunstream h sh)"
by transfer(rule lunstream_append_raw)

lift_definition lappend_trans' :: "('a, 'sg) lgenerator' \<Rightarrow> ('a, 'sh) lgenerator' \<Rightarrow> 'sh \<Rightarrow> ('a, 'sg + 'sh) lgenerator'"
is append_raw
proof
  fix g :: "('a, 'sg) lgenerator" and h :: "('a, 'sh) lgenerator" and sh s
  assume "productive g" "productive h"
  { fix sh'
    from \<open>productive h\<close> have "sh' \<in> productive_on h" ..
    then have "Inr sh' \<in> productive_on (append_raw g h sh)"
      by induction (auto intro: productive_on.intros)
  } moreover {
    fix sg
    from \<open>productive g\<close> have "sg \<in> productive_on g" ..
    then have "Inl sg \<in> productive_on (append_raw g h sh)"
      by induction(auto intro: productive_on.intros calculation) }
  ultimately show "s \<in> productive_on (append_raw g h sh)" by(cases s) auto
qed

lemma lappend_trans'_fusion [stream_fusion]:
  "lunstream' (lappend_trans' g h sh) (Inl sg) = lappend (lunstream' g sg) (lunstream' h sh)"
by transfer(rule lunstream_append_raw)

subsection {* @{const lfilter} *}

definition lfilter_trans :: "('a \<Rightarrow> bool) \<Rightarrow> ('a, 's) lgenerator \<Rightarrow> ('a, 's) lgenerator"
where "lfilter_trans = filter_raw"

lemma lunstream_lfilter_trans [stream_fusion]:
  fixes P g g' defines [simp]: "g' \<equiv> lfilter_trans P g"
  shows "lunstream g' s = lfilter P (lunstream g s)" (is "?lhs = ?rhs")
proof(rule lprefix_antisym)
  show "lprefix ?lhs ?rhs"
    by(induction g' arbitrary: s rule: lunstream.fixp_induct)
      (simp_all add: lfilter_trans_def filter_raw_def lunstream_simps split: step.split)
  show "lprefix ?rhs ?lhs"
  by(induction g arbitrary: s rule: lunstream.fixp_induct) 
    (simp_all add: lfilter_trans_def filter_raw_def lunstream_simps split: step.split)
qed

lemma lunstream_lfilter_trans2 [stream_fusion]:
  "lunstream (lfilter_trans P (lgenerator g)) s = lfilter P (lunstream' g s)"
by transfer(rule lunstream_lfilter_trans)

subsection {* @{const llist_of} *}

lift_definition llist_of_trans :: "('a, 's) generator \<Rightarrow> ('a, 's) lgenerator'"
is "\<lambda>x. x"
proof
  fix g :: "('a, 's) raw_generator" and s
  assume "terminates g"
  hence "s \<in> terminates_on g" by(simp add: terminates_def)
  then show "s \<in> productive_on g"
    by(induction)(auto intro: productive_on.intros)
qed

lemma lunstream_llist_of_trans [stream_fusion]:
  "lunstream' (llist_of_trans g) s = llist_of (unstream g s)"
apply(induction s taking: g rule: unstream.induct)
apply(rule llist.expand)
apply(auto intro: llist.expand simp add: llist_of_trans.rep_eq lunstream_sels lunstream'.rep_eq split: step.split)
done

text {* We cannot define a stream version of @{const list_of} because we would have to test
  for finiteness first and therefore traverse the list twice. *}

end