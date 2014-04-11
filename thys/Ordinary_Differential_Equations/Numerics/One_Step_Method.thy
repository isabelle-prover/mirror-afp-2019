header{* One-Step Methods *}
theory One_Step_Method
imports
  "../IVP/Initial_Value_Problem"
begin

text{*\label{sec:osm}*}

subsection{* Grids *}
text{*\label{sec:osm-grid}*}

locale grid =
  fixes t::"nat \<Rightarrow> real"
  assumes steps: "\<And>i. t i \<le> t (Suc i)"
begin

lemmas grid = steps

lemma grid_ge_min:
  shows "t 0 \<le> t j"
  using assms
proof (induct j)
  fix j
  assume "t 0 \<le> t j"
  also from grid have "t j \<le> t (Suc j)" .
  finally show "t 0 \<le> t (Suc j)" .
qed simp

lemma grid_mono:
  assumes "j \<le> n"
  shows "t j \<le> t n"
using assms
proof (induct rule: inc_induct)
  fix j
  assume "j < n" "t (Suc j) \<le> t n"
  moreover
  with grid have "t j \<le> t (Suc j)" by auto
  ultimately
  show "t j \<le> t n" by simp
qed simp

text {* The size of the step from point j to j+1 in grid t *}

definition stepsize
where "stepsize j = t (Suc j) - t j"

lemma grid_stepsize_nonneg:
  shows "stepsize j \<ge> 0"
  using assms grid unfolding stepsize_def
  by (simp add: field_simps order_less_imp_le)

lemma grid_stepsize_sum:
  shows "(\<Sum>i\<in>{0..<n}. stepsize i) = t n - t 0"
  by (induct n) (simp_all add: stepsize_def)

definition max_stepsize
where "max_stepsize n = Max (stepsize ` {0..n})"

lemma max_stepsize_ge_stepsize:
  assumes "j \<le> n"
  shows "max_stepsize n \<ge> stepsize j"
  using assms by (auto simp: max_stepsize_def)

lemma max_stepsize_nonneg:
  shows "max_stepsize n \<ge> 0"
  using grid_stepsize_nonneg[of 0]
    max_stepsize_ge_stepsize[of 0 n]
  by simp

lemma max_stepsize_mono:
  assumes "j \<le> n"
  shows "max_stepsize j \<le> max_stepsize n"
  using assms by (auto intro!: Max_mono simp: max_stepsize_def)

definition min_stepsize
where "min_stepsize n = Min (stepsize ` {0..n})"

lemma min_stepsize_le_stepsize:
  assumes "j \<le> n"
  shows "min_stepsize n \<le> stepsize j"
  using grid assms
  by (auto simp add: min_stepsize_def)

end

lemma (in grid) grid_interval_notempty: "t 0 \<le> t n" using grid_ge_min[of n] .

subsection{* Definition *}
text{*\label{sec:osm-definition}*}

text{* Discrete evolution (noted @{text \<Psi>}) using incrementing function @{term incr} *}

definition discrete_evolution
where "discrete_evolution incr t1 t0 x = x + (t1 - t0) *\<^sub>R incr (t1 - t0) t0 x"

text {* Using the discrete evolution @{text \<Psi>} between each two points of the
  grid, define a function over the whole grid *}

fun grid_function
where
  "grid_function \<Psi> x0 t 0 = x0"
| "grid_function \<Psi> x0 t (Suc j) = \<Psi> (t (Suc j)) (t j) (grid_function \<Psi> x0 t j)"


subsection {* Consistency *}
text{*\label{sec:osm-consistent}*}

definition "consistent x t T B p incr \<longleftrightarrow>
  (\<forall>h\<ge>0. t + h \<le> T \<longrightarrow> dist (x (t + h)) (discrete_evolution incr (t + h) t (x t)) \<le> B * h ^ (p + 1))"

lemma consistentD:
  assumes "consistent x t T B p incr"
  assumes "h \<ge> 0" "t + h \<le> T"
  shows "dist (x (t + h)) (discrete_evolution incr (t + h) t (x t)) \<le> B * h ^ (p + 1)"
  using assms
  unfolding consistent_def by auto

lemma consistentI[intro]:
  fixes x::"real\<Rightarrow>'a::real_normed_vector"
  assumes "\<And>h. h > 0 \<Longrightarrow> t + h \<le> T \<Longrightarrow>
    dist (x (t + h)) (discrete_evolution incr (t + h) t (x t)) \<le> B * h ^ (p + 1)"
  shows "consistent x t T B p incr"
  using assms unfolding consistent_def
  by safe (case_tac "h = 0", auto simp: discrete_evolution_def)

