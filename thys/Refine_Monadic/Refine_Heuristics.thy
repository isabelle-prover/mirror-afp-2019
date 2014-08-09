header {* \isaheader{Data Refinement Heuristics} *}
theory Refine_Heuristics
imports Refine_Basic
begin

text {*
  This theory contains some heuristics to automatically prove
  data refinement goals that are left over by the refinement condition 
  generator.
*}

text {*
  The theorem collection @{text "refine_hsimp"} contains additional simplifier
  rules that are useful to discharge typical data refinement goals.
*}

ML {*
  structure refine_heuristics_simps = Named_Thms
    ( val name = @{binding refine_hsimp}
      val description = "Refinement Framework: " ^
        "Data refinement heuristics simp rules" );
*}

setup {* refine_heuristics_simps.setup *}

subsection {* Type Based Heuristics *}
text {*
  This heuristics instantiates schematic data refinement relations based
  on their type. Both, the left hand side and right hand side type are
  considered.
*}

text {* The heuristics works by proving goals of the form 
  @{text "RELATES ?R"}, thereby instantiating @{text "?R"}. *}
definition RELATES :: "('a\<times>'b) set \<Rightarrow> bool" where "RELATES R \<equiv> True"


ML {*
structure Refine_dref_type = struct
  open Refine_Misc;

  structure pattern_rules = Named_Thms
    ( val name = @{binding refine_dref_pattern}
      val description = "Refinement Framework: " ^
        "Pattern rules to recognize refinement goal" );

  structure RELATES_rules = Named_Thms ( 
    val name = @{binding refine_dref_RELATES}
    val description = "Refinement Framework: " ^
        "Type based heuristics introduction rules" 
  );


  val tracing = 
    Attrib.setup_config_bool @{binding refine_dref_tracing} (K false);

  (* Check whether term contains schematic variable *)
  fun 
    has_schematic (Var _) = true |
    has_schematic (Abs (_,_,t)) = has_schematic t |
    has_schematic (t1$t2) = has_schematic t1 orelse has_schematic t2 |
    has_schematic _ = false;

  (* Match proof states where the conclusion of some goal has the specified
     shape *)
  fun match_goal_shape_tac (shape:term->bool) (ctxt:Proof.context) i thm =
    if Thm.nprems_of thm >= i then
      let
        val t = HOLogic.dest_Trueprop (Logic.concl_of_goal (Thm.prop_of thm) i);
      in
        (if shape t then all_tac thm else no_tac thm)
      end
    else
      no_tac thm;

  fun output_failed_msg ctxt failed_t = let
    val failed_t_str = Pretty.string_of 
      (Syntax.pretty_term (Config.put show_types true ctxt) failed_t);
    val msg = "Failed to resolve refinement goal \n  " ^ failed_t_str;
    val _ = if Config.get ctxt tracing then Output.tracing msg else ();
    in () end;
    
  (* Try to apply patternI-rules, ensure that produced first subgoal
     contains a schematic variable, and then solve it using 
     refine_dref_RELATES-rules. *)
  fun type_tac ctxt =
    ALL_GOALS_FWD (TRY o (
      resolve_tac (pattern_rules.get ctxt) THEN'
      match_goal_shape_tac has_schematic ctxt THEN'
      (SOLVED' (REPEAT_ALL_NEW (resolve_tac (RELATES_rules.get ctxt)))
        ORELSE' (fn i => fn st => let 
          val failed_t = 
            HOLogic.dest_Trueprop (Logic.concl_of_goal (Thm.prop_of st) i);
          val _ = output_failed_msg ctxt failed_t;
          in no_tac st end)
      )
    ));


end;
*}

setup {* Refine_dref_type.RELATES_rules.setup *}
setup {* Refine_dref_type.pattern_rules.setup *}

method_setup refine_dref_type = 
  {* Scan.lift (Args.mode "trace" -- Args.mode "nopost") 
  >> (fn (tracing,nopost) => 
    fn ctxt => (let
      val ctxt = 
        if tracing then Config.put Refine_dref_type.tracing true ctxt else ctxt; 
    in
      SIMPLE_METHOD (CHANGED (
        Refine_dref_type.type_tac ctxt 
        THEN (if nopost then all_tac else ALLGOALS (TRY o Refine.post_tac ctxt))))
    end))
  *} 
  "Use type-based heuristics to instantiate data refinement relations"

