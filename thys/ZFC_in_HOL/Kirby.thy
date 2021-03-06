section \<open>Addition and Multiplication of Sets\<close>

theory Kirby
  imports ZFC_Cardinals

begin

subsection \<open>Generalised Addition\<close>

text \<open>Source: Laurence Kirby, Addition and multiplication of sets
      Math. Log. Quart. 53, No. 1, 52-65 (2007) / DOI 10.1002/malq.200610026
      @{url "http://faculty.baruch.cuny.edu/lkirby/mlqarticlejan2007.pdf"}\<close>

instantiation V :: plus
begin

text\<open>This definition is credited to Tarski\<close>
definition plus_V :: "V \<Rightarrow> V \<Rightarrow> V"
  where "plus_V x \<equiv> transrec (\<lambda>f z. x \<squnion> set (f ` elts z))"

instance ..
end

definition lift :: "V \<Rightarrow> V \<Rightarrow> V"
  where "lift x y \<equiv> set (plus x ` elts y)"

lemma plus: "x + y = x \<squnion> set ((+)x ` elts y)"
  unfolding plus_V_def  by (subst transrec) auto

lemma plus_eq_lift: "x + y = x \<squnion> lift x y"
  unfolding lift_def  using plus by blast

text\<open>Lemma 3.2\<close>
lemma lift_sup_distrib: "lift x (a \<squnion> b) = lift x a \<squnion> lift x b"
  by (simp add: image_Un lift_def sup_V_def)

lemma lift_Sup_distrib: "small Y \<Longrightarrow> lift x (\<Squnion> Y) = \<Squnion> (lift x ` Y)"
  by (auto simp: lift_def Sup_V_def image_Union)

lemma add_Sup_distrib:
  fixes x::V shows "y \<noteq> 0 \<Longrightarrow> x + (SUP z\<in>elts y. f z) = (SUP z\<in>elts y. x + f z)"
  by (auto simp: plus_eq_lift SUP_sup_distrib lift_Sup_distrib image_image)

text\<open>Proposition 3.3(ii)\<close>
instantiation V :: monoid_add
begin
instance
proof
  show "a + b + c = a + (b + c)" for a b c :: V
  proof (induction c rule: eps_induct)
    case (step c)
    have "(a+b) + c = a + b \<squnion> set ((+) (a + b) ` elts c)"
      by (metis plus)
    also have "\<dots> = a \<squnion> lift a b \<squnion> set ((\<lambda>u. a + (b+u)) ` elts c)"
      using plus_eq_lift step.IH by auto
    also have "\<dots> = a \<squnion> lift a (b + c)"
    proof -
      have "lift a b \<squnion> set ((\<lambda>u. a + (b + u)) ` elts c) = lift a (b + c)"
        unfolding lift_def
        by (metis elts_of_set image_image lift_def lift_sup_distrib plus_eq_lift replacement small_elts)
      then show ?thesis
        by (simp add: sup_assoc)
    qed
    also have "\<dots> = a + (b + c)"
      using plus_eq_lift by auto
    finally show ?case .
  qed
  show "0 + x = x" for x :: V
  proof (induction rule: eps_induct)
    case (step x)
    then show ?case
      by (subst plus) auto
  qed
  show "x + 0 = x" for x :: V
    by (subst plus) auto
qed
end

lemma lift_0 [simp]: "lift 0 x = x"
  by (simp add: lift_def)

lemma lift_by0 [simp]: "lift x 0 = 0"
  by (simp add: lift_def set_empty)

lemma lift_by1 [simp]: "lift x 1 = set{x}"
  by (simp add: lift_def)

lemma plus_vinsert: "x + vinsert z y = vinsert (x+z) (x + y)"
proof -
  have f1: "elts (x + y) = elts x \<union> (+) x ` elts y"
    by (metis elts_of_set lift_def plus_eq_lift replacement small_Un small_elts sup_V_def)
  moreover have "lift x (vinsert z y) = set ((+) x ` elts (set (insert z (elts y))))"
    using vinsert_def lift_def by presburger
  ultimately show ?thesis
    by (simp add: vinsert_def plus_eq_lift sup_V_def)
qed

lemma plus_V_succ_right: "x + succ y = succ (x + y)"
  by (metis plus_vinsert succ_def)

lemma mem_plus_V_E:
  assumes l: "l \<in> elts (x + y)"
  obtains "l \<in> elts x" | z where "z \<in> elts y" "l = x + z"
  using l by (auto simp: plus [of x y] split: if_split_asm)

lemma not_add_less_right: assumes "Ord y" shows "\<not> (x + y < x)"
  using assms
proof (induction rule: Ord_induct)
  case (step i)
  then show ?case
    by (metis less_le_not_le plus sup_ge1)
qed

lemma not_add_mem_right: "\<not> (x + y \<in> elts x)"
  by (metis sup_ge1 mem_not_refl plus vsubsetD)

text\<open>Proposition 3.3(iii)\<close>
lemma add_not_less_TC_self: "\<not> x + y \<sqsubset> x"
proof (induction y arbitrary: x rule: eps_induct)
  case (step y)
  then show ?case
    using less_TC_imp_not_le plus_eq_lift by fastforce
qed

lemma TC_sup_lift: "TC x \<sqinter> lift x y = 0"
proof -
  have "elts (TC x) \<inter> elts (set ((+) x ` elts y)) = {}"
    using add_not_less_TC_self by (auto simp: less_TC_def)
  then have "TC x \<sqinter> set ((+) x ` elts y) = set {}"
    by (metis inf_V_def)
  then show ?thesis
    by (simp add: lift_def zero_V_def)
qed

lemma lift_lift: "lift x (lift y z) = lift (x+y) z"
  using add.assoc  by (auto simp: lift_def)

lemma lift_self_disjoint: "x \<sqinter> lift x u = 0"
  by (metis TC_sup_lift arg_subset_TC inf.absorb_iff2 inf_assoc inf_sup_aci(3) lift_0)

lemma sup_lift_eq_lift:
  assumes "x \<squnion> lift x u = x \<squnion> lift x v"
  shows "lift x u = lift x v"
  by (metis (no_types) assms inf_sup_absorb inf_sup_distrib2 lift_self_disjoint sup_commute sup_inf_absorb)