lemma consistent_imp_nonneg_constant:
  assumes "consistent x t T B p incr"
  assumes "t < T"
  shows "B \<ge> 0"
proof -
  from assms have "T - t > 0" by simp
  have "0 \<le> dist (x T) (discrete_evolution incr T t (x t))" by simp
  also from assms
  have "... \<le> B * (T - t) ^ (p + 1)"
    unfolding consistent_def by (auto dest: spec[where x="T - t"])
  finally show ?thesis using zero_less_power[OF `T - t > 0`, of "p+1"]
    by (simp add: zero_le_mult_iff)
qed

lemma stepsize_inverse:
  assumes "L \<ge> 0" "h \<ge> 0" "B \<ge> 0" "r \<ge> 0" "p > 0" "T1 \<ge> T2" "T2 \<ge> 0"
  assumes max_step: "h \<le> root p (r * L / B / (exp (L * T1 + 1) - 1))"
  shows  "B / L * (exp (L * T2 + 1) - 1) * h ^ p \<le> r"
proof -
  { assume "L = 0" hence ?thesis using `r \<ge> 0` by simp
  } moreover {
    assume B_pos: "B > 0" assume "L > 0"
    from `0 \<le> T2` `T1 \<ge> T2` have "T1 \<ge> 0" by simp
    hence eg: "(exp (L * T1 + 1) - 1) > 0" using `L > 0`
      by (auto intro!: add_nonneg_pos simp add: diff_less_iff)
    have "B * (h ^ p * (exp (L * T2 + 1) - 1)) / L \<le>
      B * (root p (r * L / B / (exp (L * T1 + 1) - 1)) ^ p
      * (exp (L * T2 + 1) - 1)) / L"
      using assms
      by (auto simp add: ge_iff_diff_ge_0[symmetric]
        intro!: divide_right_mono mult_left_mono mult_right_mono add_nonneg_nonneg
        power_mono)
    also
    have "root p (r * L / B / (exp (L * T1 + 1) - 1)) ^ p =
      (r * L / B / (exp (L * T1 + 1) - 1))"
      using assms B_pos `T1 \<ge> 0` `L > 0` `B > 0`
      by (subst real_root_pow_pos2[OF `p > 0`]) (auto simp add: diff_less_iff
        intro!: divide_nonneg_pos add_nonneg_pos mult_pos_pos)
    finally
    have "B * (h ^ p * (exp (L * T2 + 1) - 1)) / L \<le>
      r * ((exp (L * T2 + 1) - 1) / (exp (L * T1 + 1) - 1))"
      using B_pos `L > 0` eg `r \<ge> 0`
      by (simp add: ac_simps)
    also have "... \<le> r" using `T1 \<ge> T2` `0 \<le> T2`
    proof (cases "T1 = 0")
      assume "T1 \<noteq> 0" with `T1 \<ge> T2` `0 \<le> T2` have "T1 > 0" by simp
      show ?thesis using `L > 0` `0 \<le> T2` `T1 \<ge> 0` add_0_left `T1 > 0` `T1 \<ge> T2`
        by (intro mult_right_le_one_le `r \<ge> 0`)
      (subst pos_le_divide_eq pos_divide_le_eq,
        auto simp add: diff_le_iff diff_less_iff
        intro!: add_pos_pos mult_pos_pos)+
    qed simp
    finally have ?thesis by (simp add: ac_simps)
  } moreover {
    assume "\<not>0<B" hence "B = 0" using `B \<ge> 0` by simp
    hence ?thesis using `r \<ge> 0` by simp
  } ultimately show ?thesis using assms by arith
qed

subsection {* Accumulation of errors *}

text {* The concept of accumulating errors applies to convergence and stability. *}

