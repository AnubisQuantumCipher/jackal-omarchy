package Jackal_Assurance_Policy
  with SPARK_Mode
is
   type Display_State is
     (Absent, Indeterminate, Stale, Refused, Degraded, Verified);

   type Doctor_Verdict is
     (Doctor_Indeterminate,
      Doctor_Functional,
      Doctor_Degraded,
      Doctor_Refused,
      Doctor_Not_Installed);

   type Discovery_Outcome is
     (Discovery_Ready, Discovery_Not_Installed, Discovery_Refused);

   type Doctor_Input is record
      Discovery             : Discovery_Outcome;
      Has_Probe_Rows        : Boolean;
      All_Canonical_Declared : Boolean;
      All_Probes_Pass       : Boolean;
      Identity_Match        : Boolean;
   end record;

   function Eligible_For_Functional (Input : Doctor_Input) return Boolean is
     (Input.Discovery = Discovery_Ready
      and then Input.Has_Probe_Rows
      and then Input.All_Canonical_Declared
      and then Input.All_Probes_Pass
      and then Input.Identity_Match);

   function Required_Doctor_Verdict
     (Input : Doctor_Input) return Doctor_Verdict is
     (case Input.Discovery is
         when Discovery_Not_Installed => Doctor_Not_Installed,
         when Discovery_Refused       => Doctor_Refused,
         when Discovery_Ready         =>
           (if Eligible_For_Functional (Input)
            then Doctor_Functional
            else Doctor_Degraded));

   --  JOP-DOCTOR-001: this total finite policy makes FUNCTIONAL equivalent to
   --  ready discovery plus complete, passing canonical probes and identity.
   function Classify_Doctor (Input : Doctor_Input) return Doctor_Verdict
     with
       Post =>
         Classify_Doctor'Result = Required_Doctor_Verdict (Input)
         and then
           ((Classify_Doctor'Result = Doctor_Functional) =
              Eligible_For_Functional (Input));

   type Verification_Verdict is
     (Verification_Not_Run, Verification_Pass, Verification_Fail);

   type State_Input is record
      Report_Present  : Boolean;
      Has_Error       : Boolean;
      Installed       : Boolean;
      Identity_Match  : Boolean;
      Verification    : Verification_Verdict;
      Is_Stale        : Boolean;
      Has_Probes      : Boolean;
      All_Probes_Pass : Boolean;
      Doctor           : Doctor_Verdict;
   end record;

   --  JOP-STATE-001, JOP-STATE-002: this expression is the complete allocated
   --  functional requirement for display-state classification.
   function Required_State (Input : State_Input) return Display_State is
     (if not Input.Report_Present then Indeterminate
      elsif Input.Has_Error then Refused
      elsif not Input.Installed then Absent
      elsif not Input.Identity_Match then Refused
      elsif Input.Verification = Verification_Fail then Refused
      elsif Input.Is_Stale then Stale
      elsif not Input.Has_Probes then Indeterminate
      elsif not Input.All_Probes_Pass then Degraded
      elsif Input.Doctor = Doctor_Functional then Verified
      else Degraded);

   function Eligible_For_Verified (Input : State_Input) return Boolean is
     (Input.Report_Present
      and then not Input.Has_Error
      and then Input.Installed
      and then Input.Identity_Match
      and then Input.Verification /= Verification_Fail
      and then not Input.Is_Stale
      and then Input.Has_Probes
      and then Input.All_Probes_Pass
      and then Input.Doctor = Doctor_Functional);

   function Classify (Input : State_Input) return Display_State
     with
       Post =>
         Classify'Result = Required_State (Input)
         and then
           ((Classify'Result = Verified) = Eligible_For_Verified (Input));

   type Math_Status is
     (Estimated, Model_Based, Checked, Bounded, Formal_Bounded, Exact);

   type Math_Status_Set is array (Math_Status) of Boolean;

   type Math_Strength is
     (Estimate_Strength,
      Check_Strength,
      Bound_Strength,
      Formal_Bound_Strength,
      Exact_Strength);

   type Optional_Math_Status is record
      Present : Boolean;
      Value   : Math_Status;
   end record;

   No_Math_Status : constant Optional_Math_Status :=
     (Present => False, Value => Estimated);

   function Strength_Of (Item : Math_Status) return Math_Strength is
     (case Item is
         when Estimated | Model_Based => Estimate_Strength,
         when Checked                 => Check_Strength,
         when Bounded                 => Bound_Strength,
         when Formal_Bounded          => Formal_Bound_Strength,
         when Exact                   => Exact_Strength);

   function Math_Set_Is_Empty (Items : Math_Status_Set) return Boolean is
     (for all Item in Math_Status => not Items (Item));

   function Is_Canonical_Ceiling
     (Items     : Math_Status_Set;
      Candidate : Math_Status) return Boolean is
     (Items (Candidate)
      and then
        (for all Item in Math_Status =>
           (if Items (Item) then
                Strength_Of (Item) <= Strength_Of (Candidate)))
      and then
        (for all Item in Math_Status =>
           (if Items (Item)
              and then Strength_Of (Item) = Strength_Of (Candidate)
            then Math_Status'Pos (Candidate) <= Math_Status'Pos (Item))));

   --  JOP-ASSURANCE-001: the result is a member of the declared set, no member
   --  is stronger, and equal-strength classes resolve by canonical registry order.
   function Assurance_Ceiling
     (Items : Math_Status_Set) return Optional_Math_Status
     with
       Post =>
         Assurance_Ceiling'Result.Present = not Math_Set_Is_Empty (Items)
         and then
           (if Assurance_Ceiling'Result.Present then
                Is_Canonical_Ceiling
                  (Items, Assurance_Ceiling'Result.Value));

   type Consequence is
     (Informational, Advisory, Decision_Boundary, Safety_Critical);

   type Consequence_Set is array (Consequence) of Boolean;

   type Optional_Consequence is record
      Present : Boolean;
      Value   : Consequence;
   end record;

   No_Consequence : constant Optional_Consequence :=
     (Present => False, Value => Informational);

   function Consequence_Set_Is_Empty
     (Items : Consequence_Set) return Boolean is
     (for all Item in Consequence => not Items (Item));

   function Is_Strongest_Consequence
     (Items     : Consequence_Set;
      Candidate : Consequence) return Boolean is
     (Items (Candidate)
      and then
        (for all Item in Consequence =>
           (if Items (Item) then
                Consequence'Pos (Item) <= Consequence'Pos (Candidate))));

   function Strongest_Consequence
     (Items : Consequence_Set) return Optional_Consequence
     with
       Post =>
         Strongest_Consequence'Result.Present =
           not Consequence_Set_Is_Empty (Items)
         and then
           (if Strongest_Consequence'Result.Present then
                Is_Strongest_Consequence
                  (Items, Strongest_Consequence'Result.Value));

   function Required_Strength (Item : Consequence) return Math_Strength is
     (case Item is
         when Informational     => Estimate_Strength,
         when Advisory          => Check_Strength,
         when Decision_Boundary => Bound_Strength,
         when Safety_Critical   => Formal_Bound_Strength);

   function Required_Cap_Result
     (Assurance    : Math_Status_Set;
      Consequences : Consequence_Set;
      Carries_Axis : Boolean) return Boolean is
     (if Carries_Axis
        or else Math_Set_Is_Empty (Assurance)
        or else Consequence_Set_Is_Empty (Consequences)
      then False
      else Required_Strength (Strongest_Consequence (Consequences).Value)
           < Strength_Of (Assurance_Ceiling (Assurance).Value));

   --  JOP-CAP-001: a cap is reported only for an applicable declared
   --  consequence floor strictly below established mathematical assurance.
   function Consequence_Caps_Assurance
     (Assurance    : Math_Status_Set;
      Consequences : Consequence_Set;
      Carries_Axis : Boolean) return Boolean
     with
       Post =>
         Consequence_Caps_Assurance'Result =
           Required_Cap_Result
             (Assurance, Consequences, Carries_Axis);

end Jackal_Assurance_Policy;