text\<open>Proposition 3.4(i)\<close>
proposition lift_eq_lift: "lift x y = lift x z \<Longrightarrow> y = z"
proof (induction y arbitrary: z rule: eps_induct)
  case (step y)
  show ?case
  proof (intro vsubsetI order_antisym)
    show "u \<in> elts z" if "u \<in> elts y" for u
    proof -
      have "x+u \<in> elts (lift x z)"
        using lift_def step.prems that by fastforce
      then obtain v where "v \<in> elts z" "x+u = x+v"
        using lift_def by auto
      then have "lift x u = lift x v"
        using sup_lift_eq_lift by (simp add: plus_eq_lift)
      then have "u=v"
        using step.IH that by blast
      then show ?thesis
        using \<open>v \<in> elts z\<close> by blast
    qed
    show "u \<in> elts y" if "u \<in> elts z" for u
    proof -
      have "x+u \<in> elts (lift x y)"
        using lift_def step.prems that by fastforce
      then obtain v where "v \<in> elts y" "x+u = x+v"
        using lift_def by auto
      then have "lift x u = lift x v"
        using sup_lift_eq_lift by (simp add: plus_eq_lift)
      then have "u=v"
        using step.IH by (metis \<open>v \<in> elts y\<close>)
      then show ?thesis
        using \<open>v \<in> elts y\<close> by auto
    qed
  qed
qed

corollary inj_lift: "inj_on (lift x) A"
  by (auto simp: inj_on_def dest: lift_eq_lift)

corollary add_right_cancel [iff]:
  fixes x y z::V shows "x+y = x+z \<longleftrightarrow> y=z"
  by (metis lift_eq_lift plus_eq_lift sup_lift_eq_lift)

corollary add_mem_right_cancel [iff]:
  fixes x y z::V shows "x+y \<in> elts (x+z) \<longleftrightarrow> y \<in> elts z"
  apply safe
   apply (metis mem_plus_V_E not_add_mem_right add_right_cancel)
  by (metis ZFC_in_HOL.ext dual_order.antisym elts_vinsert insert_subset order_refl plus_vinsert)

corollary add_le_cancel_left [iff]:
  fixes x y z::V shows "x+y \<le> x+z \<longleftrightarrow> y\<le>z"
  by auto (metis add_mem_right_cancel mem_plus_V_E plus sup_ge1 vsubsetD)

corollary add_less_cancel_left [iff]:
  fixes x y z::V shows "x+y < x+z \<longleftrightarrow> y<z"
  by (simp add: less_le_not_le)

corollary lift_le_self [simp]: "lift x y \<le> x \<longleftrightarrow> y = 0"
  by (auto simp: inf.absorb_iff2 lift_eq_lift lift_self_disjoint)


text\<open>Proposition 3.5\<close>
lemma card_lift: "vcard (lift x y) = vcard y"
proof (rule cardinal_cong)
  have "bij_betw ((+)x) (elts y) (elts (lift x y))"
    unfolding bij_betw_def
    by (simp add: inj_on_def lift_def)
  then show "elts (lift x y) \<approx> elts y"
    using eqpoll_def eqpoll_sym by blast
qed

lemma eqpoll_lift: "elts (lift x y) \<approx> elts y"
  by (metis card_lift cardinal_eqpoll eqpoll_sym eqpoll_trans)

lemma card_add: "vcard (x + y) = vcard x \<oplus> vcard y"
  using card_lift [of x y] lift_self_disjoint [of x]
  by (simp add: plus_eq_lift vcard_disjoint_sup)

text\<open>Proposition 3.6\<close>
proposition TC_add: "TC (x + y) = TC x \<squnion> lift x (TC y)"
proof (induction y rule: eps_induct)
  case (step y)
  have *: "\<Squnion> (TC ` (+) x ` elts y) = TC x \<squnion> (SUP u\<in>elts y. TC (set ((+) x ` elts u)))"
    if "elts y \<noteq> {}"
  proof -
    obtain w where "w \<in> elts y"
      using \<open>elts y \<noteq> {}\<close> by blast
    then have "TC x \<le> TC (x + w)"
      by (simp add: step.IH)
    then have \<dagger>: "TC x \<le> (SUP w\<in>elts y. TC (x + w))"
      using \<open>w \<in> elts y\<close> by blast
    show ?thesis
      using that
      apply (intro conjI ballI impI order_antisym; clarsimp simp add: image_comp \<dagger>)
       apply(metis TC_sup_distrib Un_iff elts_sup_iff plus)
      by (metis TC_least Transset_TC arg_subset_TC le_sup_iff plus vsubsetD)
  qed
  have "TC (x + y) = (x + y) \<squnion> \<Squnion> (TC ` elts (x + y))"
    using TC by blast
  also have "\<dots> = x \<squnion> lift x y \<squnion> \<Squnion> (TC ` elts x) \<squnion> \<Squnion> ((\<lambda>u. TC (x+u)) ` elts y)"
    apply (simp add: plus_eq_lift image_Un Sup_Un_distrib sup.left_commute sup_assoc TC_sup_distrib SUP_sup_distrib)
    apply (simp add: lift_def sup.commute sup_aci *)
    done
  also have "\<dots> = x \<squnion> \<Squnion> (TC ` elts x) \<squnion> lift x y \<squnion> \<Squnion> ((\<lambda>u. TC x \<squnion> lift x (TC u)) ` elts y)"
    by (simp add: sup_aci step.IH)
  also have "\<dots> = TC x \<squnion> lift x y \<squnion> \<Squnion> ((\<lambda>u. lift x (TC u)) ` elts y)"
    by (simp add: sup_aci SUP_sup_distrib flip: TC [of x])
  also have "\<dots> = TC x \<squnion> lift x (y \<squnion> \<Squnion> (TC ` elts y))"
    by (metis (no_types) elts_of_set lift_Sup_distrib image_image lift_sup_distrib replacement small_elts sup_assoc)
  also have "\<dots> = TC x \<squnion> lift x (TC y)"
    by (simp add: TC [of y])
  finally show ?case .
qed

corollary TC_add': "z \<sqsubset> x + y \<longleftrightarrow> z \<sqsubset> x \<or> (\<exists>v. v \<sqsubset> y \<and> z = x + v)"
  using TC_add by (force simp: less_TC_def lift_def)

text\<open>Corollary 3.7\<close>
corollary vcard_TC_add: "vcard (TC (x+y)) = vcard (TC x) \<oplus> vcard (TC y)"
  by (simp add: TC_add TC_sup_lift card_lift vcard_disjoint_sup)

text\<open>Corollary 3.8\<close>
corollary TC_lift:
  assumes "y \<noteq> 0"
  shows "TC (lift x y) = TC x \<squnion> lift x (TC y)"
proof -
  have "TC (lift x y) = lift x y \<squnion> \<Squnion> ((\<lambda>u. TC(x+u)) ` elts y)"
    unfolding TC [of "lift x y"]  by (simp add: lift_def image_image)
  also have "\<dots> = lift x y \<squnion> (SUP u\<in>elts y. TC x \<squnion> lift x (TC u))"
    by (simp add: TC_add)
  also have "\<dots> = lift x y \<squnion> TC x \<squnion> (SUP u\<in>elts y. lift x (TC u))"
    using assms by (auto simp: SUP_sup_distrib)
  also have "\<dots> = TC x \<squnion> lift x (TC y)"
    by (simp add: TC [of y] sup_aci image_image lift_sup_distrib lift_Sup_distrib)
  finally show ?thesis .