lemma (in grid) error_accumulation:
  fixes x::"(nat \<Rightarrow> real) \<Rightarrow> nat \<Rightarrow> 'a::euclidean_space"
  assumes max_step: "max_stepsize j \<le>
    root p (\<bar>r\<bar> * L / B / (exp (L * (T - t 0) + 1) - 1))"
  defines "K \<equiv> {(s, y). \<exists>i \<le> j. s = t i \<and> y \<in> cball (x t i) r}"
  assumes "p > 0"
  assumes lipschitz: "\<And>j. t (Suc j) \<le> T \<Longrightarrow>
  dist (x t j) (grid_function (discrete_evolution \<psi>) x0 t j) \<le> \<bar>r\<bar> \<Longrightarrow>
  dist (\<psi> (stepsize j) (t j) (x t j))
     (\<psi> (stepsize j) (t j) (grid_function (discrete_evolution \<psi>) x0 t j))
    \<le> L * dist (x t j) (grid_function (discrete_evolution \<psi>) x0 t j)" and "L \<ge> 0"
  assumes consistence_error: "\<And>j. t (Suc j) \<le> T \<Longrightarrow>
    dist (x t (Suc j)) (discrete_evolution \<psi> (t (Suc j)) (t j) (x t j)) \<le>
    B * stepsize j ^ (p + 1)" and "B \<ge> 0"
  assumes initial_error: "dist (x t 0) x0 \<le>
    B * (exp 1 - 1) * stepsize 0 ^ p / L"
  assumes "t j \<le> T"
  shows "dist (x t j) (grid_function (discrete_evolution \<psi>) x0 t j) \<le>
    B / L * (exp (L * (t j - t 0) + 1) - 1) * max_stepsize j ^ p"
using `t j \<le> T` max_step
proof (induct j)
  case 0 note initial_error
  also have "B * (exp 1 - 1) * stepsize 0 ^ p / L \<le>
    B * (exp 1 - 1) * max_stepsize 0 ^ p / L"
    using grid_stepsize_nonneg `B\<ge>0` `L\<ge>0`
    by (auto intro!: max_stepsize_ge_stepsize
      power_mono mult_left_mono divide_right_mono
      simp: diff_le_iff) 
  finally show ?case by simp