(*method_setup refine_dref_type_only = 
  {* Scan.succeed (fn ctxt => SIMPLE_METHOD (CHANGED (
    Refine_dref_type.type_tac ctxt))) *} 
  "Use type-based heuristics to instantiate data refinement relations. 
    No postprocessing."*)

subsection {* Patterns *}
text {*
  This section defines the patterns that are recognized as data refinement 
  goals.
*}

lemma RELATESI_memb[refine_dref_pattern]: 
  "RELATES R \<Longrightarrow> (a,b)\<in>R \<Longrightarrow> (a,b)\<in>R" .
lemma RELATESI_refspec[refine_dref_pattern]: 
  "RELATES R \<Longrightarrow> S \<le>\<Down>R S' \<Longrightarrow> S \<le>\<Down>R S'" .

subsection {* Refinement Relations *}
text {*
  In this section, we define some general purpose refinement relations, e.g.,
  for product types and sets.
*}

lemma Id_RELATES [refine_dref_RELATES]: "RELATES Id" by (simp add: RELATES_def)

lemma prod_rel_RELATES[refine_dref_RELATES]: 
  "RELATES Ra \<Longrightarrow> RELATES Rb \<Longrightarrow> RELATES (\<langle>Ra,Rb\<rangle>prod_rel)"
  by (simp add: RELATES_def prod_rel_def)

declare prod_rel_sv[refine_hsimp]
lemma prod_rel_iff[refine_hsimp]: 
  "((a,b),(a',b'))\<in>\<langle>A,B\<rangle>prod_rel \<longleftrightarrow> (a,a')\<in>A \<and> (b,b')\<in>B"
  by (auto simp: prod_rel_def)

lemmas [refine_hsimp] = prod_rel_id_simp 

lemma option_rel_RELATES[refine_dref_RELATES]: 
  "RELATES Ra \<Longrightarrow> RELATES (\<langle>Ra\<rangle>option_rel)"
  by (simp add: RELATES_def option_rel_def)

declare option_rel_sv[refine_hsimp]

declare case_option_refine[refine del]
lemma case_option_refine_ext[refine]:
  assumes "(v,v')\<in>\<langle>Ra\<rangle>option_rel"
  assumes "n \<le> \<Down> Rb n'"
  assumes "\<And>x x'. \<lbrakk> v=Some x; v'=Some x'; (x, x') \<in> Ra \<rbrakk> 
    \<Longrightarrow> f x \<le> \<Down> Rb (f' x')"
  shows "case_option n f v \<le>\<Down>Rb (case_option n' f' v')"
  using assms
  by (auto split: option.split simp: option_rel_def)

lemmas [refine_hsimp] = option_rel_id_simp


lemmas [refine_hsimp] = set_rel_sv set_rel_csv

lemma set_rel_RELATES[refine_dref_RELATES]: 
  "RELATES R \<Longrightarrow> RELATES (\<langle>R\<rangle>set_rel)" by (simp add: RELATES_def)

lemma set_rel_empty_eq: "(S,S')\<in>\<langle>X\<rangle>set_rel \<Longrightarrow> S={} \<longleftrightarrow> S'={}"
  by (auto simp: set_rel_def)

lemma set_rel_sngD: "({a},{b})\<in>\<langle>R\<rangle>set_rel \<Longrightarrow> (a,b)\<in>R"
  by (auto simp: set_rel_def)

(*lemmas [refine_hsimp] = set_rel_empty set_rel_union set_rel_insert
  set_rel_diff*)

(*lemmas [refine_hsimp] = prod_set_eq_is_Id*)

lemma Image_insert[refine_hsimp]: 
  "(a,b)\<in>R \<Longrightarrow> single_valued R \<Longrightarrow> R``insert a A = insert b (R``A)"
  by (auto dest: single_valuedD)

lemmas [refine_hsimp] = Image_Un

lemma Image_Diff[refine_hsimp]:
  "single_valued (converse R) \<Longrightarrow> R``(A-B) = R``A - R``B"
  by (auto dest: single_valuedD)

lemma Image_Inter[refine_hsimp]:
  "single_valued (converse R) \<Longrightarrow> R``(A\<inter>B) = R``A \<inter> R``B"
  by (auto dest: single_valuedD)

lemma list_rel_RELATES[refine_dref_RELATES]: 
  "RELATES R \<Longrightarrow> RELATES (\<langle>R\<rangle>list_rel)" by (simp add: RELATES_def)

lemmas [refine_hsimp] = list_rel_sv_iff list_rel_simp

end