qed

proposition rank_add_distrib: "rank (x+y) = rank x + rank y"
proof (induction y rule: eps_induct)
  case (step y)
  show ?case
  proof (cases "y=0")
    case False
    then obtain e where e: "e \<in> elts y"
      by fastforce
    have "rank (x+y) = (SUP u\<in>elts (x \<squnion> ZFC_in_HOL.set ((+) x ` elts y)). succ (rank u))"
      by (metis plus rank_Sup)
    also have "\<dots> = (SUP x\<in>elts x. succ (rank x)) \<squnion> (SUP z\<in>elts y. succ (rank x + rank z))"
      apply (simp add: Sup_Un_distrib image_Un image_image)
      apply (simp add: step cong: SUP_cong_simp)
      done
    also have "\<dots> = (SUP z \<in> elts y. rank x + succ (rank z))"
    proof -
      have "rank x \<le> (SUP z\<in>elts y. ZFC_in_HOL.succ (rank x + rank z))"
        using \<open>y \<noteq> 0\<close>
        by (auto simp: plus_eq_lift intro: order_trans [OF _ cSUP_upper [OF e]])
      then show ?thesis
        by (force simp: plus_V_succ_right simp flip: rank_Sup [of x] intro!: order_antisym)
    qed
    also have "\<dots> = rank x + (SUP z \<in> elts y. succ (rank z))"
      by (simp add: add_Sup_distrib False)
    also have "\<dots> = rank x + rank y"
      by (simp add: rank_Sup [of y])
    finally show ?thesis .
  qed auto
qed

lemma Ord_add [simp]: "\<lbrakk>Ord x; Ord y\<rbrakk> \<Longrightarrow> Ord (x+y)"
proof (induction y rule: eps_induct)
  case (step y)
  then show ?case
    by (metis Ord_rank rank_add_distrib rank_of_Ord)
qed


definition vle :: "V \<Rightarrow> V \<Rightarrow> bool" (infix "\<unlhd>" 50)
  where "x \<unlhd> y \<equiv> \<exists>z::V. x+z = y"

lemma vle_refl [iff]: "x \<unlhd> x"
  by (metis (no_types) add.right_neutral vle_def)

lemma vle_antisym: "\<lbrakk>x \<unlhd> y; y \<unlhd> x\<rbrakk> \<Longrightarrow> x = y"
  by (metis V_equalityI plus_eq_lift sup_ge1 vle_def vsubsetD)

lemma vle_trans [trans]: "\<lbrakk>x \<unlhd> y; y \<unlhd> z\<rbrakk> \<Longrightarrow> x \<unlhd> z"
  by (metis add.assoc vle_def)

definition vle_comparable :: "V \<Rightarrow> V \<Rightarrow> bool"
  where "vle_comparable x y \<equiv> x \<unlhd> y \<or> y \<unlhd> x"

text\<open>Lemma 3.13\<close>
lemma comparable:
  assumes "a+b = c+d"
  shows "vle_comparable a c"
unfolding vle_comparable_def
proof (rule ccontr)
  assume non: "\<not> (a \<unlhd> c \<or> c \<unlhd> a)"
  let ?\<phi> = "\<lambda>x. \<forall>z. a+x \<noteq> c+z"
  have "?\<phi> x" for x
  proof (induction x rule: eps_induct)
    case (step x)
    show ?case
    proof (cases "x=0")
      case True
      with non nonzero_less_TC show ?thesis
        using vle_def by auto
    next
      case False
      then obtain v where "v \<in> elts x"
        using trad_foundation by blast
      show ?thesis
      proof clarsimp
        fix z
        assume eq: "a + x = c + z"
        then have "z \<noteq> 0"
          using vle_def non by auto
        have av: "a+v \<in> elts (a+x)"
          by (simp add: \<open>v \<in> elts x\<close>)
        moreover have "a+x = c \<squnion> lift c z"
          using eq plus_eq_lift by fastforce
        ultimately have "a+v \<in> elts (c \<squnion> lift c z)"
          by simp
        moreover
        define u where "u \<equiv> set (elts x - {v})"
        have u: "v \<notin> elts u" and xeq: "x = vinsert v u"
          using \<open>v \<in> elts x\<close> by (auto simp: u_def intro: order_antisym)
        have case1: "a+v \<notin> elts c"
        proof
          assume avc: "a + v \<in> elts c"
          then have "a \<le> c"
            by clarify (metis Un_iff elts_sup_iff eq mem_not_sym mem_plus_V_E plus_eq_lift)
          moreover have "a \<squnion> lift a x = c \<squnion> lift c z"
            using eq by (simp add: plus_eq_lift)
          ultimately have "lift c z \<le> lift a x"
            by (metis inf.absorb_iff2 inf_commute inf_sup_absorb inf_sup_distrib2 lift_self_disjoint sup.commute)
          also have "\<dots> = vinsert (a+v) (lift a u)"
            by (simp add: lift_def vinsert_def xeq)
          finally have *: "lift c z \<le> vinsert (a + v) (lift a u)" .
          have "lift c z \<le> lift a u"
          proof -
            have "a + v \<notin> elts (lift c z)"
              using lift_self_disjoint [of c z] avc V_disjoint_iff by auto
            then show ?thesis
              using * less_eq_V_def by auto
          qed
          { fix e
            assume "e \<in> elts z"
            then have "c+e \<in> elts (lift c z)"
              by (simp add: lift_def)
            then have "c+e \<in> elts (lift a u)"
              using \<open>lift c z \<le> lift a u\<close> by blast
            then obtain y where "y \<in> elts u" "c+e = a+y"
              using lift_def by auto
            then have False
              by (metis elts_vinsert insert_iff step.IH xeq)
          }
          then show False
            using \<open>z \<noteq> 0\<close> by fastforce
        qed
        ultimately show False
          by (metis (no_types) \<open>v \<in> elts x\<close> av case1 eq mem_plus_V_E step.IH)
      qed
    qed
  qed
  then show False
    using assms by blast
qed

lemma vle1: "x \<unlhd> y \<Longrightarrow> x \<le> y"
  using vle_def plus_eq_lift by auto