next
  case (Suc j)
  have "t 0 \<le> T"
    using Suc grid_interval_notempty[of "Suc j"] by auto
  from Suc have j_in:"t j \<le> T" using grid_mono[of j "Suc j"] by simp
  moreover
  have "max_stepsize j \<le> max_stepsize (Suc j)"
    by (simp add: max_stepsize_mono)
  with Suc have IH1: "max_stepsize j \<le>
    root p (\<bar>r\<bar> * L / B / (exp (L * (T - t 0) + 1) - 1))" by simp
  ultimately have
    IH2: "dist (x t j) (grid_function (discrete_evolution \<psi>) x0 t j)
     \<le> B / L * (exp (L * (t j - t 0) + 1) - 1) * max_stepsize j ^ p"
    by (rule Suc(1))
  have "dist (x t (Suc j)) (grid_function (discrete_evolution \<psi>) x0 t (Suc j)) =
    norm (x t (Suc j) -
    (discrete_evolution \<psi>) (t (Suc j)) (t j) (x t j) +
    ((discrete_evolution \<psi>) (t (Suc j)) (t j) (x t j) -
    (discrete_evolution \<psi>) (t (Suc j)) (t j) (grid_function (discrete_evolution \<psi>) x0 t j)))"
    by (simp add: field_simps dist_norm)
  also have "... \<le> norm (x t (Suc j) -
    (discrete_evolution \<psi>) (t (Suc j)) (t j) (x t j)) +
    norm (((discrete_evolution \<psi>) (t (Suc j)) (t j) (x t j) -
    (discrete_evolution \<psi>) (t (Suc j)) (t j) (grid_function (discrete_evolution \<psi>) x0 t j)))"
    (is "_ \<le> _ + ?ej") 
    by (rule norm_triangle_ineq)
  also have "?ej =
    norm (x t j - grid_function (discrete_evolution \<psi>) x0 t j + stepsize j *\<^sub>R
    (\<psi> (stepsize j) (t j) (x t j) -
    \<psi> (stepsize j) (t j) (grid_function (discrete_evolution \<psi>) x0 t j)))"
    by (simp add: discrete_evolution_def stepsize_def algebra_simps)
  also have "... \<le>
    norm (x t j - grid_function (discrete_evolution \<psi>) x0 t j) + norm (stepsize j *\<^sub>R
    (\<psi> (stepsize j) (t j) (x t j) -
    \<psi> (stepsize j) (t j) (grid_function (discrete_evolution \<psi>) x0 t j)))"
    by (rule norm_triangle_ineq)
  also have "... = norm (x t j - grid_function (discrete_evolution \<psi>) x0 t j) +
    stepsize j *
    dist (\<psi> (stepsize j) (t j) (x t j))
    (\<psi> (stepsize j) (t j) (grid_function (discrete_evolution \<psi>) x0 t j))"
    (is "_ = _ + _ * ?dj")
    using grid_stepsize_nonneg
    by (simp add: dist_norm)
  also
  have "?dj \<le> L * dist (x t j) (grid_function (discrete_evolution \<psi>) x0 t j)"
  proof (intro lipschitz(1))
    from IH2 have
      "dist (x t j) (grid_function (discrete_evolution \<psi>) x0 t j)
      \<le> B / L * (exp (L * (t j - t 0) + 1) - 1) * max_stepsize j ^ p"
      by (simp add: ac_simps)
    also have "... \<le>
      B / L * (exp (L * (T - t 0) + 1) - 1) * max_stepsize j ^ p"
      using `L\<ge>0` `B\<ge>0` `t j \<le> T` max_stepsize_nonneg
      by (auto intro!: mult_left_mono mult_right_mono divide_right_mono)
    also have "... \<le> \<bar>r\<bar>"
      using `B \<ge> 0` max_step max_stepsize_nonneg `L \<ge> 0` `p > 0`
        grid_ge_min using grid_mono[of 0 j] `t 0 \<le> T` IH1
      by (intro stepsize_inverse) auto
    finally show
      "dist (x t j) (grid_function (discrete_evolution \<psi>) x0 t j) \<le> \<bar>r\<bar>" .
  qed (insert Suc, simp)
  finally
  have "dist (x t (Suc j)) (grid_function (discrete_evolution \<psi>) x0 t (Suc j))
    \<le> norm (x t (Suc j) - (discrete_evolution \<psi>) (t (Suc j)) (t j) (x t j)) +
    (1 + stepsize j * L) *
      dist (x t j) (grid_function (discrete_evolution \<psi>) x0 t j)"
    using grid_stepsize_nonneg
    by (auto simp: algebra_simps mult_right_mono dist_norm)
  also
  have "norm (x t (Suc j) - (discrete_evolution \<psi>) (t (Suc j)) (t j) (x t j)) \<le>
    B * stepsize j ^ (p + 1)"
    using consistence_error[OF `t (Suc j) \<le> T`] by (simp add: dist_norm)
  finally have rec:
    "dist (x t (Suc j)) (grid_function (discrete_evolution \<psi>) x0 t (Suc j))
      \<le> B * stepsize j ^ (p + 1) +
        (1 + stepsize j * L) *
        dist (x t j) (grid_function (discrete_evolution \<psi>) x0 t j)"
    by simp
  also have "... \<le> B * stepsize j ^ (p + 1) +
    (1 + stepsize j * L) * (B / L * (exp (L * (t j - t 0) + 1) - 1) * max_stepsize j ^ p)"
    using `B \<ge> 0` IH1 IH2 `t (Suc j) \<le> T` `0\<le>L` grid_stepsize_nonneg
    by (intro add_mono mult_left_mono) auto
  finally
  have "dist (x t (Suc j)) (grid_function (discrete_evolution \<psi>) x0 t (Suc j))
    \<le> B * stepsize j ^ (p + 1) +
    (1 + stepsize j * L) * (B / L * (exp (L * (t j - t 0) + 1) - 1) *
      max_stepsize j ^ p)" .
  also have "... \<le> B * stepsize j * max_stepsize j ^ p +
    (1 + stepsize j * L) *
    (B / L * (exp (L * (t j - t 0) + 1) - 1) * max_stepsize j ^ p)"
    using grid_stepsize_nonneg `B \<ge> 0` grid
    by (auto intro!: mult_left_mono power_mono
      simp add: max_stepsize_def field_simps)
  also have "... = max_stepsize j ^ p * B / L * (1 + stepsize j * L) *
      (exp (L * (t j - t 0) + 1))
    - max_stepsize j ^ p * B / L"
    using `B \<ge> 0` grid_stepsize_nonneg `p > 0` `L\<ge>0`
    apply (cases "L \<noteq> 0")
     apply (simp add: field_simps)
    apply (cases "max_stepsize j = 0")
     apply simp
    by (metis IH1 abs_not_less_zero abs_of_pos divide_zero_left less_eq_real_def max_stepsize_nonneg
      mult_zero_right real_root_zero)
  also
  have "B * (max_stepsize j ^ p * (exp (L * (t j - t 0) + 1) *
    (1 + L * (t (Suc j) - t j)))) / L
    \<le> B * (max_stepsize j ^ p * exp (L * (t (Suc j) - t 0) + 1)) / L"
    using `L \<ge> 0` `B \<ge> 0` max_stepsize_nonneg
  proof (intro divide_right_mono mult_left_mono)
    have "exp (L * (t j - t 0) + 1) * (1 + L * (t (Suc j) - t j)) \<le>
      exp (L * (t j - t 0) + 1) * exp (stepsize j * L)"
      unfolding stepsize_def[symmetric] by (auto simp add: ac_simps)
    also have "... \<le> exp (L * (t (Suc j) - t 0) + 1)"
      by (simp add: mult_exp_exp stepsize_def algebra_simps)
    finally
    show "exp (L * (t j - t 0) + 1) * (1 + L * (t (Suc j) - t j)) \<le>
      exp (L * (t (Suc j) - t 0) + 1)" .
  qed simp_all
  hence "max_stepsize j ^ p * B / L * (1 + stepsize j * L) *
    exp (L * (t j - t 0) + 1) \<le>
    max_stepsize j ^ p * B / L * exp (L * (t (Suc j) - t 0) + 1)"
    by (simp add: stepsize_def ac_simps)
  finally
  have "dist (x t (Suc j)) (grid_function (discrete_evolution \<psi>) x0 t (Suc j))
    \<le> B / L * (exp (L * (t (Suc j) - t 0) + 1) - 1) *
    max_stepsize j ^ p" by (simp add: field_simps)
  also have "... \<le> B / L * (exp (L * (t (Suc j) - t 0) + 1) - 1) *
    max_stepsize (Suc j) ^ p"
    using `B\<ge>0``L\<ge>0` max_stepsize_nonneg
    by (intro mult_left_mono power_mono max_stepsize_mono) (auto
      simp: diff_le_iff intro!: divide_nonneg_nonneg mult_nonneg_nonneg
      add_nonneg_nonneg grid_mono)
  finally show ?case .
qed

subsection {* Consistency of order p implies convergence of order p *}
text{*\label{sec:osm-cons-imp-conv}*}

locale consistent_one_step =
  fixes t0 t1 and x::"real \<Rightarrow> 'a::ordered_euclidean_space" and incr p B r L
  assumes order_pos: "p > 0"
  assumes consistent_nonneg: "B \<ge> 0"
  assumes consistent: "\<And>s. s \<in> {t0..t1} \<Longrightarrow> consistent x s t1 B p incr"
  assumes lipschitz_nonneg: "L \<ge> 0"
  assumes lipschitz_incr: "\<And>s h. s \<in> {t0..t1} \<Longrightarrow> h \<in> {0..t1 - s} \<Longrightarrow>
    lipschitz (cball (x s) \<bar>r\<bar>) (\<lambda>x. incr h s x) L"

locale max_step = grid +
  fixes t1 p L B r
  assumes max_step: "\<And>j. t j \<le> t1 \<Longrightarrow> max_stepsize j \<le>
    root p (\<bar>r\<bar> * L / B / (exp (L * (t1 - t 0) + 1) - 1))"
begin

lemma max_step_mono_r:
  assumes "\<bar>s\<bar> \<ge> \<bar>r\<bar>" "L \<ge> 0" "B \<ge> 0" "t1 \<ge> t 0" "0 < p" "t j \<le> t1"
  shows "max_stepsize j \<le>
    root p (\<bar>s\<bar> * L / B / (exp (L * (t1 - t 0) + 1) - 1))"
proof -
  from max_step `t j \<le> t1` have "max_stepsize j \<le>
    root p (\<bar>r\<bar> * L / B / (exp (L * (t1 - t 0) + 1) - 1))" .
  also
  have "... \<le> root p (\<bar>s\<bar> * L / B / (exp (L * (t1 - t 0) + 1) - 1))"
    using assms
    apply (cases "B = 0", simp)
    apply (cases "L = 0", simp)
    by (auto simp add: mult_le_cancel_left1 diff_le_iff
      intro!: divide_right_mono add_increasing mult_left_mono
      mult_pos_pos)
  finally
  show "max_stepsize j \<le> root p (\<bar>s\<bar> * L / B / (exp (L * (t1 - t 0) + 1) - 1))" .
qed

end

locale convergent_one_step = consistent_one_step + max_step +
  assumes grid_from: "t0 = t 0"
begin

lemma (in convergent_one_step) convergence:
  assumes "t j \<le> t1"
  shows "dist (x (t j)) (grid_function (discrete_evolution incr) (x (t 0)) t j) \<le>
        B / L * (exp (L * (t1 - t 0) + 1) - 1) * max_stepsize j ^ p"