lemma vle2: "x \<unlhd> y \<Longrightarrow> x \<sqsubseteq> y"
  by (metis (full_types) TC_add' add.right_neutral le_TC_def vle_def nonzero_less_TC)


subsection \<open>Generalised Multiplication\<close>

text \<open>Credited to Dana Scott\<close>

instantiation V :: times
begin

text\<open>This definition is credited to Tarski\<close>
definition times_V :: "V \<Rightarrow> V \<Rightarrow> V"
  where "times_V x \<equiv> transrec (\<lambda>f y. \<Squnion> ((\<lambda>u. lift (f u) x) ` elts y))"

instance ..
end

lemma mult: "x * y = (SUP u\<in>elts y. lift (x * u) x)"
  unfolding times_V_def  by (subst transrec) (force simp:)

text \<open>Lemma 4.2\<close>

lemma mult_zero_right [simp]:
  fixes x::V shows "x * 0 = 0"
  by (metis ZFC_in_HOL.Sup_empty elts_0 image_empty mult)

lemma mult_insert: "x * (vinsert y z) = x*z \<squnion> lift (x*y) x"
  by (metis (no_types, lifting) elts_vinsert image_insert replacement small_elts sup_commute mult Sup_V_insert)

lemma mult_succ: "x * succ y = x*y + x"
  by (simp add: mult_insert plus_eq_lift succ_def)

subsubsection\<open>Proposition 4.3\<close>

lemma mult_zero_left [simp]:
  fixes x::V shows "0 * x = 0"
proof (induction x rule: eps_induct)
  case (step x)
  then show ?case
    by (subst mult) auto
qed

lemma mult_sup_distrib:
  fixes x::V shows "x * (y \<squnion> z) = x*y \<squnion> x*z"
  unfolding mult [of x "y \<squnion> z"] mult [of x y] mult [of x z]
  by (simp add: Sup_Un_distrib image_Un)

lemma mult_Sup_distrib: "small Y \<Longrightarrow> x * (\<Squnion>Y) = \<Squnion> ((*) x ` Y)"
  unfolding mult [of x "\<Squnion>Y"]
  by (simp add: cSUP_UNION) (metis mult)

lemma mult_lift_imp_distrib: "x * (lift y z) = lift (x*y) (x*z) \<Longrightarrow> x * (y+z) = x*y + x*z"
  by (simp add: mult_sup_distrib plus_eq_lift)

lemma mult_lift: "x * (lift y z) = lift (x*y) (x*z)"
proof (induction z rule: eps_induct)
  case (step z)
  have "x * lift y z = (SUP u\<in>elts (lift y z). lift (x * u) x)"
    using mult by blast
  also have "\<dots> = (SUP v\<in>elts z. lift (x * (y + v)) x)"
    using lift_def by auto
  also have "\<dots> = (SUP v\<in>elts z. lift (x * y + x * v) x)"
    using mult_lift_imp_distrib step.IH by auto
  also have "\<dots> = (SUP v\<in>elts z. lift (x * y) (lift (x * v) x))"
    by (simp add: lift_lift)
  also have "\<dots> = lift (x * y) (SUP v\<in>elts z. lift (x * v) x)"
    by (simp add: image_image lift_Sup_distrib)
  also have "\<dots> = lift (x*y) (x*z)"
    by (metis mult)
  finally show ?case .
qed

lemma add_mult_distrib: "x * (y+z) = x*y + x*z" for x::V
  by (simp add: mult_lift mult_lift_imp_distrib)

instantiation V :: monoid_mult
begin
instance
proof
  show "1 * x = x" for x :: V
  proof (induction x rule: eps_induct)
    case (step x)
    then show ?case
      by (subst mult) auto
  qed
  show "x * 1 = x" for x :: V
    by (subst mult) auto
  show "(x * y) * z = x * (y * z)" for x y z::V
  proof (induction z rule: eps_induct)
    case (step z)
    have "(x * y) * z = (SUP u\<in>elts z. lift (x * y * u) (x * y))"
      using mult by blast
    also have "\<dots> = (SUP u\<in>elts z. lift (x * (y * u)) (x * y))"
      using step.IH by auto
    also have "\<dots> = (SUP u\<in>elts z. x * lift (y * u) y)"
      using mult_lift by auto
    also have "\<dots> = x * (SUP u\<in>elts z. lift (y * u) y)"
      by (simp add: image_image mult_Sup_distrib)
    also have "\<dots> = x * (y * z)"
      by (metis mult)
    finally show ?case .
  qed
qed

end

lemma mult_sing_1 [simp]:
  fixes x::V shows "x * set{1} = lift x x"
  by (subst mult) auto

lemma mult_2_right [simp]:
  fixes x::V shows "x * set{0,1} = x+x"
  by (subst mult) (auto simp: Sup_V_insert plus_eq_lift)

lemma Ord_mult [simp]: "\<lbrakk>Ord y; Ord x\<rbrakk> \<Longrightarrow> Ord (x*y)"
proof (induction y rule: Ord_induct3)
  case 0
  then show ?case
    by auto
next
  case (succ k)
  then show ?case
    by (simp add: mult_succ)
next
  case (Limit k)
  then have "Ord (x * \<Squnion> (elts k))"
    by (force simp: mult_Sup_distrib intro: Ord_Sup)
  then show ?case
    using Limit.hyps Limit_eq_Sup_self by auto
qed

subsubsection \<open>Proposition 4.4-5\<close>
proposition rank_mult_distrib: "rank (x*y) = rank x * rank y"
proof (induction y rule: eps_induct)
  case (step y)
  have "rank (x*y) = (SUP y\<in>elts (SUP u\<in>elts y. lift (x * u) x). succ (rank y))"
    by (metis rank_Sup mult)
  also have "\<dots> = (SUP u\<in>elts y. SUP r\<in>elts x. succ (rank (x * u + r)))"
    apply (simp add: lift_def image_image image_UN)
    apply (simp add: Sup_V_def)
    done
  also have "\<dots> = (SUP u\<in>elts y. SUP r\<in>elts x. succ (rank (x * u) + rank r))"
    using rank_add_distrib by auto
  also have "\<dots> = (SUP u\<in>elts y. SUP r\<in>elts x. succ (rank x * rank u + rank r))"
    using step arg_cong [where f = Sup] by auto
  also have "\<dots> = (SUP u\<in>elts y. rank x * rank u + rank x)"
  proof (rule SUP_cong)
    show "(SUP r\<in>elts x. succ (rank x * rank u + rank r)) = rank x * rank u + rank x"
      if "u \<in> elts y" for u
    proof (cases "x=0")
      case False
      have "(SUP r\<in>elts x. succ (rank x * rank u + rank r)) = rank x * rank u + (SUP y\<in>elts x. succ (rank y))"
      proof (rule order_antisym)
        show "(SUP r\<in>elts x. succ (rank x * rank u + rank r)) \<le> rank x * rank u + (SUP y\<in>elts x. succ (rank y))"
          by (auto simp: Sup_le_iff simp flip: plus_V_succ_right)
        have "rank x * rank u + (SUP y\<in>elts x. succ (rank y)) = (SUP y\<in>elts x. rank x * rank u + succ (rank y))"
          by (simp add: add_Sup_distrib False)
        also have "\<dots> \<le> (SUP r\<in>elts x. succ (rank x * rank u + rank r))"
          using plus_V_succ_right by auto
        finally show "rank x * rank u + (SUP y\<in>elts x. succ (rank y)) \<le> (SUP r\<in>elts x. succ (rank x * rank u + rank r))" .
      qed
      also have "\<dots> = rank x * rank u + rank x"
        by (metis rank_Sup)
      finally show ?thesis .
    qed auto
  qed auto
  also have "\<dots> = rank x * rank y"
    by (simp add: rank_Sup [of y] mult_Sup_distrib mult_succ image_image)
  finally show ?case .
qed

lemma mult_le1:
  fixes y::V assumes "y \<noteq> 0" shows "x \<sqsubseteq> x * y"
proof (cases "x = 0")
  case False
  then obtain r where r: "r \<in> elts x"
    by fastforce
  from \<open>y \<noteq> 0\<close> show ?thesis
  proof (induction y rule: eps_induct)
    case (step y)
    show ?case
    proof (cases "y = 1")
      case False
      with \<open>y \<noteq> 0\<close> obtain p where p: "p \<in> elts y" "p \<noteq> 0"
        by (metis V_equalityI elts_1 insertI1 singletonD trad_foundation)
      then have "x*p + r \<in> elts (lift (x*p) x)"
        by (simp add: lift_def r)
      moreover have "lift (x*p) x \<le> x*y"
        by (metis bdd_above_iff_small cSUP_upper2 order_refl \<open>p \<in> elts y\<close> replacement small_elts mult)
      ultimately have "x*p + r \<in> elts (x*y)"
        by blast
      moreover have "x*p \<sqsubseteq> x*p + r"
        by (metis TC_add' V_equalityI add.right_neutral eps_induct le_TC_refl less_TC_iff less_imp_le_TC)
      ultimately show ?thesis
        using step.IH [OF p] le_TC_trans less_TC_iff by blast
    qed auto
  qed
qed auto

lemma mult_eq_0_iff [simp]:
  fixes y::V shows "x * y = 0 \<longleftrightarrow> x=0 \<or> y=0"
proof
  show "x = 0 \<or> y = 0" if "x * y = 0"
    by (metis le_0 le_TC_def less_TC_imp_not_le mult_le1 that)
qed auto

lemma lift_lemma:
  assumes "x \<noteq> 0" "y \<noteq> 0"  shows "\<not> lift (x * y) x \<le> x"
  using assms mult_le1 [of concl: x y]
  by (auto simp: le_TC_def TC_lift less_TC_def less_TC_imp_not_le)

lemma mult_le2:
  fixes y::V assumes "x \<noteq> 0" "y \<noteq> 0" "y \<noteq> 1" shows "x \<sqsubset> x * y"
proof -
  obtain v where v: "v \<in> elts y" "v \<noteq> 0"
    using assms by fastforce
  have "x \<noteq> x * y"
    using lift_lemma [of x v]
    by (metis \<open>x \<noteq> 0\<close> bdd_above_iff_small cSUP_upper2 order_refl replacement small_elts mult v)
  then show ?thesis
  using assms mult_le1 [of y x]
    by (auto simp: le_TC_def)
qed



subsubsection\<open>Theorem 4.6\<close>

theorem mult_eq_imp_0:
  assumes "a*x = a*y + b" "b \<sqsubset> a"
  shows "b=0"
proof (cases "a=0 \<or> x=0")
  case True
  with assms show ?thesis
    by (metis add_le_cancel_left mult_eq_0_iff eq_iff le_0)
next
  case False
  then have "a\<noteq>0" "x\<noteq>0"
    by auto
  then show ?thesis
  proof (cases "y=0")
    case True
    then show ?thesis
      using assms less_asym_TC mult_le2 by force
  next
    case False
    have "b=0" if "Ord \<alpha>" "x \<in> elts (Vset \<alpha>)" "y \<in> elts (Vset \<alpha>)" for \<alpha>
      using that assms
    proof (induction \<alpha> arbitrary: x y b rule: Ord_induct3)
      case 0
      then show ?case by auto
    next
      case (succ k)
      define \<Phi> where "\<Phi> \<equiv> \<lambda>x y. \<exists>r. 0 \<sqsubset> r \<and> r \<sqsubset> a \<and> a*x = a*y + r"
      show ?case
      proof (rule ccontr)
        assume "b \<noteq> 0"
        then have "0 \<sqsubset> b"
          by (metis nonzero_less_TC)
        then have "\<Phi> x y"
          unfolding \<Phi>_def using succ.prems by blast
        then obtain x' where "\<Phi> x' y" "x' \<sqsubseteq> x" and min: "\<And>x''. x'' \<sqsubset> x' \<Longrightarrow> \<not> \<Phi> x'' y"
          using less_TC_minimal [of "\<lambda>x. \<Phi> x y" x] by blast
        then obtain b' where "0 \<sqsubset> b'" "b' \<sqsubset> a" and eq: "a*x' = a*y + b'"
          using \<Phi>_def by blast
        have "a*y \<sqsubset> a*x'"
          using TC_add' \<open>0 \<sqsubset> b'\<close> eq by auto
        then obtain p where "p \<in> elts (a * x')" "a * y \<sqsubseteq> p"
          using less_TC_iff by blast
        then have "p \<notin> elts (a * y)"
          using less_TC_iff less_irrefl_TC by blast
        then have "p \<in> \<Union> (elts ` (\<lambda>v. lift (a * v) a) ` elts x')"
          by (metis \<open>p \<in> elts (a * x')\<close> elts_Sup replacement small_elts mult)
        then obtain u c where "u \<in> elts x'" "c \<in> elts a" "p = a*u + c"
          using lift_def by auto
        then have "p \<in> elts (lift (a*y) b')"
          using \<open>p \<in> elts (a * x')\<close> \<open>p \<notin> elts (a * y)\<close> eq plus_eq_lift by auto
        then obtain d where d: "d \<in> elts b'" "p = a*y + d" "p = a*u + c"
          by (metis \<open>p = a * u + c\<close> \<open>p \<in> elts (a * x')\<close> \<open>p \<notin> elts (a * y)\<close> eq mem_plus_V_E)
        have noteq: "a*y \<noteq> a*u"
        proof
          assume "a*y = a*u"
          then have "lift (a*y) a = lift (a*u) a"
            by metis
          also have "\<dots> \<le> a*x'"
            unfolding mult [of _ x'] using \<open>u \<in> elts x'\<close> by (auto intro: cSUP_upper)
          also have "\<dots> = a*y \<squnion> lift (a*y) b'"
            by (simp add: eq plus_eq_lift)
          finally have "lift (a*y) a \<le> a*y \<squnion> lift (a*y) b'" .
          then have "lift (a*y) a \<le> lift (a*y) b'"
            using add_le_cancel_left less_TC_imp_not_le plus_eq_lift \<open>b' \<sqsubset> a\<close> by auto
          then have "a \<le> b'"
            by (simp add: le_iff_sup lift_eq_lift lift_sup_distrib)
          then show False
            using \<open>b' \<sqsubset> a\<close> less_TC_imp_not_le by auto
        qed
        consider "a*y \<unlhd> a*u" | "a*u \<unlhd> a*y"
          using d comparable vle_comparable_def by auto
        then show False
        proof cases
          case 1
          then obtain e where e: "a*u = a*y + e" "e \<noteq> 0"
            by (metis add.right_neutral noteq vle_def)
          moreover have "e + c = d"
            by (metis e add_right_cancel \<open>p = a * u + c\<close> \<open>p = a * y + d\<close> add.assoc)
          with \<open>d \<in> elts b'\<close> \<open>b' \<sqsubset> a\<close> have "e \<sqsubset> a"
            by (meson less_TC_iff less_TC_trans vle2 vle_def)
          ultimately show False
            \<comment>\<open>contradicts minimality of @{term x'}\<close>
            using min unfolding \<Phi>_def by (meson \<open>u \<in> elts x'\<close> le_TC_def less_TC_iff nonzero_less_TC)
        next
          case 2
          then obtain e where e: "a*y = a*u + e" "e \<noteq> 0"
            by (metis add.right_neutral noteq vle_def)
          moreover have "e + d = c"
            by (metis e add_right_cancel \<open>p = a * u + c\<close> \<open>p = a * y + d\<close> add.assoc)
          with \<open>d \<in> elts b'\<close> \<open>b' \<sqsubset> a\<close> have "e \<sqsubset> a"
            by (metis \<open>c \<in> elts a\<close> less_TC_iff vle2 vle_def)
          ultimately have "\<Phi> y u"
            unfolding \<Phi>_def using nonzero_less_TC by blast
          then obtain y' where "\<Phi> y' u" "y' \<sqsubseteq> y" and min: "\<And>x''. x'' \<sqsubset> y' \<Longrightarrow> \<not> \<Phi> x'' u"
            using less_TC_minimal [of "\<lambda>x. \<Phi> x u" y] by blast
          then obtain b' where "0 \<sqsubset> b'" "b' \<sqsubset> a" and eq: "a*y' = a*u + b'"
            using \<Phi>_def by blast
          have u_k: "u \<in> elts (Vset k)"
            using \<open>u \<in> elts x'\<close> \<open>x' \<sqsubseteq> x\<close> succ Vset_succ_TC less_TC_iff less_le_TC_trans by blast
          have "a*u \<sqsubset> a*y'"
            using TC_add' \<open>0 \<sqsubset> b'\<close> eq by auto
          then obtain p where "p \<in> elts (a * y')" "a * u \<sqsubseteq> p"
            using less_TC_iff by blast
          then have "p \<notin> elts (a * u)"
            using less_TC_iff less_irrefl_TC by blast
          then have "p \<in> \<Union> (elts ` (\<lambda>v. lift (a * v) a) ` elts y')"
            by (metis \<open>p \<in> elts (a * y')\<close> elts_Sup replacement small_elts mult)
          then obtain v c where "v \<in> elts y'" "c \<in> elts a" "p = a*v + c"
            using lift_def by auto
          then have "p \<in> elts (lift (a*u) b')"
            using \<open>p \<in> elts (a * y')\<close> \<open>p \<notin> elts (a * u)\<close> eq plus_eq_lift by auto
          then obtain d where d: "d \<in> elts b'" "p = a*u + d" "p = a*v + c"
            by (metis \<open>p = a * v + c\<close> \<open>p \<in> elts (a * y')\<close> \<open>p \<notin> elts (a * u)\<close> eq mem_plus_V_E)
          have v_k: "v \<in> elts (Vset k)"
            using Vset_succ_TC \<open>v \<in> elts y'\<close> \<open>y' \<sqsubseteq> y\<close> less_TC_iff less_le_TC_trans succ.hyps succ.prems(2) by blast
          have noteq: "a*u \<noteq> a*v"
            proof
              assume "a*u = a*v"
              then have "lift (a*v) a \<le> a*y'"
                unfolding mult [of _ y'] using \<open>v \<in> elts y'\<close> by (auto intro: cSUP_upper)
              also have "\<dots> = a*u \<squnion> lift (a*u) b'"
                by (simp add: eq plus_eq_lift)
              finally have "lift (a*v) a \<le> a*u \<squnion> lift (a*u) b'" .
              then have "lift (a*u) a \<le> lift (a*u) b'"
                by (metis \<open>a * u = a * v\<close> le_iff_sup lift_sup_distrib sup_left_commute sup_lift_eq_lift)
              then have "a \<le> b'"
                by (simp add: le_iff_sup lift_eq_lift lift_sup_distrib)
              then show False
                using \<open>b' \<sqsubset> a\<close> less_TC_imp_not_le by auto
            qed
          consider "a*u \<unlhd> a*v" | "a*v \<unlhd> a*u"
            using d comparable vle_comparable_def by auto
          then show False
          proof cases
            case 1
            then obtain e where e: "a*v = a*u + e" "e \<noteq> 0"
              by (metis add.right_neutral noteq vle_def)
            moreover have "e + c = d"
              by (metis add_right_cancel \<open>p = a * u + d\<close> \<open>p = a * v + c\<close> add.assoc e)
            with \<open>d \<in> elts b'\<close> \<open>b' \<sqsubset> a\<close> have "e \<sqsubset> a"
              by (meson less_TC_iff less_TC_trans vle2 vle_def)
            ultimately show False
              using succ.IH u_k v_k by blast
          next
            case 2
            then obtain e where e: "a*u = a*v + e" "e \<noteq> 0"
              by (metis add.right_neutral noteq vle_def)
            moreover have "e + d = c"
              by (metis add_right_cancel add.assoc d e)
            with \<open>d \<in> elts b'\<close> \<open>b' \<sqsubset> a\<close> have "e \<sqsubset> a"
              by (metis \<open>c \<in> elts a\<close> less_TC_iff vle2 vle_def)
           ultimately show False
             using succ.IH u_k v_k by blast
          qed
        qed
      qed
    next
      case (Limit k)
      obtain i j where k: "i \<in> elts k" "j \<in> elts k"
        and x: "x \<in> elts (Vset i)"
        and y: "y \<in> elts (Vset j)"
        using that Limit by (auto simp: Limit_Vfrom_eq)
      show ?case
      proof (rule Limit.IH [of "i \<squnion> j"])
        show "i \<squnion> j \<in> elts k"
          by (meson k x y Limit.hyps Limit_def Ord_in_Ord Ord_mem_iff_lt Ord_sup union_less_iff)
        show "x \<in> elts (Vset (i \<squnion> j))" "y \<in> elts (Vset (i \<squnion> j))"
          using x y by (auto simp: Vfrom_sup)
      qed (use Limit.prems in auto)
    qed
    then show ?thesis
      by (metis two_in_Vset Ord_rank Ord_VsetI rank_lt)
  qed
qed

subsubsection\<open>Theorem 4.7\<close>

lemma mult_cancellation_half:
  assumes "a*x + r = a*y + s" "r \<sqsubset> a" "s \<sqsubset> a"
  shows "x \<le> y"
proof -
  have "x \<le> y" if "Ord \<alpha>" "x \<in> elts (Vset \<alpha>)" "y \<in> elts (Vset \<alpha>)" for \<alpha>
    using that assms
  proof (induction \<alpha> arbitrary: x y r s rule: Ord_induct3)
    case 0
    then show ?case
      by auto
  next
    case (succ k)
    show ?case
    proof
      fix u
      assume u: "u \<in> elts x"
      have u_k: "u \<in> elts (Vset k)"
        using Vset_succ succ.hyps succ.prems(1) u by auto
      obtain r' where "r' \<in> elts a" "r \<sqsubseteq> r'"
        using less_TC_iff succ.prems(4) by blast
      have "a*u + r' \<in> elts (lift (a*u) a)"
        by (simp add: \<open>r' \<in> elts a\<close> lift_def)
      also have "\<dots> \<le> elts (a*x)"
        using u by (force simp: mult [of _ x])
      also have "\<dots> \<le> elts (a*y + s)"
        by (metis less_eq_V_def plus_eq_lift succ.prems(3) sup_ge1)
      also have "\<dots> = elts (a*y) \<union> elts (lift (a*y) s)"
        by (simp add: plus_eq_lift)
      finally have "a * u + r' \<in> elts (a * y) \<union> elts (lift (a * y) s)" .
      then show "u \<in> elts y"
      proof
        assume *: "a * u + r' \<in> elts (a * y)"
        show "u \<in> elts y"
        proof -
          obtain v e where v: "v \<in> elts y" "e \<in> elts a" "a * u + r' = a * v + e"
            using * by (auto simp: mult [of _ y] lift_def)
          then have v_k: "v \<in> elts (Vset k)"
            using Vset_succ_TC less_TC_iff succ.prems(2) by blast
          then have "u = v"
            by (metis succ.IH u_k V_equalityI \<open>r' \<in> elts a\<close> le_TC_refl less_TC_iff v(2) v(3) vsubsetD)
          then show ?thesis
            using \<open>v \<in> elts y\<close> by blast
        qed
      next
        assume "a * u + r' \<in> elts (lift (a * y) s)"
        then obtain t where "t \<in> elts s" and t: "a * u + r' = a * y + t"
          using lift_def by auto
        have noteq: "a*y \<noteq> a*u"
        proof
          assume "a*y = a*u"
          then have "lift (a*y) a = lift (a*u) a"
            by metis
          also have "\<dots> \<le> a*x"
            unfolding mult [of _ x] using \<open>u \<in> elts x\<close> by (auto intro: cSUP_upper)
          also have "\<dots> \<le> a*y \<squnion> lift (a*y) s"
            using \<open>elts (a * x) \<subseteq> elts (a * y + s)\<close> plus_eq_lift by auto
          finally have "lift (a*y) a \<le> a*y \<squnion> lift (a*y) s" .
          then have "lift (a*y) a \<le> lift (a*y) s"
            using add_le_cancel_left less_TC_imp_not_le plus_eq_lift \<open>s \<sqsubset> a\<close> by auto
          then have "a \<le> s"
            by (simp add: le_iff_sup lift_eq_lift lift_sup_distrib)
          then show False
            using \<open>s \<sqsubset> a\<close> less_TC_imp_not_le by auto
        qed
        consider "a * u \<unlhd> a * y" | "a * y \<unlhd> a * u"
          using t comparable vle_comparable_def by blast
        then have "False"
        proof cases
          case 1
          then obtain c where "a*y = a*u + c"
            by (metis vle_def)
          then have "c+t = r'"
            by (metis add_right_cancel add.assoc t)
          then have "c \<sqsubset> a"
            using \<open>r' \<in> elts a\<close> less_TC_iff vle2 vle_def by force
          moreover have "c \<noteq> 0"
            using \<open>a * y = a * u + c\<close> noteq by auto
          ultimately show ?thesis
            using \<open>a * y = a * u + c\<close> mult_eq_imp_0 by blast
        next
          case 2
          then obtain c where "a*u = a*y + c"
            by (metis vle_def)
          then have "c+r' = t"
            by (metis add_right_cancel add.assoc t)
          then have "c \<sqsubset> a"
            by (metis \<open>t \<in> elts s\<close> less_TC_iff less_TC_trans \<open>s \<sqsubset> a\<close> vle2 vle_def)
          moreover have "c \<noteq> 0"
            using \<open>a * u = a * y + c\<close> noteq by auto
          ultimately show ?thesis
            using \<open>a * u = a * y + c\<close> mult_eq_imp_0 by blast
        qed
        then show "u \<in> elts y" ..
      qed
    qed
  next
    case (Limit k)
    obtain i j where k: "i \<in> elts k" "j \<in> elts k"
      and x: "x \<in> elts (Vset i)" and y: "y \<in> elts (Vset j)"
      using that Limit by (auto simp: Limit_Vfrom_eq)
    show ?case
    proof (rule Limit.IH [of "i \<squnion> j"])
      show "i \<squnion> j \<in> elts k"
        by (meson k x y Limit.hyps Limit_def Ord_in_Ord Ord_mem_iff_lt Ord_sup union_less_iff)
      show "x \<in> elts (Vset (i \<squnion> j))" "y \<in> elts (Vset (i \<squnion> j))"
        using x y by (auto simp: Vfrom_sup)
      thm Limit.prems
    qed (auto intro: Limit.prems)
  qed
  then show ?thesis
    by (metis two_in_Vset Ord_rank Ord_VsetI rank_lt)
qed


theorem mult_cancellation_lemma:
  assumes "a*x + r = a*y + s" "r \<sqsubset> a" "s \<sqsubset> a"
  shows "x=y \<and> r=s"
  by (metis add_right_cancel mult_cancellation_half antisym assms)

corollary mult_cancellation [simp]:
  fixes a::V
  assumes "a \<noteq> 0"
  shows "a*x = a*y \<longleftrightarrow> x=y"
  by (metis assms nonzero_less_TC mult_cancellation_lemma)

corollary lift_mult_TC_disjoint:
  fixes x::V
  assumes "x \<noteq> y"
  shows "lift (a*x) (TC a) \<sqinter> lift (a*y) (TC a) = 0"
  apply (rule V_equalityI)
  using assms
  by (force simp: less_TC_def inf_V_def zero_V_def lift_def image_iff dest: mult_cancellation_lemma)

corollary lift_mult_disjoint:
  fixes x::V
  assumes "x \<noteq> y"
  shows "lift (a*x) a \<sqinter> lift (a*y) a = 0"
proof -
  have "lift (a*x) a \<sqinter> lift (a*y) a \<le> lift (a*x) (TC a) \<sqinter> lift (a*y) (TC a)"
    by (metis TC' inf_mono lift_sup_distrib sup_ge1)
  then show ?thesis
    using assms lift_mult_TC_disjoint by auto
qed

lemma mult_add_mem:
  assumes "a*x + r \<in> elts (a*y)" "r \<sqsubset> a"
  shows "x \<in> elts y" "r \<in> elts a"
proof -
  obtain v s where v: "a * x + r = a * v + s" "v \<in> elts y" "s \<in> elts a"
    using assms unfolding mult [of a y] lift_def by auto
  then show "x \<in> elts y"
    by (metis arg_subset_TC assms(2) less_TC_def mult_cancellation_lemma vsubsetD)
  show "r \<in> elts a"
    by (metis arg_subset_TC assms(2) less_TC_def mult_cancellation_lemma v(1) v(3) vsubsetD)
qed

lemma mult_add_mem_0: "a*x \<in> elts (a*y) \<longleftrightarrow> x \<in> elts y \<and> 0 \<in> elts a"
  proof -
  have "x \<in> elts y"
    if "a * x \<in> elts (a * y) \<and> 0 \<in> elts a"
    using that   using mult_add_mem [of a x 0]
    using nonzero_less_TC by force
  moreover have "a * x \<in> elts (a * y)"
    if "x \<in> elts y" "0 \<in> elts a"
    using that  by (force simp: image_iff mult [of a y] lift_def)
  ultimately show ?thesis
    by (metis mult_eq_0_iff add.right_neutral mult_add_mem(2) nonzero_less_TC)
qed


lemma vcard_mult: "vcard (x * y) = vcard x \<otimes> vcard y"
proof -
  have 1: "elts (lift (x * u) x) \<approx> elts x" if "u \<in> elts y" for u
    by (metis cardinal_eqpoll eqpoll_sym eqpoll_trans card_lift)
  have 2: "pairwise (\<lambda>u u'. disjnt (elts (lift (x * u) x)) (elts (lift (x * u') x)))  (elts y)"
    by (simp add: pairwise_def disjnt_def) (metis V_disjoint_iff lift_mult_disjoint)
  have "x * y = (SUP u\<in>elts y. lift (x * u) x)"
    using mult by blast
  then have "elts (x * y) \<approx> (\<Union>u\<in>elts y. elts (lift (x * u) x))"
    by simp
  also have "\<dots> \<approx> elts y \<times> elts x"
    using Union_eqpoll_Times [OF 1 2] .
  also have "\<dots> \<approx> elts x \<times> elts y"
    by (simp add: times_commute_eqpoll)
  also have "\<dots> \<approx> elts (vcard x) \<times> elts (vcard y)"
    using cardinal_eqpoll eqpoll_sym times_eqpoll_cong by blast
  also have "\<dots> \<approx> elts (vcard x \<otimes> vcard y)"
    by (simp add: cmult_def elts_vcard_VSigma_eqpoll eqpoll_sym)
  finally have "elts (x * y) \<approx> elts (vcard x \<otimes> vcard y)" .
  then show ?thesis
    by (metis cadd_cmult_distrib cadd_def cardinal_cong cardinal_idem vsum_0_eqpoll)
qed

proposition TC_mult: "TC(x * y) = (SUP r \<in> elts (TC x). SUP u \<in> elts (TC y). set{x * u + r})"
proof (cases "x = 0")
  case False
  have *: "TC(x * y) = (SUP u \<in> elts (TC y). lift (x * u) (TC x))" for y
  proof (induction y rule: eps_induct)
    case (step y)
    have "TC(x * y) = (SUP u \<in> elts y. TC (lift (x * u) x))"
      by (simp add: mult [of x y] TC_Sup_distrib image_image)
    also have "\<dots> = (SUP u \<in> elts y. TC(x * u) \<squnion> lift (x * u) (TC x))"
      by (simp add: TC_lift False)
    also have "\<dots> = (SUP u \<in> elts y. (SUP z \<in> elts (TC u). lift (x * z) (TC x)) \<squnion> lift (x * u) (TC x))"
      by (simp add: step)
    also have "\<dots> = (SUP u \<in> elts (TC y). lift (x * u) (TC x))"
      by (auto simp: TC' [of y] image_Un Sup_Un_distrib TC_Sup_distrib cSUP_UNION SUP_sup_distrib)
    finally show ?case .
  qed
  show ?thesis
    by (force simp: * lift_def)
qed auto


corollary vcard_TC_mult: "vcard (TC(x * y)) = vcard (TC x) \<otimes> vcard (TC y)"
proof -
  have "(\<Union>u\<in>elts (TC x). \<Union>v\<in>elts (TC y). {x * v + u}) = (\<Union>u\<in>elts (TC x). (\<lambda>v. x * v + u) ` elts (TC y))"
    by (simp add: UNION_singleton_eq_range)
  also have "\<dots> \<approx> (\<Union>x\<in>elts (TC x). elts (lift (TC y * x) (TC y)))"
  proof (rule UN_eqpoll_UN)
    show "(\<lambda>v. x * v + u) ` elts (TC y) \<approx> elts (lift (TC y * u) (TC y))"
      if "u \<in> elts (TC x)" for u
    proof -
      have "inj_on (\<lambda>v. x * v + u) (elts (TC y))"
        by (meson inj_onI less_TC_def mult_cancellation_lemma that)
      then have "(\<lambda>v. x * v + u) ` elts (TC y) \<approx> elts (TC y)"
        by (rule inj_on_image_eqpoll_self)
      also have "\<dots> \<approx> elts (lift (TC y * u) (TC y))"
        by (simp add: eqpoll_lift eqpoll_sym)
      finally show ?thesis .
    qed
    show "pairwise (\<lambda>u ya. disjnt ((\<lambda>v. x * v + u) ` elts (TC y)) ((\<lambda>v. x * v + ya) ` elts (TC y))) (elts (TC x))"
      apply (auto simp: pairwise_def disjnt_def)
      using less_TC_def mult_cancellation_lemma by blast
    show "pairwise (\<lambda>u ya. disjnt (elts (lift (TC y * u) (TC y))) (elts (lift (TC y * ya) (TC y)))) (elts (TC x))"
      apply (auto simp: pairwise_def disjnt_def)
      by (metis Int_iff V_disjoint_iff empty_iff lift_mult_disjoint)
  qed
  also have "\<dots> = elts (TC y * TC x)"
    by (metis elts_Sup image_image mult replacement small_elts)
  finally have "(\<Union>u\<in>elts (TC x). \<Union>v\<in>elts (TC y). {x * v + u}) \<approx> elts (TC y * TC x)" .
  then show ?thesis
    apply (subst cmult_commute)
    by (simp add: TC_mult cardinal_cong flip: vcard_mult)
qed

end