proof -
  from order_pos consistent_nonneg lipschitz_nonneg
  have "p > 0" "B \<ge> 0" "L \<ge> 0" by simp_all
  {
    fix j::nat assume "t (Suc j) \<le> t1"
    from consistent have "dist (x (t j + stepsize j))
      (discrete_evolution incr (t j + stepsize j) (t j) (x (t j)))
      \<le> B * (stepsize j ^ (p + 1))"
      apply (rule consistentD)
      using `t (Suc j) \<le> t1` grid_mono[of j "Suc j"] grid_stepsize_nonneg
      by (auto intro: grid_mono simp: stepsize_def grid_from)
  } note consistence_error = this
  {
    fix j::nat
    assume "t (Suc j) \<le> t1"
    assume in_K:
      "dist (x (t j)) (grid_function (discrete_evolution incr) (x (t 0)) t j) \<le> \<bar>r\<bar>"
    hence "stepsize j \<in> {0..t1 - t j}"
      using grid_stepsize_nonneg grid_mono `t (Suc j) \<le> t1`
      by (simp add: stepsize_def diff_le_iff)
    moreover
    have "t j \<in> {t 0..t1}" using grid[of j] `t (Suc j) \<le> t1`
      grid_mono[of j "Suc j"] grid_ge_min by simp
    moreover
    hence "x (t j) \<in> cball (x (t j)) \<bar>r\<bar>" by simp
    moreover
    hence  "grid_function (discrete_evolution incr) (x (t 0)) t j \<in>
      cball (x (t j)) \<bar>r\<bar>" using in_K by simp
    ultimately
    have "dist (incr (stepsize j) (t j) (x (t j)))
      (incr (stepsize j) (t j)
      (grid_function (discrete_evolution incr) (x (t 0)) t j))
      \<le> L *
      dist (x (t j))
      (grid_function (discrete_evolution incr) (x (t 0)) t j)"
      using lipschitz_incr grid_from
      unfolding lipschitz_def
      by blast
  } note lipschitz_grid = this
  have
    "dist (x (t j)) (grid_function (discrete_evolution incr) (x (t 0)) t j) \<le>
    (B / L * (exp (L * (t j - t 0) + 1) - 1)) * max_stepsize j ^ p"
    using `p > 0` `L \<ge> 0` `B \<ge> 0` `t j \<le> t1`
      max_stepsize_nonneg
      consistence_error lipschitz_grid
    by (intro error_accumulation[OF max_step]) (auto intro!:
      divide_nonneg_nonneg mult_nonneg_nonneg zero_le_power grid_mono
      simp add: lipschitz_def diff_le_iff stepsize_def)
  also have "... \<le>
    (B / L * (exp (L * (t1 - t 0) + 1) - 1)) * max_stepsize j ^ p"
    using `t j \<le> t1` `0\<le>L` `0\<le>B` max_stepsize_nonneg
    by (auto intro!: divide_right_mono mult_right_mono mult_left_mono)
  finally show ?thesis by simp
qed

end

subsection{* Stability *}
text{*\label{sec:osm-stability}*}

locale disturbed_one_step = grid +
  fixes t1 s s0 x incr p B L
  assumes initial_error: "norm s0 \<le> B / L * (exp 1 - 1) * stepsize 0 ^ p"
  assumes error: "\<And>j. t (Suc j) \<le> t1 \<Longrightarrow>
  norm (s (stepsize j) (t j)
  (grid_function (discrete_evolution (\<lambda>h t x. incr h t x + s h t x))
    (x (t 0) + s0) t j)) \<le> B * stepsize j ^ p"

locale stable_one_step =
  consistent_one_step "t 0" + disturbed_one_step +
  max_step t t1 p L B "r / 2"
begin

lemma t0_le: "t i \<le> t1 \<Longrightarrow> t 0 \<le> t1"
  by (metis grid_interval_notempty order.trans)

lemma max_step_r:
  assumes "t j \<le> t1"
  shows "max_stepsize j \<le> root p (\<bar>r\<bar> * L / B / (exp (L * (t1 - t 0) + 1) - 1))"
  using consistent_nonneg lipschitz_nonneg grid_interval_notempty order_pos assms
    grid_mono[of 0 j, simplified]
  by (intro max_step_mono_r) (auto simp: t0_le)


lemma stability:
  assumes "t j \<le> t1"
  defines incrs: "incrs \<equiv> \<lambda>h t x. incr h t x + s h t x"
  shows "dist
    (grid_function (discrete_evolution incrs) (x (t 0) + s0) t j)
    (grid_function (discrete_evolution incr) (x (t 0)) t j) \<le>
        B / L * (exp (L * (t1 - t 0) + 1) - 1) * max_stepsize j ^ p"
proof -
  have "t 0 \<le> t1"
    by (metis assms(1) grid_ge_min order_trans)
  {
    fix j assume "t (Suc j) \<le> t1" from error[OF this]
    have "stepsize j * norm (s (stepsize j) (t j)
        (grid_function (discrete_evolution incrs) (x (t 0) + s0) t j))
       \<le> stepsize j * (B * stepsize j ^ p)"
      using grid_stepsize_nonneg
      by (auto intro: mult_left_mono simp: incrs)
    hence "norm (stepsize j *\<^sub>R s (stepsize j) (t j)
        (grid_function (discrete_evolution incrs) (x (t 0) + s0) t j))
      \<le> B * stepsize j ^ (p + 1)"
      using grid_stepsize_nonneg
      by (simp add: field_simps)
  } note error = this
  interpret c1: convergent_one_step "t 0" using max_step_r
    by unfold_locales simp_all
  { fix j assume "t (Suc j) \<le> t1"
    hence "t j \<le> t1" using grid_mono[of j "Suc j"] by auto
    have "dist (x (t j)) (grid_function (discrete_evolution incr) (x (t 0)) t j)
      \<le> B / L * (exp (L * (t1 - t 0) + 1) - 1) * max_stepsize j ^ p"
      using `t j \<le> t1` by (rule c1.convergence)
    also have "... \<le> \<bar>r/2\<bar>" using max_stepsize_nonneg grid_interval_notempty max_step
      consistent_nonneg lipschitz_nonneg order_pos
      grid_mono `t j \<le> t1` t0_le
      apply (cases "L = 0", simp)
      by (intro stepsize_inverse) (auto simp: diff_le_iff)
    finally have
      "dist (x (t j)) (grid_function (discrete_evolution incr) (x (t 0)) t j) \<le>
      \<bar>r / 2\<bar>" .
  } note incr_in = this
  { fix j assume "t (Suc j) \<le> t1"
    note incr_in[OF this]
    also have "\<bar>r/2\<bar> \<le> \<bar>r\<bar>" by simp
    finally have
      "dist (x (t j)) (grid_function (discrete_evolution incr) (x (t 0)) t j) \<le> \<bar>r\<bar>".
  }
  note incr_in_r = this
  have "dist
    (grid_function (discrete_evolution incrs) (x (t 0) + s0) t j)
    (grid_function (discrete_evolution incr) (x (t 0)) t j) \<le>
    B / L * (exp (L * (t j - t 0) + 1) - 1) * max_stepsize j ^ p"
  proof (intro error_accumulation[OF max_step])
    fix j assume j: "t (Suc j) \<le> t1"
    show "dist (grid_function (discrete_evolution incrs) (x (t 0) + s0) t (Suc j))
      (discrete_evolution incr (t (Suc j)) (t j) (grid_function (discrete_evolution incrs) (x (t 0) + s0) t j))
      \<le> B * stepsize j ^ (p + 1)"
      using error[OF j]
      by (simp add: incrs discrete_evolution_def[abs_def] dist_norm
        stepsize_def scaleR_right_distrib)
  next
    fix j assume "t (Suc j) \<le> t1" hence "t j \<le> t1" using grid_mono[of j "Suc j"]
      by simp
    have
      "dist (x (t j)) (grid_function (discrete_evolution incrs) (x (t 0) + s0) t j)
      \<le> dist (x (t j)) (grid_function (discrete_evolution incr) (x (t 0)) t j) +
      dist (grid_function (discrete_evolution incrs) (x (t 0) + s0) t j)
      (grid_function (discrete_evolution incr) (x (t 0)) t j)"
      by (rule dist_triangle2)
    also have
      "dist (x (t j)) (grid_function (discrete_evolution incr) (x (t 0)) t j) \<le>
      B / L * (exp (L * (t1 - t 0) + 1) - 1) * max_stepsize j ^ p"
      using `t j \<le> t1` by (rule c1.convergence)
    also have "... \<le> \<bar>r/2\<bar>"
      using max_stepsize_nonneg grid_interval_notempty max_step
        consistent_nonneg lipschitz_nonneg order_pos
        grid_mono `t j \<le> t1` `t 0 \<le> t1`
      by (intro stepsize_inverse) (auto simp: diff_le_iff)
    also
    assume "dist (grid_function (discrete_evolution incrs) (x (t 0) + s0) t j)
      (grid_function (discrete_evolution incr) (x (t 0)) t j) \<le> \<bar>r / 2\<bar>"
    finally
    have "dist
      (x (t j))
      (grid_function (discrete_evolution incrs) (x (t 0) + s0) t j) \<le> \<bar>r\<bar>" by simp
    thus "dist
      (incr (stepsize j) (t j)
      (grid_function (discrete_evolution incrs) (x (t 0) + s0) t j))
      (incr (stepsize j) (t j)
      (grid_function (discrete_evolution incr) (x (t 0)) t j))
      \<le> L *
      dist (grid_function (discrete_evolution incrs) (x (t 0) + s0) t j)
      (grid_function (discrete_evolution incr) (x (t 0)) t j)"
      using  `t j \<le> t1` `t (Suc j) \<le> t1` incr_in_r
        max_stepsize_nonneg
        grid_ge_min
        grid_stepsize_nonneg
        grid_mono[of j]
      by (intro lipschitz_incr[THEN lipschitzD]) (auto simp: stepsize_def)
  next
    show "dist (grid_function (discrete_evolution incrs) (x (t 0) + s0) t 0)
      (x (t 0))
      \<le> B * (exp 1 - 1) * stepsize 0 ^ p / L" using initial_error
      by (simp add: dist_norm)
  qed (simp_all add: consistent_nonneg order_pos lipschitz_nonneg `t j \<le> t1`)
  also have "... \<le>
    B / L * (exp (L * (t1 - t 0) + 1) - 1) * max_stepsize j ^ p"
    using grid lipschitz_nonneg consistent_nonneg
      max_stepsize_nonneg
      grid_ge_min grid_mono `t j \<le> t1`
    by  (auto simp add: ac_simps intro!: divide_right_mono mult_left_mono)
  finally have "dist (grid_function (discrete_evolution incrs) (x (t 0) + s0) t j)
   (grid_function (discrete_evolution incr) (x (t 0)) t j)
  \<le> B / L * (exp (L * (t1 - t 0) + 1) - 1) * max_stepsize j ^ p" .
  thus ?thesis by simp
qed

end

subsection{* Stability via implicit error *}

locale rounded_one_step = consistent_one_step "t 0" t1 x incr p B r L +
  max_step t t1 p L B "r / 2"
  for t::"nat\<Rightarrow>real" and t1 and x::"real\<Rightarrow>('a::ordered_euclidean_space)" and incr p B r L +
  fixes incr'::"real\<Rightarrow>real\<Rightarrow>'a\<Rightarrow>'a"
  fixes x0'::'a
  assumes initial_error: "dist (x (t 0)) x0' \<le>
    B / L * (exp 1 - 1) * stepsize 0 ^ p"
  assumes incr_approx: "\<And>h j x. t j \<le> t1 \<Longrightarrow> dist (incr h (t j) x) (incr' h (t j) x) \<le>
    B * stepsize j ^ p"
begin

lemma stability:
  assumes "t j \<le> t1"
  shows "dist
   ((grid_function (discrete_evolution incr') (x0') t j))
   (grid_function (discrete_evolution incr) (x (t 0)) t j) \<le>
     B / L * (exp (L * (t1 - (t 0)) + 1) - 1) * max_stepsize j ^ p"
proof -
   note fg' = incr_approx
  def s0 \<equiv> "x0' - x (t 0)"
  hence x0': "x0' = x (t 0) + s0"
    by simp
  def s \<equiv> "\<lambda>x xa xb. (incr' x xa xb) - incr x xa xb"
  def incrs \<equiv> "\<lambda>h t x. incr h t x + s h t x"
  have s: "incr' = incrs"
    by (simp add: s_def incrs_def)
  interpret c: stable_one_step t1 x incr p B r L t s s0
  proof
    fix j
    assume "(t (Suc j)) \<le> t1"
    hence "t j \<le> t1" using grid_mono[of j "Suc j"] by simp
    have "norm (s (stepsize j) (t j) (grid_function
             (discrete_evolution (\<lambda>h t x. (incr' h t x)))
             (x (t 0) + s0) t j))
          \<le> B * stepsize j ^ p"
      unfolding s_def dist_norm[symmetric]
      unfolding dist_commute
      using `t j \<le> t1`
      by (rule fg')
    thus "norm
         (s (stepsize j) (t j)
           (grid_function (discrete_evolution (\<lambda>h t x. incr h t x + s h t x))
             (x (t 0) + s0) (\<lambda>x. (t x)) j))
        \<le> B * stepsize j ^ p" by (simp add: s incrs_def)
  next
    show "norm s0 \<le> B / L * (exp 1 - 1) * stepsize 0 ^ p"
      unfolding s0_def using initial_error by (simp add: dist_commute dist_norm)
  qed
  show ?thesis
    unfolding s x0'
    using `t j \<le> t1`
    by (rule c.stability[simplified incrs_def[symmetric]])
qed

end

end
